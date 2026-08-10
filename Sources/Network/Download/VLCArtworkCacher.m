/*****************************************************************************
 * VLCArtworkCacher.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCArtworkCacher.h"
#import "VLC-Swift.h"

@interface VLCArtworkCacher ()
{
    NSLock *_lock;
    NSURLSessionDownloadTask *_task;
    BOOL _cancelled;
}
@end

@implementation VLCArtworkCacher

- (instancetype)init
{
    if (self = [super init]) {
        _lock = [[NSLock alloc] init];
    }
    return self;
}

#pragma mark - VLCMLCacherDelegate

- (VLCMLCacheStatus)cacheMRL:(NSURL *)mrl toPath:(NSString *)path
{
    NSString *scheme = mrl.scheme.lowercaseString;
    if (![scheme isEqualToString:@"https"] && ![scheme isEqualToString:@"http"]) {
        APLog(@"%s: unsupported scheme for %@", __func__, mrl);
        return VLCMLCacheStatusFailed;
    }

    dispatch_semaphore_t completion = dispatch_semaphore_create(0);
    __block VLCMLCacheStatus status = VLCMLCacheStatusFailed;

    NSURLSessionDownloadTask *task = [[NSURLSession sharedSession]
        downloadTaskWithURL:mrl
          completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        status = [self moveDownloadedArtworkFrom:location
                                          toPath:path
                                        response:response
                                           error:error];
        dispatch_semaphore_signal(completion);
    }];

    [_lock lock];
    BOOL cancelled = _cancelled;
    /* A cancellation only applies to the download it interrupted. */
    _cancelled = NO;
    if (!cancelled) {
        _task = task;
    }
    [_lock unlock];

    if (cancelled) {
        return VLCMLCacheStatusCancelled;
    }

    [task resume];
    dispatch_semaphore_wait(completion, DISPATCH_TIME_FOREVER);

    [_lock lock];
    _task = nil;
    _cancelled = NO;
    [_lock unlock];

    return status;
}

- (void)interruptCaching
{
    [_lock lock];
    _cancelled = YES;
    NSURLSessionDownloadTask *task = _task;
    [_lock unlock];

    [task cancel];
}

- (VLCMLCacheStatus)moveDownloadedArtworkFrom:(NSURL *)location
                                       toPath:(NSString *)path
                                     response:(NSURLResponse *)response
                                        error:(NSError *)error
{
    if (!location) {
        if ([error.domain isEqualToString:NSURLErrorDomain]) {
            if (error.code == NSURLErrorCancelled) {
                return VLCMLCacheStatusCancelled;
            }
            if (error.code == NSURLErrorTimedOut) {
                return VLCMLCacheStatusTimeout;
            }
        }
        APLog(@"%s: download failed: %@", __func__, error.localizedDescription);
        return VLCMLCacheStatusFailed;
    }

    NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]]
                         ? ((NSHTTPURLResponse *)response).statusCode : 200;
    if (statusCode < 200 || statusCode > 299) {
        APLog(@"%s: download failed with status %li", __func__, (long)statusCode);
        return VLCMLCacheStatusFailed;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:path error:nil];

    NSError *moveError;
    if (![fileManager moveItemAtURL:location
                              toURL:[NSURL fileURLWithPath:path]
                              error:&moveError]) {
        APLog(@"%s: failed to store the artwork at %@: %@", __func__, path,
              moveError.localizedDescription);
        return VLCMLCacheStatusFailed;
    }

    return VLCMLCacheStatusSuccess;
}

@end
