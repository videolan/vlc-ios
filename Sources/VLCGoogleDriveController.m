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
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCGoogleDriveController.h"
#import "NSString+SupportedMedia.h"
#import "VLCPlaybackService.h"
#import "VLCMediaFileDiscoverer.h"
#import "VLC-Swift.h"
#import <XKKeychain/XKKeychain.h>

#import <GTMAppAuth/GTMAppAuth.h>
#import <GTMSessionFetcher/GTMSessionFetcherService.h>
#import <GoogleSignIn/GIDSignIn.h>

@interface VLCGoogleDriveController ()
{
    GTLRDrive_FileList *_fileList;
    GTLRServiceTicket *_fileListTicket;

    NSArray *_currentFileList;

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
    [self restoreFromSharedCredentials];
    self.driveService = [GTLRDriveService new];
    self.driveService.authorizer = [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:kKeychainItemName];
    _driveService.shouldFetchNextPages = YES;
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
    NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousStore setString:nil forKey:kVLCStoreGDriveCredentials];
    [ubiquitousStore synchronize];
    [self stopSession];
    [GIDSignIn.sharedInstance signOut];
    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

- (BOOL)isAuthorized
{
    if (!self.driveService) {
        [self startSession];
    }

    BOOL ret = [GIDSignIn.sharedInstance hasPreviousSignIn];

    if (ret) {
        [self shareCredentials];
    }
    return ret;
}

- (void)shareCredentials
{
    /* share our credentials */
    XKKeychainGenericPasswordItem *item = [XKKeychainGenericPasswordItem itemForService:kKeychainItemName account:@"OAuth" error:nil]; // kGTMOAuth2AccountName
    NSString *credentials = item.secret.stringValue;
    if (credentials == nil)
        return;

    NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousStore setString:credentials forKey:kVLCStoreGDriveCredentials];
    [ubiquitousStore synchronize];
}

- (BOOL)restoreFromSharedCredentials
{
    NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousStore synchronize];
    NSString *credentials = [ubiquitousStore stringForKey:kVLCStoreGDriveCredentials];
    if (!credentials)
        return NO;

    XKKeychainGenericPasswordItem *keychainItem = [[XKKeychainGenericPasswordItem alloc] init];
    keychainItem.service = kKeychainItemName;
    keychainItem.account = @"OAuth"; // kGTMOAuth2AccountName
    keychainItem.secret.stringValue = credentials;
    [keychainItem saveWithError:nil];

    return YES;
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
        [self listFilesWithID:path];
    }
}

- (BOOL)hasMoreFiles
{
    return _nextPageToken != nil;
}

- (void)downloadFileToDocumentFolder:(GTLRDrive_File *)file
{
    if (file == nil)
        return;

    if ([file.mimeType isEqualToString:@"application/vnd.google-apps.folder"]) return;

    if (!_listOfGoogleDriveFilesToDownload)
        _listOfGoogleDriveFilesToDownload = [[NSMutableArray alloc] init];

    [_listOfGoogleDriveFilesToDownload addObject:file];

    if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
        [self.delegate numberOfFilesWaitingToBeDownloadedChanged];

    [self _triggerNextDownload];
}

- (void)listFilesWithID:(NSString *)folderId
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
                                  [self _listOfGoodFilesAndFolders];
                              } else {
                                  [self showAlert:NSLocalizedString(@"GDRIVE_ERROR_FETCHING_FILES",nil) message:error.localizedDescription];
                              }
                          }];
}

- (void)streamFile:(GTLRDrive_File *)file
{
    NSString *token = [((GTMAppAuthFetcherAuthorization *)self.driveService.authorizer).authState.lastTokenResponse accessToken];
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/drive/v3/files/%@?alt=media", file.identifier];

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
    NSString *filePath = [searchPaths[0] stringByAppendingFormat:@"/%@", file.originalFilename];

    [self loadFile:file intoPath:filePath];

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStarted)])
        [self.delegate operationWithProgressInformationStarted];

    _downloadInProgress = YES;
}

- (BOOL)_supportedFileExtension:(NSString *)filename
{
    if ([filename isSupportedMediaFormat] || [filename isSupportedAudioMediaFormat] || [filename isSupportedSubtitleFormat])
        return YES;

    return NO;
}

- (void)_listOfGoodFilesAndFolders
{
    NSMutableArray *listOfGoodFilesAndFolders = [[NSMutableArray alloc] init];

    for (GTLRDrive_File *iter in _fileList.files) {
        if (iter.trashed.boolValue) {
            continue;
        }

        BOOL isDirectory = [iter.mimeType isEqualToString:@"application/vnd.google-apps.folder"];
        BOOL supportedFile = [self _supportedFileExtension:iter.name];

        if (isDirectory || supportedFile)
            [listOfGoodFilesAndFolders addObject:iter];
    }
    _currentFileList = [NSArray arrayWithArray:listOfGoodFilesAndFolders];

    if ([_currentFileList count] <= 10 && [self hasMoreFiles]) {
        [self listFilesWithID:_folderId];
        return;
    }

    APLog(@"found filtered metadata for %lu files", (unsigned long)_currentFileList.count);

    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

- (void)loadFile:(GTLRDrive_File*)file intoPath:(NSString*)destinationPath
{
    NSString *exportURLStr =  [NSString stringWithFormat:@"https://www.googleapis.com/drive/v3/files/%@?alt=media",
                           file.identifier];

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
    [[VLCMediaFileDiscoverer sharedInstance] performSelectorOnMainThread:@selector(updateMediaList) withObject:nil waitUntilDone:NO];
#if TARGET_OS_IOS
    // FIXME: Replace notifications by cleaner observers
    [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.VLCNewFileAddedNotification
                                                        object:self];
#endif
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
