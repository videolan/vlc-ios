/*****************************************************************************
 * VLCGoogleDriveController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Soomin Lee <TheHungryBu # gmail.com>
 *          Eshan Singh <eeeshan789 # gmail.com>
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCGoogleDriveController.h"
#import "GTLRDrive_File+VLCShortcut.h"
#import "NSString+SupportedMedia.h"
#import "VLCPlaybackService.h"
#import "VLC-Swift.h"

#import <AppAuth/AppAuth.h>
#import <GTMSessionFetcher/GTMSessionFetcherService.h>
#import <GoogleSignIn/GoogleSignIn.h>
@import GTMAppAuth;

@interface VLCGoogleDriveController () <GTMAuthSessionDelegate>
{
    GTLRDrive_FileList *_fileList;
    GTLRServiceTicket *_fileListTicket;

    NSArray *_currentFileList;
    NSArray *_folderFileList;
    
    NSMutableArray *_listOfGoogleDriveFilesToDownload;
    BOOL _downloadInProgress;

    NSString *_nextPageToken;
    NSString *_folderId;

    CGFloat _averageSpeed;
    NSTimeInterval _startDL;
    NSTimeInterval _lastStatsUpdate;
}

@end

@implementation VLCGoogleDriveController

#pragma mark - session handling

+ (instancetype)sharedInstance
{
    static VLCGoogleDriveController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [VLCGoogleDriveController new];
        sharedInstance.sortBy = VLCCloudSortingCriteriaName; //Default sort by file names
    });

    return sharedInstance;
}

- (void)startSession
{
    self.driveService = [GTLRDriveService new];
    [self applyCurrentUserAuthorizer];
    _driveService.shouldFetchNextPages = YES;
}

- (void)applyCurrentUserAuthorizer
{
    id<GTMFetcherAuthorizationProtocol> authorizer = GIDSignIn.sharedInstance.currentUser.fetcherAuthorizer;

    /* GoogleSignIn installs a delegate that hands the raw token response back
     * on refresh, where the values are not all strings. GTMAppAuth bridges
     * that to a Swift [String: String] and traps, so answer for it instead. */
    if ([authorizer isKindOfClass:[GTMAuthSession class]]) {
        ((GTMAuthSession *)authorizer).delegate = self;
    }

    self.driveService.authorizer = authorizer;
}

#pragma mark - GTMAuthSessionDelegate

- (NSDictionary<NSString *, NSString *> *)additionalTokenRefreshParametersForAuthSession:(GTMAuthSession *)authSession
{
    NSDictionary *parameters = authSession.authState.lastTokenResponse.additionalParameters;
    NSMutableDictionary<NSString *, NSString *> *stringParameters = [NSMutableDictionary dictionaryWithCapacity:parameters.count];

    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        if ([value isKindOfClass:[NSString class]]) {
            stringParameters[key] = value;
        } else if ([value isKindOfClass:[NSNumber class]]) {
            stringParameters[key] = [value stringValue];
        }
    }];

    return stringParameters;
}

- (void)stopSession
{
    [_fileListTicket cancelTicket];
    _nextPageToken = nil;
    _currentFileList = nil;
}

- (void)logout
{
    self.driveService.authorizer = nil;
    [GIDSignIn.sharedInstance signOut];
    [self stopSession];

    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

- (BOOL)isAuthorized
{
    if (!self.driveService) {
        [self startSession];
    }

    return GIDSignIn.sharedInstance.hasPreviousSignIn;
}

- (void)showAlert:(NSString *)title message:(NSString *)message
{
    [VLCAlertViewController alertViewManagerWithTitle:title
                                         errorMessage:message
                                       viewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

#pragma mark - file management

- (BOOL)canPlayAll
{
    return NO;
}

- (BOOL)supportSorting
{
    return YES; //Google drive controller implemented sorting
}

- (void)requestDirectoryListingAtPath:(NSString *)path
{
    if (self.isAuthorized) {
        //we entered a different folder so discard all current files
        if (![path isEqualToString:_folderId])
            _currentFileList = nil;
        [self listFilesWithID:path: NO];
    }
}

- (BOOL)hasMoreFiles
{
    return _nextPageToken != nil;
}

- (void)downloadFileToDocumentFolder:(GTLRDrive_File *)file : (NSString *) currentPath
{
    if (file == nil)
        return;

    if (file.vlc_isDirectory) {
        if (currentPath != nil) {
            if (![currentPath isEqualToString:@""]) {
                currentPath = [currentPath stringByAppendingString:@"/"];
            }
            currentPath = [currentPath stringByAppendingString:file.vlc_targetIdentifier];
            [self listFilesWithID: currentPath : YES];
        }
    } else {
        [self queueDownloads: file];
    }
}

-(void)queueDownloads:(GTLRDrive_File *)file
{
    if (!_listOfGoogleDriveFilesToDownload)
        _listOfGoogleDriveFilesToDownload = [[NSMutableArray alloc] init];
    
    [_listOfGoogleDriveFilesToDownload addObject:file];
    
    if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
        [self.delegate numberOfFilesWaitingToBeDownloadedChanged];
    
    [self _triggerNextDownload];
}

- (void)listFilesWithID:(NSString *)folderId : (BOOL)isDownloadingFolder
{
    _fileList = nil;
    _folderId = folderId;
    GTLRDriveQuery_FilesList *query;
    NSString *parentName = @"root";

    query = [GTLRDriveQuery_FilesList query];
    query.pageToken = _nextPageToken;
    query.fields = @"nextPageToken,files(*)";
    
    //Set orderBy parameter based on sortBy
    if (self.sortBy == VLCCloudSortingCriteriaName)
        query.orderBy = @"folder,name,modifiedTime desc";
    else
        query.orderBy = @"modifiedTime desc,folder,name";

    if (![_folderId isEqualToString:@""]) {
        parentName = [_folderId lastPathComponent];
    }
    query.q = [NSString stringWithFormat:@"'%@' in parents", parentName];

    _fileListTicket = [self.driveService executeQuery:query
                          completionHandler:^(GTLRServiceTicket *ticket,
                                              GTLRDrive_FileList *fileList,
                                              NSError *error) {
                              if (error == nil) {
                                  self->_fileList = fileList;
                                  self->_nextPageToken = fileList.nextPageToken;
                                  self->_fileListTicket = nil;
                                  [self _listOfGoodFilesAndFolders: isDownloadingFolder];
                              } else {
                                  [self showAlert:NSLocalizedString(@"GDRIVE_ERROR_FETCHING_FILES",nil) message:error.localizedDescription];
                              }
                          }];
}

- (void)streamFile:(GTLRDrive_File *)file
{
    GTMAuthSession *authSession = (GTMAuthSession *)self.driveService.authorizer;
    NSString *token = authSession.authState.lastTokenResponse.accessToken;
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/drive/v3/files/%@?alt=media", file.vlc_targetIdentifier];

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMedia *media = [self setMediaNameMetadata:[VLCMedia mediaWithURL:[NSURL URLWithString:urlString]]
                                        withName:file.name];
    [media addOptions:@{@"http-token" : token}];
    VLCMediaList *medialist = [[VLCMediaList alloc] init];
    [medialist addMedia:media];
    [vpc playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
}

- (void)_triggerNextDownload
{
    if (_listOfGoogleDriveFilesToDownload.count > 0 && !_downloadInProgress) {
        [self _reallyDownloadFileToDocumentFolder:_listOfGoogleDriveFilesToDownload[0]];
        [_listOfGoogleDriveFilesToDownload removeObjectAtIndex:0];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];
    }
}

- (void)_reallyDownloadFileToDocumentFolder:(GTLRDrive_File *)file
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    /* shortcuts carry no original filename */
    NSString *fileName = file.originalFilename.length > 0 ? file.originalFilename : file.name;
    NSString *filePath = [searchPaths[0] stringByAppendingFormat:@"/%@", fileName];

    [self loadFile:file intoPath:filePath];

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStarted)])
        [self.delegate operationWithProgressInformationStarted];

    _downloadInProgress = YES;
}

- (BOOL)_isSupportedMediaFile:(GTLRDrive_File *)file
{
    if ([file.name isSupportedMediaFormat] || [file.name isSupportedSubtitleFormat]) {
        return YES;
    }

    /* shortcuts and uploads without an extension carry no usable name, so fall
     * back to what Drive reports the content to be */
    NSString *mimeType = file.vlc_effectiveMimeType;
    return [mimeType hasPrefix:@"video/"] || [mimeType hasPrefix:@"audio/"];
}

- (void)_listOfGoodFilesAndFolders : (BOOL)isDownloadingFolder
{
    NSMutableArray *listOfGoodFilesAndFolders = [[NSMutableArray alloc] init];

    for (GTLRDrive_File *iter in _fileList.files) {
        if (iter.trashed.boolValue) {
            continue;
        }

        BOOL isDirectory = iter.vlc_isDirectory;

        if (isDownloadingFolder) {
            if (!isDirectory && [self _isSupportedMediaFile:iter])
                [listOfGoodFilesAndFolders addObject:iter];
        } else if (isDirectory || [self _isSupportedMediaFile:iter]) {
            [listOfGoodFilesAndFolders addObject:iter];
        }
    }
    if (isDownloadingFolder) {
        _folderFileList = [NSArray arrayWithArray:listOfGoodFilesAndFolders];
        if ([_folderFileList count] <= 10 && [self hasMoreFiles]) {
            [self listFilesWithID: _folderId : isDownloadingFolder];
            return;
        }
        
        for (GTLRDrive_File *file in _folderFileList) {
            [self queueDownloads:file];
        }
        
    } else {
        _currentFileList = [NSArray arrayWithArray:listOfGoodFilesAndFolders];
        
        if ([_currentFileList count] <= 10 && [self hasMoreFiles]) {
            [self listFilesWithID: _folderId : isDownloadingFolder];
            return;
        }
        
        if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
            [self.delegate mediaListUpdated];
    }
    
    APLog(@"found filtered metadata for %lu files", (unsigned long)_currentFileList.count);
}

- (void)loadFile:(GTLRDrive_File*)file intoPath:(NSString*)destinationPath
{
    NSString *exportURLStr =  [NSString stringWithFormat:@"https://www.googleapis.com/drive/v3/files/%@?alt=media",
                           file.vlc_targetIdentifier];

    if ([exportURLStr length] > 0) {
        GTMSessionFetcher *fetcher = [self.driveService.fetcherService fetcherWithURLString:exportURLStr];
        fetcher.authorizer = self.driveService.authorizer;

        fetcher.destinationFileURL = [NSURL fileURLWithPath:destinationPath isDirectory:YES];

        // Fetcher logging can include comments.
        [fetcher setCommentWithFormat:@"Downloading \"%@\"", file.name];
        _startDL = [NSDate timeIntervalSinceReferenceDate];
        fetcher.downloadProgressBlock = ^(int64_t bytesWritten,
                                          int64_t totalBytesWritten,
                                          int64_t totalBytesExpectedToWrite) {
            if ((self->_lastStatsUpdate > 0 && ([NSDate timeIntervalSinceReferenceDate] - self->_lastStatsUpdate > .5)) || self->_lastStatsUpdate <= 0) {
                [self calculateRemainingTime:totalBytesWritten expectedDownloadSize:totalBytesExpectedToWrite];
                self->_lastStatsUpdate = [NSDate timeIntervalSinceReferenceDate];
            }

            CGFloat progress = (CGFloat)totalBytesWritten / (CGFloat)[file.size unsignedLongValue];
            if ([self.delegate respondsToSelector:@selector(currentProgressInformation:)])
                [self.delegate currentProgressInformation:progress];
        };

        [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
            if (error == nil) {
                //TODO: show something nice than an annoying alert
                //[self showAlert:NSLocalizedString(@"GDRIVE_DOWNLOAD_SUCCESSFUL_TITLE",nil) message:NSLocalizedString(@"GDRIVE_DOWNLOAD_SUCCESSFUL",nil)];
                [self downloadSuccessful];
            } else {
                [self showAlert:NSLocalizedString(@"GDRIVE_ERROR_DOWNLOADING_FILE_TITLE",nil) message:NSLocalizedString(@"GDRIVE_ERROR_DOWNLOADING_FILE",nil)];
                [self downloadFailedWithError:error];
            }
        }];
    }
}

- (void)calculateRemainingTime:(CGFloat)receivedDataSize expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    CGFloat lastSpeed = receivedDataSize / ([NSDate timeIntervalSinceReferenceDate] - _startDL);
    CGFloat smoothingFactor = 0.005;
    _averageSpeed = isnan(_averageSpeed) ? lastSpeed : smoothingFactor * lastSpeed + (1 - smoothingFactor) * _averageSpeed;

    CGFloat RemainingInSeconds = (expectedDownloadSize - receivedDataSize) / _averageSpeed;

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:RemainingInSeconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSString  *remainingTime = [formatter stringFromDate:date];
    if ([self.delegate respondsToSelector:@selector(updateRemainingTime:)])
        [self.delegate updateRemainingTime:remainingTime];
}

- (void)downloadSuccessful
{
    /* update library now that we got a file */
    APLog(@"DriveFile download was successful");
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"GDRIVE_DOWNLOAD_SUCCESSFUL", nil));
    // FIXME: Replace notifications by cleaner observers
    [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.VLCNewFileAddedNotification
                                                        object:self];
    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
        [self.delegate operationWithProgressInformationStopped];
    _downloadInProgress = NO;

    [self _triggerNextDownload];
}

- (void)downloadFailedWithError:(NSError*)error
{
    APLog(@"DriveFile download failed with error %li", (long)error.code);
    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
        [self.delegate operationWithProgressInformationStopped];
    _downloadInProgress = NO;

    [self _triggerNextDownload];
}

#pragma mark - VLC internal communication and delegate

- (NSArray *)currentListFiles
{
    return _currentFileList;
}

- (NSInteger)numberOfFilesWaitingToBeDownloaded
{
    if (_listOfGoogleDriveFilesToDownload)
        return _listOfGoogleDriveFilesToDownload.count;

    return 0;
}

@end
