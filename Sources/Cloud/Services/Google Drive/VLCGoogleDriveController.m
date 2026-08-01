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

    /* paging is driven from hasMoreFiles and the scroll position */
    _driveService.shouldFetchNextPages = NO;
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
    return @{};
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
    if (!self.isAuthorized) {
        return;
    }

    /* every listing request starts over: refreshing, re-sorting and returning
     * to the browser all ask for the folder that is already on screen, and
     * appending to it would grow the list without bound. Further pages come
     * from requestNextPage as the user scrolls. */
    _currentFileList = nil;
    _nextPageToken = nil;

    if (path.length == 0) {
        _folderId = path;
        [self listRootLocations];
        return;
    }

    [self listFilesWithID:path isDownloadingFolder:NO];
}

- (void)requestNextPage
{
    if (!self.isAuthorized || ![self hasMoreFiles]) {
        return;
    }

    [self listFilesWithID:_folderId isDownloadingFolder:NO];
}

- (BOOL)hasMoreFiles
{
    /* the root is synthesised and always complete */
    if (_folderId.length == 0) {
        return NO;
    }

    return _nextPageToken != nil;
}

#pragma mark - root locations

- (GTLRDrive_File *)pseudoFolderWithIdentifier:(NSString *)identifier name:(NSString *)name
{
    return [GTLRDrive_File objectWithJSON:@{ @"id"       : identifier,
                                             @"name"     : name,
                                             @"mimeType" : kVLCGoogleDriveFolderMimeType }];
}

- (void)buildRootLocationsWithSharedDrives:(NSArray<GTLRDrive_Drive *> *)sharedDrives
{
    NSMutableArray<GTLRDrive_File *> *locations = [NSMutableArray array];

    [locations addObject:[self pseudoFolderWithIdentifier:kVLCGoogleDriveMyDrivePath
                                                    name:NSLocalizedString(@"GDRIVE_MY_DRIVE", nil)]];
    [locations addObject:[self pseudoFolderWithIdentifier:kVLCGoogleDriveSharedWithMePath
                                                    name:NSLocalizedString(@"GDRIVE_SHARED_WITH_ME", nil)]];

    for (GTLRDrive_Drive *drive in sharedDrives) {
        if (drive.identifier.length == 0) {
            continue;
        }

        [locations addObject:[self pseudoFolderWithIdentifier:drive.identifier
                                                        name:drive.name ?: drive.identifier]];
    }

    _currentFileList = [NSArray arrayWithArray:locations];

    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

- (void)listRootLocations
{
    GTLRDriveQuery_DrivesList *query = [GTLRDriveQuery_DrivesList query];
    query.pageSize = kVLCGoogleDriveSharedDrivePageSize;
    query.fields = @"drives(id,name)";

    _fileListTicket = [self.driveService executeQuery:query
                          completionHandler:^(GTLRServiceTicket *ticket,
                                              GTLRDrive_DriveList *driveList,
                                              NSError *error) {
                              self->_fileListTicket = nil;

                              /* accounts without Workspace own no shared drives
                               * and may even be refused the call, so this must
                               * never surface as an error */
                              if (error != nil) {
                                  APLog(@"could not list shared drives: %li", (long)error.code);
                              }

                              [self buildRootLocationsWithSharedDrives:error != nil ? nil : driveList.drives];
                          }];
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

            /* this starts a listing of its own, unrelated to what is on screen */
            _nextPageToken = nil;
            _folderFileList = nil;
            [self listFilesWithID:currentPath isDownloadingFolder:YES];
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

- (void)listFilesWithID:(NSString *)folderId isDownloadingFolder:(BOOL)isDownloadingFolder
{
    _fileList = nil;
    _folderId = folderId;

    GTLRDriveQuery_FilesList *query = [GTLRDriveQuery_FilesList query];
    query.pageToken = _nextPageToken;
    query.fields = @"nextPageToken,files(*)";

    /* without both flags the API omits everything stored on a shared drive */
    query.includeItemsFromAllDrives = YES;
    query.supportsAllDrives = YES;

    //Set orderBy parameter based on sortBy
    if (self.sortBy == VLCCloudSortingCriteriaName)
        query.orderBy = @"folder,name,modifiedTime desc";
    else
        query.orderBy = @"modifiedTime desc,folder,name";

    query.q = [self queryStringForFolderID:folderId];

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

- (NSString *)queryStringForFolderID:(NSString *)folderId
{
    if ([folderId isEqualToString:kVLCGoogleDriveSharedWithMePath]) {
        return @"sharedWithMe and trashed = false";
    }

    NSString *parent = folderId.length > 0 ? folderId.lastPathComponent
                                           : kVLCGoogleDriveMyDrivePath;
    return [NSString stringWithFormat:@"'%@' in parents and trashed = false", parent];
}

- (NSString *)mediaURLStringForFile:(GTLRDrive_File *)file
{
    /* the media endpoint refuses anything living on a shared drive unless the
     * request opts in, exactly like the listing queries do */
    return [NSString stringWithFormat:@"https://www.googleapis.com/drive/v3/files/%@?alt=media&supportsAllDrives=true",
            file.vlc_targetIdentifier];
}

- (void)streamFile:(GTLRDrive_File *)file
{
    GTMAuthSession *authSession = (GTMAuthSession *)self.driveService.authorizer;
    NSString *token = authSession.authState.lastTokenResponse.accessToken;

    if (token.length == 0) {
        [self showAlert:NSLocalizedString(@"GDRIVE_ERROR_FETCHING_FILES", nil)
                message:NSLocalizedString(@"GDRIVE_ERROR_FETCHING_FILES", nil)];
        return;
    }

    NSString *urlString = [self mediaURLStringForFile:file];

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
        BOOL isDirectory = iter.vlc_isDirectory;

        if (isDownloadingFolder) {
            if (!isDirectory && [self _isSupportedMediaFile:iter])
                [listOfGoodFilesAndFolders addObject:iter];
        } else if (isDirectory || [self _isSupportedMediaFile:iter]) {
            [listOfGoodFilesAndFolders addObject:iter];
        }
    }

    /* a further page extends the listing rather than replacing it */
    NSArray<GTLRDrive_File *> *accumulated = isDownloadingFolder ? _folderFileList : _currentFileList;
    accumulated = accumulated ? [accumulated arrayByAddingObjectsFromArray:listOfGoodFilesAndFolders]
                              : [NSArray arrayWithArray:listOfGoodFilesAndFolders];

    if (isDownloadingFolder) {
        _folderFileList = accumulated;
    } else {
        _currentFileList = accumulated;
    }

    if (accumulated.count < kVLCGoogleDriveMinimumItemsPerBatch && [self hasMoreFiles]) {
        [self listFilesWithID:_folderId isDownloadingFolder:isDownloadingFolder];
        return;
    }

    if (isDownloadingFolder) {
        for (GTLRDrive_File *file in _folderFileList) {
            [self queueDownloads:file];
        }
        _folderFileList = nil;
        return;
    }

    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];

    APLog(@"found filtered metadata for %lu files", (unsigned long)_currentFileList.count);
}

- (void)loadFile:(GTLRDrive_File*)file intoPath:(NSString*)destinationPath
{
    NSString *exportURLStr = [self mediaURLStringForFile:file];

    if ([exportURLStr length] > 0) {
        GTMSessionFetcher *fetcher = [self.driveService.fetcherService fetcherWithURLString:exportURLStr];
        fetcher.authorizer = self.driveService.authorizer;

        fetcher.destinationFileURL = [NSURL fileURLWithPath:destinationPath isDirectory:YES];

        // Fetcher logging can include comments.
        [fetcher setCommentWithFormat:@"Downloading \"%@\"", file.name];
        _startDL = [NSDate timeIntervalSinceReferenceDate];
        _averageSpeed = 0.;
        _lastStatsUpdate = 0.;
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

    /* the average has to start from a real sample: it is an instance variable,
     * so it begins at zero rather than NaN and would otherwise creep up from a
     * standstill and report hours of remaining time on a fast connection */
    if (_averageSpeed <= 0. || isnan(_averageSpeed)) {
        _averageSpeed = lastSpeed;
    } else {
        _averageSpeed = smoothingFactor * lastSpeed + (1 - smoothingFactor) * _averageSpeed;
    }

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
