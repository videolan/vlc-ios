/*****************************************************************************
 * VLCSubscriptionCacher.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSubscriptionCacher.h"
#import "VLCAppCoordinator.h"
#import "VLCTransferController.h"
#import "VLC-Swift.h"

static const NSTimeInterval VLCSubscriptionCacherProgressInterval = 0.5;

@interface VLCSubscriptionCacher () <VLCMediaDownloaderDelegate>
{
    VLCMediaDownloader *_downloader;

    /* The mutex guards the state shared with interruptCaching, which is called
     * from a different thread than cacheMRL:toPath:. */
    NSLock *_lock;
    VLCMediaDownloadTask *_task;
    NSFileHandle *_fileHandle;
    dispatch_semaphore_t _completion;
    BOOL _cancelled;
    BOOL _terminated;
    BOOL _success;

    NSUInteger _transferToken;
    NSTimeInterval _lastProgressReport;
}
@end

@implementation VLCSubscriptionCacher

- (instancetype)init
{
    if (self = [super init]) {
        _downloader = [[VLCMediaDownloader alloc] init];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

#pragma mark - VLCMLCacherDelegate

- (BOOL)cacheMRL:(NSURL *)mrl toPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager createFileAtPath:path contents:nil attributes:nil]) {
        APLog(@"%s: failed to create cache file at %@", __func__, path);
        return NO;
    }

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!fileHandle) {
        APLog(@"%s: failed to open cache file at %@", __func__, path);
        [fileManager removeItemAtPath:path error:nil];
        return NO;
    }

    VLCMedia *media = [VLCMedia mediaWithURL:mrl];
    if (!media) {
        APLog(@"%s: failed to create media for %@", __func__, mrl);
        [fileHandle closeFile];
        [fileManager removeItemAtPath:path error:nil];
        return NO;
    }

    dispatch_semaphore_t completion = dispatch_semaphore_create(0);
    NSString *displayName = [[VLCAppCoordinator sharedInstance].mediaLibraryService.medialib mediaWithMrl:mrl].title;
    if (displayName.length == 0) {
        displayName = mrl.lastPathComponent.stringByRemovingPercentEncoding ?: mrl.absoluteString;
    }

    [_lock lock];
    _fileHandle = fileHandle;
    _completion = completion;
    _terminated = NO;
    _success = NO;
    _transferToken = 0;
    _lastProgressReport = 0;
    /* A prior interruptCaching (e.g. a shutdown racing the next item) must abort
     * this download too rather than being silently forgotten. */
    BOOL abortImmediately = _cancelled;
    if (!abortImmediately) {
        _transferToken = [[VLCAppCoordinator sharedInstance].transferController startExternalDownloadWithName:displayName];
        _task = [_downloader downloadMedia:media delegate:self];
    }
    VLCMediaDownloadTask *task = _task;
    [_lock unlock];

    if (abortImmediately || !task) {
        if (!abortImmediately) {
            APLog(@"%s: failed to queue download for %@", __func__, mrl);
        }
        [self finishWithSuccess:NO];
        dispatch_semaphore_wait(completion, DISPATCH_TIME_FOREVER);
        return [self teardownAndCleanupPath:path];
    }

    dispatch_semaphore_wait(completion, DISPATCH_TIME_FOREVER);
    return [self teardownAndCleanupPath:path];
}

- (void)interruptCaching
{
    [_lock lock];
    _cancelled = YES;
    VLCMediaDownloadTask *task = _task;
    [_lock unlock];

    [task cancel];
}

#pragma mark - completion handling

/* Signals the waiting cacheMRL:toPath: exactly once. */
- (void)finishWithSuccess:(BOOL)success
{
    [_lock lock];
    if (_terminated) {
        [_lock unlock];
        return;
    }
    _terminated = YES;
    _success = success;
    dispatch_semaphore_t completion = _completion;
    [_lock unlock];

    if (completion) {
        dispatch_semaphore_signal(completion);
    }
}

- (BOOL)teardownAndCleanupPath:(NSString *)path
{
    [_lock lock];
    NSFileHandle *fileHandle = _fileHandle;
    BOOL success = _success;
    NSUInteger token = _transferToken;
    _fileHandle = nil;
    _task = nil;
    _completion = nil;
    _transferToken = 0;
    /* Reset for the next item; a cancellation only applies to the download it
     * interrupted. */
    _cancelled = NO;
    [_lock unlock];

    [fileHandle closeFile];

    if (!success) {
        /* Drop the partial file so the library never treats it as a complete
         * cached episode. */
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }

    if (token != 0) {
        VLCTransferController *transferController = [VLCAppCoordinator sharedInstance].transferController;
        if (success) {
            [transferController finishExternalDownload:token filePath:path];
        } else {
            [transferController failExternalDownload:token errorDescription:nil];
        }
    }

    return success;
}

- (void)reportProgressReceived:(uint64_t)received expected:(uint64_t)expected
{
    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;

    [_lock lock];
    NSUInteger token = _transferToken;
    BOOL due = token != 0 && (now - _lastProgressReport >= VLCSubscriptionCacherProgressInterval);
    if (due) {
        _lastProgressReport = now;
    }
    [_lock unlock];

    if (due) {
        [[VLCAppCoordinator sharedInstance].transferController updateExternalDownload:token
                                                                       receivedBytes:(long long)received
                                                                       expectedBytes:(long long)expected];
    }
}

#pragma mark - VLCMediaDownloaderDelegate

- (NSInteger)mediaDownloadTask:(VLCMediaDownloadTask *)task
                didReceiveData:(NSData *)data
                      position:(uint64_t)position
                         total:(uint64_t)total
{
    [_lock lock];
    BOOL cancelled = _cancelled;
    NSFileHandle *fileHandle = _fileHandle;
    [_lock unlock];

    if (cancelled) {
        return VLCMediaDownloadConsumedCancel;
    }

    @try {
        [fileHandle writeData:data];
    } @catch (NSException *exception) {
        APLog(@"%s: failed to write %lu bytes: %@", __func__,
              (unsigned long)data.length, exception.reason);
        return VLCMediaDownloadConsumedError;
    }

    [self reportProgressReceived:position expected:total];

    return data.length;
}

- (void)mediaDownloadTask:(VLCMediaDownloadTask *)task
          didUpdateStatus:(VLCMediaDownloadStatus)status
{
    switch (status) {
        case VLCMediaDownloadStatusPending:
        case VLCMediaDownloadStatusRunning:
        case VLCMediaDownloadStatusPaused:
            break;

        case VLCMediaDownloadStatusFinished:
            [self finishWithSuccess:YES];
            break;

        case VLCMediaDownloadStatusCancelled:
        case VLCMediaDownloadStatusError:
            [self finishWithSuccess:NO];
            break;
    }
}

- (void)mediaDownloadTask:(VLCMediaDownloadTask *)task
       didReceiveSubitems:(VLCMediaList *)subitems
{
    /* A feed that resolves to a playlist cannot be cached as a single file. */
    APLog(@"%s: media resolved to subitems and cannot be cached as a file", __func__);
    [task cancel];
}

- (void)mediaDownloadTask:(VLCMediaDownloadTask *)task
         didReceiveSlaves:(NSArray<VLCMediaSlave *> *)slaves
{
    APLog(@"%s: ignoring %lu slaves", __func__, (unsigned long)slaves.count);
}

@end
