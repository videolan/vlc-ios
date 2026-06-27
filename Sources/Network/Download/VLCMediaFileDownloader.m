/*****************************************************************************
 * VLCMediaFileDownloader.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2020-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMediaFileDownloader.h"
#import "NSString+SupportedMedia.h"
#import "VLCActivityManager.h"
#import "VLC-Swift.h"

NSString *VLCMediaFileDownloaderBackgroundTaskName = @"VLCMediaFileDownloaderBackgroundTaskName";

/* throttle progress reporting to keep UI churn down on fast links */
static const NSTimeInterval VLCMediaFileDownloaderProgressInterval = 0.5;

@interface VLCMediaFileDownloader () <VLCMediaDownloaderDelegate>
{
    VLCMediaDownloader *_downloader;
    VLCMediaDownloadTask *_task;
    NSFileHandle *_fileHandle;
    NSString *_filePath;
    NSFileManager *_fileManager;
    BOOL _downloadCancelled;
    BOOL _didStart;
    BOOL _terminated;
    unsigned long long _expectedDownloadSize;
    unsigned long long _receivedBytes;
    unsigned long long _lastReportedBytes;
    NSTimeInterval _lastReportTime;
    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
}
@end

@implementation VLCMediaFileDownloader

- (instancetype)init
{
    if (self = [super init]) {
#if MEDIA_DOWNLOAD_DEBUG
        VLCLibrary *library = [[VLCLibrary alloc] init];
        VLCConsoleLogger *consoleLogger = [[VLCConsoleLogger alloc] init];
        consoleLogger.level = kVLCLogLevelDebug;
        library.loggers = @[consoleLogger];
        _downloader = [[VLCMediaDownloader alloc] initWithLibrary:library];
#else
        _downloader = [[VLCMediaDownloader alloc] init];
#endif
        _fileManager = [NSFileManager defaultManager];
        _filePath = @"";
    }
    return self;
}

- (NSString *)downloadLocationPath
{
    return [_filePath copy];
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

    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStarted];
    [activityManager disableIdleTimer];

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

    _filePath = [libraryPath stringByAppendingPathComponent:downloadFileName];
    _filename = downloadFileName;

    if (![_fileManager createFileAtPath:_filePath contents:nil attributes:nil]
        || !(_fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath])) {
        APLog(@"%s: failed to create download file at %@", __func__, _filePath);
        [self _finishWithFailureDescription:NSLocalizedString(@"DOWNLOAD_FAILED", nil)];
        return nil;
    }

    _expectedDownloadSize = expectedDownloadSize;
    _receivedBytes = 0;
    _lastReportedBytes = 0;
    _lastReportTime = 0;
    _downloadCancelled = NO;
    _didStart = NO;
    _terminated = NO;
    _downloadInProgress = YES;

    _task = [_downloader downloadMedia:media delegate:self];
    if (!_task) {
        APLog(@"%s: failed to queue download for %@", __func__, mediaURL);
        [self _finishWithFailureDescription:NSLocalizedString(@"DOWNLOAD_FAILED", nil)];
        return nil;
    }

    return [[NSUUID UUID] UUIDString];
}

- (void)cancelDownload
{
    _downloadCancelled = YES;
    [_task cancel];
}

#pragma mark - VLCMediaDownloaderDelegate

- (NSInteger)mediaDownloadTask:(VLCMediaDownloadTask *)task
                didReceiveData:(NSData *)data
                      position:(uint64_t)position
                         total:(uint64_t)total
{
    if (_downloadCancelled) {
        return VLCMediaDownloadConsumedCancel;
    }

    @try {
        [_fileHandle writeData:data];
    } @catch (NSException *exception) {
        APLog(@"%s: failed to write %lu bytes: %@", __func__, (unsigned long)data.length, exception.reason);
        return VLCMediaDownloadConsumedError;
    }

    _receivedBytes = position;
    if (total > 0) {
        _expectedDownloadSize = total;
    }

    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    if (now - _lastReportTime >= VLCMediaFileDownloaderProgressInterval) {
        _lastReportTime = now;
        [self reportProgress];
    }

    return data.length;
}

- (void)mediaDownloadTask:(VLCMediaDownloadTask *)task
          didUpdateStatus:(VLCMediaDownloadStatus)status
{
    switch (status) {
        case VLCMediaDownloadStatusPending:
            APLog(@"%s: pending", __func__);
            break;

        case VLCMediaDownloadStatusRunning:
            APLog(@"%s: running", __func__);
            [self _downloadStarted];
            break;

        case VLCMediaDownloadStatusPaused:
            APLog(@"%s: paused", __func__);
            break;

        case VLCMediaDownloadStatusFinished:
            APLog(@"%s: finished", __func__);
            if (_terminated) {
                break;
            }
            _terminated = YES;
            [self _closeFile];
            [self reportProgress];
            [self _finishSuccessfully];
            break;

        case VLCMediaDownloadStatusCancelled:
            APLog(@"%s: cancelled", __func__);
            if (_terminated) {
                break;
            }
            _terminated = YES;
            [self _finishWithFailureDescription:NSLocalizedString(@"HTTP_DOWNLOAD_CANCELLED", nil)];
            break;

        case VLCMediaDownloadStatusError:
            APLog(@"%s: error", __func__);
            if (_terminated) {
                break;
            }
            _terminated = YES;
            [self _finishWithFailureDescription:NSLocalizedString(@"DOWNLOAD_FAILED", nil)];
            break;
    }
}

- (void)mediaDownloadTask:(VLCMediaDownloadTask *)task
       didReceiveSubitems:(VLCMediaList *)subitems
{
    APLog(@"%s: media resolved to subitems and cannot be downloaded as a file", __func__);
    [_task cancel];
}

- (void)mediaDownloadTask:(VLCMediaDownloadTask *)task
         didReceiveSlaves:(NSArray<VLCMediaSlave *> *)slaves
{
    APLog(@"%s: ignoring %lu slaves", __func__, (unsigned long)slaves.count);
}

#pragma mark - download lifecycle

- (void)_closeFile
{
    [_fileHandle closeFile];
    _fileHandle = nil;
}

- (void)_downloadStarted
{
    if (_didStart) {
        return;
    }
    _didStart = YES;

    [self.delegate mediaFileDownloaderDidStart:self];
}

- (void)_cleanup
{
    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStopped];
    [activityManager activateIdleTimer];

    _downloadInProgress = NO;
    _task = nil;
    [self terminateBackgroundTask];
}

- (void)_finishSuccessfully
{
    [self _cleanup];

#if TARGET_OS_IOS
    dispatch_async(dispatch_get_main_queue(), ^{
        // FIXME: Replace notifications by cleaner observers
        [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.VLCNewFileAddedNotification
                                                            object:self];
    });
#endif

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate mediaFileDownloaderDidFinish:self];
    });
}

- (void)_finishWithFailureDescription:(NSString *)description
{
    [self _closeFile];

    /* remove the partial file so observers don't surface it as completed */
    [_fileManager removeItemAtURL:[NSURL fileURLWithPath:_filePath] error:nil];

    [self _cleanup];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate mediaFileDownloader:self didFailWithDescription:description];
    });
}

- (void)reportProgress
{
    if (![self.delegate respondsToSelector:@selector(mediaFileDownloader:didUpdateReceivedBytes:expectedBytes:)]) {
        return;
    }

    unsigned long long received = _receivedBytes;
    if (received == _lastReportedBytes) {
        return;
    }
    _lastReportedBytes = received;

    int64_t expected = (int64_t)_expectedDownloadSize;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate mediaFileDownloader:self didUpdateReceivedBytes:(int64_t)received expectedBytes:expected];
    });
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
