/*****************************************************************************
 * VLCDropboxController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Jean-Baptiste Kempf <jb # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDropboxController.h"
#import "NSString+SupportedMedia.h"
#import "VLCPlaybackController.h"
#import "VLCActivityManager.h"
#if !TARGET_OS_TV
#import "VLCMediaFileDiscoverer.h"
#endif
#import "DBKeychain.h"
#import "VLCDropboxConstants.h"

@interface VLCDropboxController ()
{
    DBRestClient *_restClient;
    NSArray *_currentFileList;

    NSMutableArray *_listOfDropboxFilesToDownload;
    BOOL _downloadInProgress;

    NSInteger _outstandingNetworkRequests;

    CGFloat _averageSpeed;
    CGFloat _fileSize;
    NSTimeInterval _startDL;
    NSTimeInterval _lastStatsUpdate;

    UINavigationController *_lastKnownNavigationController;
}

@end

@implementation VLCDropboxController

#pragma mark - session handling

+ (instancetype)sharedInstance
{
    static VLCDropboxController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [VLCDropboxController new];
        [sharedInstance shareCredentials];

        DBSession* dbSession = [[DBSession alloc] initWithAppKey:kVLCDropboxAppKey appSecret:kVLCDropboxPrivateKey root:kDBRootDropbox];
        [DBSession setSharedSession:dbSession];
        [DBRequest setNetworkRequestDelegate:sharedInstance];
    });

    return sharedInstance;
}

- (void)shareCredentials
{
    /* share our credentials */
    NSDictionary *credentials = [DBKeychain credentials];
    if (credentials == nil)
        return;

    NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousStore setDictionary:credentials forKey:kVLCStoreDropboxCredentials];
    [ubiquitousStore synchronize];
}

- (BOOL)restoreFromSharedCredentials
{
    NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousStore synchronize];
    NSDictionary *credentials = [ubiquitousStore dictionaryForKey:kVLCStoreDropboxCredentials];
    if (!credentials)
        return NO;

    [DBKeychain setCredentials:credentials];
    return YES;
}

- (void)startSession
{
    [[DBSession sharedSession] isLinked];
}

- (void)logout
{
    [[DBSession sharedSession] unlinkAll];
}

- (BOOL)isAuthorized
{
    return [[DBSession sharedSession] isLinked];
}

- (DBRestClient *)restClient {
    if (!_restClient) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

#pragma mark - file management

- (BOOL)canPlayAll
{
    return NO;
}

- (void)requestDirectoryListingAtPath:(NSString *)path
{
    if (self.isAuthorized)
        [[self restClient] loadMetadata:path];
}

- (void)downloadFileToDocumentFolder:(DBMetadata *)file
{
    if (!file.isDirectory) {
        if (!_listOfDropboxFilesToDownload)
            _listOfDropboxFilesToDownload = [[NSMutableArray alloc] init];
        [_listOfDropboxFilesToDownload addObject:file];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];

        [self _triggerNextDownload];
    }
}

- (void)streamFile:(DBMetadata *)file currentNavigationController:(UINavigationController *)navigationController
{
    if (!file.isDirectory) {
        _lastKnownNavigationController = navigationController;
        NSString *path = file.path;
        if (path != nil)
            [[self restClient] loadStreamableURLForFile:path];
    }
}

- (void)_triggerNextDownload
{
    if (_listOfDropboxFilesToDownload.count > 0 && !_downloadInProgress) {
        [self _reallyDownloadFileToDocumentFolder:_listOfDropboxFilesToDownload[0]];
        [_listOfDropboxFilesToDownload removeObjectAtIndex:0];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];
    }
}

- (void)_reallyDownloadFileToDocumentFolder:(DBMetadata *)file
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [searchPaths[0] stringByAppendingFormat:@"/%@", file.filename];
    _startDL = [NSDate timeIntervalSinceReferenceDate];
    _fileSize = file.totalBytes;
    [[self restClient] loadFile:file.path intoPath:filePath];

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStarted)])
        [self.delegate operationWithProgressInformationStarted];

    _downloadInProgress = YES;
}

#pragma mark - restClient delegate
- (BOOL)_supportedFileExtension:(NSString *)filename
{
    if ([filename isSupportedMediaFormat] || [filename isSupportedAudioMediaFormat] || [filename isSupportedSubtitleFormat])
        return YES;

    return NO;
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    _currentFileList = [NSArray arrayWithArray:metadata.contents];

    APLog(@"found filtered metadata for %lu files", (unsigned long)_currentFileList.count);
    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    APLog(@"DBMetadata download failed with error %li", (long)error.code);
    [self _handleError:error];
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
{
#if TARGET_OS_IOS
    /* update library now that we got a file */
    [[VLCMediaFileDiscoverer sharedInstance] performSelectorOnMainThread:@selector(updateMediaList) withObject:nil waitUntilDone:NO];

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
        [self.delegate operationWithProgressInformationStopped];
    _downloadInProgress = NO;

    [self _triggerNextDownload];
#endif
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
    APLog(@"DBFile download failed with error %li", (long)error.code);
    [self _handleError:error];
    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
        [self.delegate operationWithProgressInformationStopped];
    _downloadInProgress = NO;
    [self _triggerNextDownload];
}

- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
{
    if ((_lastStatsUpdate > 0 && ([NSDate timeIntervalSinceReferenceDate] - _lastStatsUpdate > .5)) || _lastStatsUpdate <= 0) {
        [self calculateRemainingTime:progress * _fileSize expectedDownloadSize:_fileSize];
        _lastStatsUpdate = [NSDate timeIntervalSinceReferenceDate];
    }

    if ([self.delegate respondsToSelector:@selector(currentProgressInformation:)])
        [self.delegate currentProgressInformation:progress];
}

- (void)restClient:(DBRestClient*)restClient loadedStreamableURL:(NSURL*)url forFile:(NSString*)path
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    [vpc playURL:url successCallback:nil errorCallback:nil];
#if TARGET_OS_TV
    if (_lastKnownNavigationController) {
        VLCFullscreenMovieTVViewController *movieVC = [VLCFullscreenMovieTVViewController fullscreenMovieTVViewController];
        [_lastKnownNavigationController presentViewController:movieVC
                                                     animated:YES
                                                   completion:nil];
    }
#endif
}

- (void)restClient:(DBRestClient*)restClient loadStreamableURLFailedWithError:(NSError*)error
{
    APLog(@"loadStreamableURL failed with error %li", (long)error.code);
    [self _handleError:error];
}

#pragma mark - DBSession delegate

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId
{
    APLog(@"DBSession received authorization failure with user ID %@", userId);
}

#pragma mark - DBNetworkRequest delegate
- (void)networkRequestStarted
{
    _outstandingNetworkRequests++;
    if (_outstandingNetworkRequests == 1) {
        VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
        [activityManager networkActivityStarted];
        [activityManager disableIdleTimer];
    }
}

- (void)networkRequestStopped
{
    _outstandingNetworkRequests--;
    if (_outstandingNetworkRequests == 0) {
        VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
        [activityManager networkActivityStopped];
        [activityManager activateIdleTimer];
    }
}

#pragma mark - VLC internal communication and delegate

- (void)calculateRemainingTime:(CGFloat)receivedDataSize expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    CGFloat lastSpeed = receivedDataSize / ([NSDate timeIntervalSinceReferenceDate] - _startDL);
    CGFloat smoothingFactor = 0.005;
    _averageSpeed = isnan(_averageSpeed) ? lastSpeed : smoothingFactor * lastSpeed + (1 - smoothingFactor) * _averageSpeed;

    CGFloat RemainingInSeconds = (expectedDownloadSize - receivedDataSize)/_averageSpeed;

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:RemainingInSeconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSString  *remaingTime = [formatter stringFromDate:date];
    if ([self.delegate respondsToSelector:@selector(updateRemainingTime:)])
        [self.delegate updateRemainingTime:remaingTime];
}

- (NSArray *)currentListFiles
{
    return _currentFileList;
}

- (NSInteger)numberOfFilesWaitingToBeDownloaded
{
    if (_listOfDropboxFilesToDownload)
        return _listOfDropboxFilesToDownload.count;

    return 0;
}

#pragma mark - user feedback
- (void)_handleError:(NSError *)error
{
#if TARGET_OS_IOS
    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"ERROR_NUMBER", nil), error.code]
                                                      message:error.localizedDescription
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                            otherButtonTitles:nil];
    [alert show];
#else
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"ERROR_NUMBER", nil), error.code]
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction *action) {
                                                          }];

    [alert addAction:defaultAction];

    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
#endif
}

- (void)reset
{
    [_restClient cancelAllRequests];
    _currentFileList = nil;
}

@end
