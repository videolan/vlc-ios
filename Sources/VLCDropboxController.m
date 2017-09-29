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
#import "VLCMediaFileDiscoverer.h"
#import "VLCDropboxConstants.h"

@interface VLCDropboxController ()
{
    DBUserClient *_client;
    NSArray *_currentFileList;

    NSMutableArray *_listOfDropboxFilesToDownload;
    BOOL _downloadInProgress;

    CGFloat _averageSpeed;
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
    });

    return sharedInstance;
}

- (void)shareCredentials
{
    /* share our credentials */
    NSArray *credentials = [DBSDKKeychain retrieveAllTokenIds];
    if (credentials == nil)
        return;

    NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousStore setArray:credentials forKey:kVLCStoreDropboxCredentials];
    [ubiquitousStore synchronize];
}

- (BOOL)restoreFromSharedCredentials
{
    NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousStore synchronize];
    NSArray *credentials = [ubiquitousStore arrayForKey:kVLCStoreDropboxCredentials];
    if (!credentials)
        return NO;
    for (NSString *tmp in credentials) {
        [DBSDKKeychain storeValueWithKey:kVLCStoreDropboxCredentials value:tmp];
    }
    return YES;
}

- (void)startSession
{
    [DBClientsManager authorizedClient];
}

- (void)logout
{
    [DBClientsManager unlinkAndResetClients];
}

- (BOOL)isAuthorized
{
    return [DBClientsManager authorizedClient];
}

- (DBUserClient *)client {
    if (!_client) {
        _client = [DBClientsManager authorizedClient];
    }
    return _client;
}


#pragma mark - file management

- (BOOL)_supportedFileExtension:(NSString *)filename
{
    return [filename isSupportedMediaFormat]
        || [filename isSupportedAudioMediaFormat]
        || [filename isSupportedSubtitleFormat];
}

- (NSString *)_createPotentialNameFrom:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *fileName = [path lastPathComponent];
    NSString *finalFilePath = [path stringByDeletingLastPathComponent];

    if ([fileManager fileExistsAtPath:path]) {
        NSString *potentialFilename;
        NSString *fileExtension = [fileName pathExtension];
        NSString *rawFileName = [fileName stringByDeletingPathExtension];
        for (NSUInteger x = 1; x < 100; x++) {
            potentialFilename = [NSString stringWithFormat:@"%@_%lu.%@", rawFileName, (unsigned long)x, fileExtension];
            if (![fileManager fileExistsAtPath:[finalFilePath stringByAppendingPathComponent:potentialFilename]])
                break;
        }
        return [finalFilePath stringByAppendingPathComponent:potentialFilename];
    }
    return path;
}

- (BOOL)canPlayAll
{
    return NO;
}

- (void)requestDirectoryListingAtPath:(NSString *)path
{
    if (self.isAuthorized)
        [self listFiles:path];
}

- (void)downloadFileToDocumentFolder:(DBFILESMetadata *)file
{
    if (![file isKindOfClass:[DBFILESFolderMetadata class]]) {
        if (!_listOfDropboxFilesToDownload)
            _listOfDropboxFilesToDownload = [[NSMutableArray alloc] init];
        [_listOfDropboxFilesToDownload addObject:file];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];

        [self _triggerNextDownload];
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

- (void)_reallyDownloadFileToDocumentFolder:(DBFILESFileMetadata *)file
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [searchPaths[0] stringByAppendingFormat:@"/%@", file.name];
    _startDL = [NSDate timeIntervalSinceReferenceDate];

    [self downloadFileFrom:file.pathDisplay to:filePath];

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStarted)])
        [self.delegate operationWithProgressInformationStarted];

    _downloadInProgress = YES;
}

- (void)streamFile:(DBFILESMetadata *)file currentNavigationController:(UINavigationController *)navigationController
{
    if (![file isKindOfClass:[DBFILESFolderMetadata class]]) {
        _lastKnownNavigationController = navigationController;
        [self loadStreamFrom:file.pathLower];
    }
}

# pragma mark - Dropbox API Request

- (void)listFiles:(NSString *)path
{
    // DropBox API prefers an empty path than a '/'
    if (!path || [path isEqualToString:@"/"]) {
        path = @"";
    }
    [[[self client].filesRoutes listFolder:path] setResponseBlock:^(DBFILESListFolderResult * _Nullable result, DBFILESListFolderError * _Nullable routeError, DBRequestError * _Nullable networkError) {
        if (result) {
            _currentFileList = [result.entries sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                NSString *first = [(DBFILESMetadata*)a name];
                NSString *second = [(DBFILESMetadata*)b name];
                return [first caseInsensitiveCompare:second];
            }];
            APLog(@"found filtered metadata for %lu files", (unsigned long)_currentFileList.count);
            if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
                [self.delegate mediaListUpdated];
        } else {
            APLog(@"listFiles failed with network error %li and error tag %li", (long)networkError.statusCode, (long)networkError.tag);
            [self _handleError:[NSError errorWithDomain:networkError.description code:networkError.statusCode.integerValue userInfo:nil]];
        }
    }];
}

- (void)downloadFileFrom:(NSString *)path to:(NSString *)destination
{
    if (![self _supportedFileExtension:[path lastPathComponent]]) {
        [self _handleError:[NSError errorWithDomain:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil) code:415 userInfo:nil]];
        return;
    }

    if (!destination) {
        [self _handleError:[NSError errorWithDomain:NSLocalizedString(@"GDRIVE_ERROR_DOWNLOADING_FILE", nil) code:415 userInfo:nil]];
        return;
    }

    // Need to replace all ' ' by '_' because it causes a `NSInvalidArgumentException ... destination path is nil` in the dropbox library.
    destination = [destination stringByReplacingOccurrencesOfString:@" " withString:@"_"];

    destination = [self _createPotentialNameFrom:destination];

    [[[_client.filesRoutes downloadUrl:path overwrite:YES destination:[NSURL URLWithString:destination]]
        setResponseBlock:^(DBFILESFileMetadata * _Nullable result, DBFILESDownloadError * _Nullable routeError, DBRequestError * _Nullable networkError, NSURL * _Nonnull destination) {

            if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)]) {
                [self.delegate operationWithProgressInformationStopped];
            }

            _downloadInProgress = NO;
            [self _triggerNextDownload];
            if (networkError) {
                APLog(@"downloadFile failed with network error %li and error tag %li", (long)networkError.statusCode, (long)networkError.tag);
                [self _handleError:networkError.nsError];
            }
        }] setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            if (totalBytesWritten == totalBytesExpectedToWrite) {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"GDRIVE_DOWNLOAD_SUCCESSFUL", nil));
            }

            if ((_lastStatsUpdate > 0 && ([NSDate timeIntervalSinceReferenceDate] - _lastStatsUpdate > .5)) || _lastStatsUpdate <= 0) {
                [self calculateRemainingTime:(CGFloat)totalBytesWritten expectedDownloadSize:(CGFloat)totalBytesExpectedToWrite];
                _lastStatsUpdate = [NSDate timeIntervalSinceReferenceDate];
            }

            if ([self.delegate respondsToSelector:@selector(currentProgressInformation:)])
                [self.delegate currentProgressInformation:(CGFloat)totalBytesWritten / (CGFloat)totalBytesExpectedToWrite];
        }];

}

- (void)loadStreamFrom:(NSString *)path
{
    if (!path || ![self _supportedFileExtension:[path lastPathComponent]]) {
        [self _handleError:[NSError errorWithDomain:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil) code:415 userInfo:nil]];
        return;
    }

    [[_client.filesRoutes getTemporaryLink:path] setResponseBlock:^(DBFILESGetTemporaryLinkResult * _Nullable result, DBFILESGetTemporaryLinkError * _Nullable routeError, DBRequestError * _Nullable networkError) {

        if (result) {
            VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:result.link]];
            VLCMediaList *medialist = [[VLCMediaList alloc] init];
            [medialist addMedia:media];
            [[VLCPlaybackController sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
#if TARGET_OS_TV
            if (_lastKnownNavigationController) {
                VLCFullscreenMovieTVViewController *movieVC = [VLCFullscreenMovieTVViewController fullscreenMovieTVViewController];
                [_lastKnownNavigationController presentViewController:movieVC
                                                             animated:YES
                                                           completion:nil];
            }
#endif
        } else {
            APLog(@"loadStream failed with network error %li and error tag %li", (long)networkError.statusCode, (long)networkError.tag);
            [self _handleError:[NSError errorWithDomain:networkError.description code:networkError.statusCode.integerValue userInfo:nil]];
        }
    }];
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
    _currentFileList = nil;
}

@end
