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
#import "VLCPlaybackService.h"
#import "VLCActivityManager.h"
#import "VLCMediaFileDiscoverer.h"
#import "VLCDropboxConstants.h"

#if TARGET_OS_IOS
# import "VLC-Swift.h"
#endif

@interface VLCDropboxController ()

@property (strong, nonatomic) DBUserClient *client;
@property (strong, nonatomic) NSArray *currentFileList;

@property (strong, nonatomic) NSMutableArray *listOfDropboxFilesToDownload;
@property (assign, nonatomic) BOOL downloadInProgress;

@property (assign, nonatomic) CGFloat averageSpeed;
@property (assign, nonatomic) NSTimeInterval startDL;
@property (assign, nonatomic) NSTimeInterval lastStatsUpdate;

@property (strong, nonatomic) UINavigationController *lastKnownNavigationController;

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
    if (!credentials) {
        return NO;
    }
    for (NSString *tmp in credentials) {
        DBAccessToken *accessToken = [DBAccessToken createWithLongLivedAccessToken:tmp uid:kVLCStoreDropboxCredentials];
        [DBSDKKeychain storeAccessToken:accessToken];
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
    [self reset];
    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
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

- (BOOL)canPlayAll
{
    return NO;
}

- (void)requestDirectoryListingAtPath:(NSString *)path
{
    if (self.isAuthorized) {
        [self listFiles:path];
    }
}

- (void)downloadFileToDocumentFolder:(DBFILESMetadata *)file
{
    if (![file isKindOfClass:[DBFILESFolderMetadata class]]) {
        if (!self.listOfDropboxFilesToDownload) {
            self.listOfDropboxFilesToDownload = [[NSMutableArray alloc] init];
        }
        [self.listOfDropboxFilesToDownload addObject:file];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)]) {
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];
        }

        [self _triggerNextDownload];
    }
}

- (void)_triggerNextDownload
{
    if (self.listOfDropboxFilesToDownload.count > 0 && !self.downloadInProgress) {
        [self _reallyDownloadFileToDocumentFolder:self.listOfDropboxFilesToDownload[0]];
        [self.listOfDropboxFilesToDownload removeObjectAtIndex:0];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)]) {
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];
        }
    }
}

- (void)_reallyDownloadFileToDocumentFolder:(DBFILESFileMetadata *)file
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [searchPaths[0] stringByAppendingFormat:@"/%@", file.name];
    self.startDL = [NSDate timeIntervalSinceReferenceDate];

    [self downloadFileFrom:file.pathDisplay to:filePath];

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStarted)]) {
        [self.delegate operationWithProgressInformationStarted];
    }

    self.downloadInProgress = YES;
}

- (void)streamFile:(DBFILESMetadata *)file currentNavigationController:(UINavigationController *)navigationController
{
    if (![file isKindOfClass:[DBFILESFolderMetadata class]]) {
        _lastKnownNavigationController = navigationController;
        [self loadStreamFrom:file.pathLower];
    }
}

# pragma mark - Dropbox API Request

- (void)listFolderContinueWithClient:(DBUserClient *)client cursor:(NSString *)cursor list:(NSMutableArray *)list {
    [[[self client].filesRoutes listFolderContinue:cursor]
     setResponseBlock:^(DBFILESListFolderResult *response, DBFILESListFolderContinueError *routeError,
                        DBRequestError *networkError) {
        if (response) {
            [list addObjectsFromArray:response.entries];
            if ([response.hasMore boolValue]) {
                [self listFolderContinueWithClient:client cursor:response.cursor list:list];
            } else {
                [self sendMediaListUpdatedWithList:list];
            }
        } else {
            NSLog(@"%@\n%@\n", routeError, networkError);
        }
    }];
}

- (void)sendMediaListUpdatedWithList:(NSArray *)list
{
    self.currentFileList = [[list sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *first = [(DBFILESMetadata*)a name];
        NSString *second = [(DBFILESMetadata*)b name];
        return [first caseInsensitiveCompare:second];
    }] copy];
    APLog(@"found filtered metadata for %lu files", (unsigned long)self.currentFileList.count);
    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)]) {
        [self.delegate mediaListUpdated];
    }
}

- (void)listFiles:(NSString *)path
{
    // DropBox API prefers an empty path than a '/'
    if (!path || [path isEqualToString:@"/"]) {
        path = @"";
    }

    NSMutableArray<DBFILESMetadata *> *stock = [[NSMutableArray alloc] init];

    [[[self client].filesRoutes listFolder:path] setResponseBlock:^(DBFILESListFolderResult * _Nullable result, DBFILESListFolderError * _Nullable routeError, DBRequestError * _Nullable networkError) {
        if (result) {
            if ([result.hasMore boolValue]) {
                [self listFolderContinueWithClient:self->_client cursor:result.cursor list:stock];
            } else {
                [self sendMediaListUpdatedWithList:result.entries];
            }
        } else {
            APLog(@"listFiles failed with network error %li and error tag %li", (long)networkError.statusCode, (long)networkError.tag);
            [self _handleError:[NSError errorWithDomain:networkError.description code:networkError.statusCode.integerValue userInfo:nil]];
        }
    }];
}

- (NSArray *)currentListFiles
{
    return _currentFileList;
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

    destination = [self createPotentialPathFrom:destination];
    destination = [destination
                   stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet
                                                                       URLPathAllowedCharacterSet]];

    [[[self.client.filesRoutes downloadUrl:path overwrite:YES destination:[NSURL URLWithString:destination]]
        setResponseBlock:^(DBFILESFileMetadata * _Nullable result, DBFILESDownloadError * _Nullable routeError, DBRequestError * _Nullable networkError, NSURL * _Nonnull destination) {

            if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)]) {
                [self.delegate operationWithProgressInformationStopped];
            }

#if TARGET_OS_IOS
            // FIXME: Replace notifications by cleaner observers
            [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.VLCNewFileAddedNotification
                                                                object:self];
#endif
            self.downloadInProgress = NO;
            [self _triggerNextDownload];
            if (networkError) {
                APLog(@"downloadFile failed with network error %li and error tag %li", (long)networkError.statusCode, (long)networkError.tag);
                [self _handleError:networkError.nsError];
            }
        }] setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            if (totalBytesWritten == totalBytesExpectedToWrite) {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"GDRIVE_DOWNLOAD_SUCCESSFUL", nil));
            }

            if ((self.lastStatsUpdate > 0 && ([NSDate timeIntervalSinceReferenceDate] - self.lastStatsUpdate > .5)) || self.lastStatsUpdate <= 0) {
                [self calculateRemainingTime:(CGFloat)totalBytesWritten expectedDownloadSize:(CGFloat)totalBytesExpectedToWrite];
                self.lastStatsUpdate = [NSDate timeIntervalSinceReferenceDate];
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

    [[self.client.filesRoutes getTemporaryLink:path] setResponseBlock:^(DBFILESGetTemporaryLinkResult * _Nullable result, DBFILESGetTemporaryLinkError * _Nullable routeError, DBRequestError * _Nullable networkError) {

        if (result) {
            VLCMedia *media = [self setMediaNameMetadata:[VLCMedia mediaWithURL:[NSURL URLWithString:result.link]]
                                                withName:result.metadata.name];
            VLCMediaList *medialist = [[VLCMediaList alloc] init];
            [medialist addMedia:media];
            [[VLCPlaybackService sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
#if TARGET_OS_TV
            if (self.lastKnownNavigationController) {
                VLCFullscreenMovieTVViewController *movieVC = [VLCFullscreenMovieTVViewController fullscreenMovieTVViewController];
                [self.lastKnownNavigationController presentViewController:movieVC
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
    CGFloat lastSpeed = receivedDataSize / ([NSDate timeIntervalSinceReferenceDate] - self.startDL);
    CGFloat smoothingFactor = 0.005;
    self.averageSpeed = isnan(self.averageSpeed) ? lastSpeed : smoothingFactor * lastSpeed + (1 - smoothingFactor) * self.averageSpeed;

    CGFloat RemainingInSeconds = (expectedDownloadSize - receivedDataSize)/self.averageSpeed;

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:RemainingInSeconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSString  *remaingTime = [formatter stringFromDate:date];
    if ([self.delegate respondsToSelector:@selector(updateRemainingTime:)]) {
        [self.delegate updateRemainingTime:remaingTime];
    }
}

- (NSInteger)numberOfFilesWaitingToBeDownloaded
{
    if (self.listOfDropboxFilesToDownload) {
        return self.listOfDropboxFilesToDownload.count;
    }
    return 0;
}

#pragma mark - user feedback
- (void)_handleError:(NSError *)error
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"ERROR_NUMBER", nil), error.code]
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction *action) {
                                                          }];

    [alert addAction:defaultAction];

    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)reset
{
    self.currentFileList = nil;
}

@end
