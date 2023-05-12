/*****************************************************************************
 * VLCMediaFileDownloader.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2020-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMediaFileDownloader.h"
#import "NSString+SupportedMedia.h"
#import "VLCActivityManager.h"
#import "VLCMediaFileDiscoverer.h"
#import "VLC-Swift.h"

NSString *VLCMediaFileDownloaderBackgroundTaskName = @"VLCMediaFileDownloaderBackgroundTaskName";

@interface VLCMediaFileDownloader () <VLCMediaPlayerDelegate>
{
    VLCMediaPlayer *_mediaPlayer;
    NSString *_demuxDumpFilePath;
    BOOL _downloadCancelled;
    NSTimer *_timer;
    NSFileManager *_fileManager;
    unsigned long long _expectedDownloadSize;
    unsigned long long _lastFileSize;
    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
}
@end

@implementation VLCMediaFileDownloader

- (instancetype)init
{
    if (self = [super init]) {
        _mediaPlayer = [[VLCMediaPlayer alloc] init];
        _mediaPlayer.delegate = self;
        _fileManager = [NSFileManager defaultManager];
        _demuxDumpFilePath = @"";
    }
    return self;
}

- (NSString *)downloadLocationPath
{
    return [_demuxDumpFilePath copy];
}

- (NSString *)createPotentialNameFromName:(NSString *)name
{
    NSString *documentDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                          NSUserDomainMask,
                                                                          YES).firstObject;

    return [[self createPotentialPathFromPath:[documentDirectoryPath
                                               stringByAppendingPathComponent:name]] lastPathComponent];
}

- (NSString *)createPotentialPathFromPath:(NSString *)path
{
    NSString *fileName = [path lastPathComponent];
    NSString *finalFilePath = [path stringByDeletingLastPathComponent];

    if ([_fileManager fileExistsAtPath:path]) {
        NSString *potentialFilename;
        NSString *fileExtension = [fileName pathExtension];
        NSString *rawFileName = [fileName stringByDeletingPathExtension];
        for (NSUInteger x = 1; x < 100; x++) {
            potentialFilename = [NSString stringWithFormat:@"%@_%lu.%@",
                                 rawFileName, (unsigned long)x, fileExtension];
            if (![_fileManager fileExistsAtPath:[finalFilePath stringByAppendingPathComponent:potentialFilename]]) {
                break;
            }
        }
        return [finalFilePath stringByAppendingPathComponent:potentialFilename];
    }
    return path;
}

- (NSString *)downloadFileFromVLCMedia:(VLCMedia *)media withName:(NSString *)name expectedDownloadSize:(unsigned long long)expectedDownloadSize
{
    [self beginBackgroundTask];
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = [searchPaths firstObject];

    NSURL *mediaURL = media.url;
    NSString *fileName = [name stringByRemovingPercentEncoding];
    NSString *downloadFileName = [self createPotentialNameFromName:fileName];

    if (downloadFileName.pathExtension.length == 0 || ![downloadFileName isSupportedFormat]) {
        NSString *urlExtension = mediaURL.pathExtension;
        NSString *extension = urlExtension.length != 0 ? urlExtension : @"vlc";
        downloadFileName = [fileName stringByAppendingPathExtension:extension];
    }

    _demuxDumpFilePath = [libraryPath stringByAppendingPathComponent:downloadFileName];

    [media addOptions:@{ @"demuxdump-file" : _demuxDumpFilePath,
                         @"demux" : @"demuxdump" }];

    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStarted];
    [activityManager disableIdleTimer];

    _expectedDownloadSize = expectedDownloadSize;

    _downloadCancelled = NO;
    _downloadInProgress = YES;

    _mediaPlayer.media = media;

#if MEDIA_DOWNLOAD_DEBUG
    VLCConsoleLogger *consoleLogger = [[VLCConsoleLogger alloc] init];
    consoleLogger.level = kVLCLogLevelDebug;
    _mediaPlayer.libraryInstance.loggers = @[consoleLogger];
#endif

    [_mediaPlayer play];

    return [[NSUUID UUID] UUIDString];
}

- (void)cancelDownload
{
    _downloadCancelled = YES;
    [_mediaPlayer stop];
}

- (void)_downloadStarted
{
    [self.delegate mediaFileDownloadStarted:self];
}

- (void)_downloadFailed
{
    if ([self.delegate respondsToSelector:@selector(downloadFailedWithErrorDescription:forDownloader:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate downloadFailedWithErrorDescription:@"libvlc failure" forDownloader:self];
        });
    }
    [self _downloadEnded];
}

- (void)_downloadCancelled
{
    /* remove partially downloaded content */
    [_fileManager removeItemAtURL:[NSURL fileURLWithPath:_demuxDumpFilePath] error:nil];

    if ([self.delegate respondsToSelector:@selector(downloadFailedWithErrorDescription:forDownloader:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate downloadFailedWithErrorDescription:NSLocalizedString(@"HTTP_DOWNLOAD_CANCELLED",nil) forDownloader:self];
        });
    }
}

- (void)_downloadEnded
{
    [_timer invalidate];

    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStopped];
    [activityManager activateIdleTimer];

    [[VLCMediaFileDiscoverer sharedInstance] performSelectorOnMainThread:@selector(updateMediaList) withObject:nil waitUntilDone:NO];
#if TARGET_OS_IOS
    dispatch_async(dispatch_get_main_queue(), ^{
        // FIXME: Replace notifications by cleaner observers
        [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.VLCNewFileAddedNotification
                                                            object:self];
    });
#endif

    _downloadInProgress = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate mediaFileDownloadEnded:self];
    });

    [self terminateBackgroundTask];
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
        VLCMediaPlayerState currentState = _mediaPlayer.state;

        switch (currentState) {
            case VLCMediaPlayerStatePlaying:
                _timer = [NSTimer scheduledTimerWithTimeInterval:1. target:self selector:@selector(updatePosition) userInfo:nil repeats:YES];
                APLog(@"%s: playing", __func__);
                [self _downloadStarted];
                break;

            case VLCMediaPlayerStateOpening:
                APLog(@"%s: opening", __func__);
                break;

            case VLCMediaPlayerStateBuffering:
                APLog(@"%s: buffering", __func__);
                break;

            case VLCMediaPlayerStateError:
                APLog(@"%s: error", __func__);
                [self _downloadFailed];
                break;
#if LIBVLC_VERSION_MAJOR == 3
            case VLCMediaPlayerStateEnded:
                APLog(@"%s: ended", __func__);
                [self _downloadEnded];
                break;
#endif
            case VLCMediaPlayerStateStopped:
                APLog(@"%s: stopped", __func__);
                if (_downloadCancelled) {
                    [self _downloadCancelled];
                }
                [self _downloadEnded];
                break;
            default:
                APLog(@"%s: state %li not handled", __func__, (long)currentState);
                break;
        }
}

- (void)updatePosition
{
    unsigned long long fileSize = _mediaPlayer.media.statistics.readBytes;

    if ([self.delegate respondsToSelector:@selector(progressUpdatedTo:receivedDataSize:expectedDownloadSize:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate progressUpdatedTo:self->_expectedDownloadSize > 0 ? (float)fileSize / (float)self->_expectedDownloadSize : 0.
                            receivedDataSize:fileSize - self->_lastFileSize
                        expectedDownloadSize:self->_expectedDownloadSize];
            self->_lastFileSize = fileSize;
        });
    }
}

#pragma mark - background task management
- (void)beginBackgroundTask
{
    if (!_backgroundTaskIdentifier || _backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        dispatch_block_t expirationHandler = ^{
            APLog(@"Cancelling active download because the expiration date was reached, time remaining: %f", [[UIApplication sharedApplication] backgroundTimeRemaining]);
            [self cancelDownload];
            [[UIApplication sharedApplication] endBackgroundTask:self->_backgroundTaskIdentifier];
            self->_backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        };
        _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:VLCMediaFileDownloaderBackgroundTaskName
                                                                                 expirationHandler:expirationHandler];
    }
}

- (void)terminateBackgroundTask
{
    if (_backgroundTaskIdentifier && _backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
}

@end
