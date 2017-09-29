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
#import "VLCPlaybackController.h"
#import "VLCMediaFileDiscoverer.h"
#import <XKKeychain/XKKeychain.h>

#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>

@interface VLCGoogleDriveController ()
{
    GTLDriveFileList *_fileList;
    GTLServiceTicket *_fileListTicket;

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
    });

    return sharedInstance;
}

- (void)startSession
{
    [self restoreFromSharedCredentials];
    self.driveService = [GTLServiceDrive new];
    self.driveService.authorizer = [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:kKeychainItemName];
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
    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

- (BOOL)isAuthorized
{
    if (!self.driveService) {
        [self startSession];
    }

    BOOL ret = [(GTMAppAuthFetcherAuthorization *)self.driveService.authorizer canAuthorize];

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
    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle: title
                                                      message: message
                                                     delegate: nil
                                            cancelButtonTitle: @"OK"
                                            otherButtonTitles: nil];
    [alert show];
}

#pragma mark - file management

- (BOOL)canPlayAll
{
    return NO;
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

- (void)downloadFileToDocumentFolder:(GTLDriveFile *)file
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
    GTLQueryDrive *query;
    NSString *parentName = @"root";

    query = [GTLQueryDrive queryForFilesList];
    query.pageToken = _nextPageToken;
    //the results don't come in alphabetical order when paging. So the maxresult (default 100) is set to 1000 in order to get a few more files at once.
    //query.pageSize = 1000;
    query.includeDeleted = NO;
    query.includeRemoved = NO;
    query.restrictToMyDrive = YES;
    query.fields = @"files(*)";

    if (![_folderId isEqualToString:@""]) {
        parentName = [_folderId lastPathComponent];
    }
    query.q = [NSString stringWithFormat:@"'%@' in parents", parentName];

    _fileListTicket = [self.driveService executeQuery:query
                          completionHandler:^(GTLServiceTicket *ticket,
                                              GTLDriveFileList *fileList,
                                              NSError *error) {
                              if (error == nil) {
                                  _fileList = fileList;
                                  _nextPageToken = fileList.nextPageToken;
                                  _fileListTicket = nil;
                                  [self _listOfGoodFilesAndFolders];
                              } else {
                                  [self showAlert:NSLocalizedString(@"GDRIVE_ERROR_FETCHING_FILES",nil) message:error.localizedDescription];
                              }
                          }];
}

- (void)streamFile:(GTLDriveFile *)file
{
    NSString *token = [((GTMAppAuthFetcherAuthorization *)self.driveService.authorizer).authState.lastTokenResponse accessToken];
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/drive/v3/files/%@?alt=media&access_token=%@",
                     file.identifier, token];

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:urlString]];
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

- (void)_reallyDownloadFileToDocumentFolder:(GTLDriveFile *)file
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

    for (GTLDriveFile *iter in _fileList.files) {
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

    //the files come in a chaotic order so we order alphabetically
     NSArray *sortedArray = [_currentFileList sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *first = [(GTLDriveFile *)a name];
        NSString *second = [(GTLDriveFile *)b name];
        return [first compare:second];
    }];
    _currentFileList = sortedArray;

    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

- (void)loadFile:(GTLDriveFile*)file intoPath:(NSString*)destinationPath
{
    NSString *exportURLStr =  [NSString stringWithFormat:@"https://www.googleapis.com/drive/v3/files/%@?alt=media",
                           file.identifier];

    if ([exportURLStr length] > 0) {
        GTMSessionFetcher *fetcher = [self.driveService.fetcherService fetcherWithURLString:exportURLStr];
        fetcher.authorizer = self.driveService.authorizer;

        fetcher.destinationFileURL = [NSURL fileURLWithPath:destinationPath isDirectory:YES];

        // Fetcher logging can include comments.
        [fetcher setCommentWithFormat:@"Downloading \"%@\"", file.name];
        __weak GTMSessionFetcher *weakFetcher = fetcher;
        _startDL = [NSDate timeIntervalSinceReferenceDate];
        fetcher.downloadProgressBlock = ^(int64_t bytesWritten,
                                          int64_t totalBytesWritten,
                                          int64_t totalBytesExpectedToWrite) {
            if ((_lastStatsUpdate > 0 && ([NSDate timeIntervalSinceReferenceDate] - _lastStatsUpdate > .5)) || _lastStatsUpdate <= 0) {
                [self calculateRemainingTime:totalBytesWritten expectedDownloadSize:totalBytesExpectedToWrite];
                _lastStatsUpdate = [NSDate timeIntervalSinceReferenceDate];
            }

            CGFloat progress = (CGFloat)weakFetcher.downloadedLength / (CGFloat)[file.size unsignedLongValue];
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
