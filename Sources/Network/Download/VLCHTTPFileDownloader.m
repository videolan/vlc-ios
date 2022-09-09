/*****************************************************************************
 * VLCHTTPFileDownloader.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCHTTPFileDownloader.h"
#import "VLCActivityManager.h"
#import "VLCMediaFileDiscoverer.h"
#import "VLC-Swift.h"

@interface VLCHTTPFileDownloader () <NSURLSessionDelegate>
{
    NSURL *_url;
    NSString *_fileName;
    NSURL *_fileURL;

    NSURLSession *_urlSession;
    NSURLSessionTask *_urlSessionTask;
    dispatch_queue_t _downloadsAccessQueue;

    BOOL _downloadInProgress;
}
@end

@implementation VLCHTTPFileDownloader

- (instancetype)init
{
    if (self = [super init]) {
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                    delegate:self
                                               delegateQueue:nil];
        _downloadsAccessQueue = dispatch_queue_create("VLCHTTPFileDownloader.downloadsQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSString *)downloadLocationPath
{
    return _fileURL.path;
}

- (BOOL)downloadInProgress
{
    return _downloadInProgress;
}

- (NSMutableURLRequest *)mutableURLRequest
{
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:_url];
    [theRequest addValue:[NSString stringWithFormat:@"Mozilla/5.0 (%@; CPU OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/%@ Safari/9537.53 VLC for iOS/%@",
                          UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone",
                          [[UIDevice currentDevice] systemVersion],
                          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]
      forHTTPHeaderField:@"User-Agent"];
    return theRequest;
}

- (NSString *)downloadFileFromVLCMedia:(VLCMedia *)media withName:(NSString *)name expectedDownloadSize:(unsigned long long)expectedDownloadSize
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = [searchPaths firstObject];

    _url = media.url;
    _fileName = name;
    _fileURL = [NSURL fileURLWithPath:[libraryPath stringByAppendingPathComponent:name]];

    NSString *identifier = [[NSUUID UUID] UUIDString];

    _urlSessionTask = [_urlSession downloadTaskWithRequest:[self mutableURLRequest]];
    _urlSessionTask.taskDescription = identifier;
    [_urlSessionTask resume];

    if (!_urlSessionTask) {
        APLog(@"failed to establish connection");
        return nil;
    } else {
        VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
        [activityManager networkActivityStarted];
        [activityManager disableIdleTimer];
    }

    _downloadInProgress = YES;
    return identifier;
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    NSURL *newUrl = request.URL;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:[_fileURL path]])
        [fileManager removeItemAtURL:_fileURL error:nil];

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = [[searchPaths firstObject] stringByAppendingPathComponent:kVLCHTTPUploadDirectory];
    _fileName = [[newUrl lastPathComponent] stringByRemovingPercentEncoding];
    _fileURL = [NSURL fileURLWithPath:[basePath stringByAppendingPathComponent:_fileName]];

    if (![fileManager fileExistsAtPath:basePath]) {
        [fileManager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    completionHandler(nil);
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if ([self.delegate respondsToSelector:@selector(progressUpdatedTo:receivedDataSize:expectedDownloadSize:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate progressUpdatedTo:(float)totalBytesWritten / (float)totalBytesExpectedToWrite
                            receivedDataSize:bytesWritten
                        expectedDownloadSize:totalBytesExpectedToWrite];
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:[_fileURL path]]) {
        if (@available(iOS 10.3, *)) {
            //The copy should be instant iOS 10.3+ with APFS
            [fileManager copyItemAtURL:location toURL:_fileURL error:nil];
        } else {
            [fileManager moveItemAtURL:location toURL:_fileURL error:nil];
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error.code != -999) {
        if (error) {
            APLog(@"http file download failed (%li)", (long)error.code);

            if ([self.delegate respondsToSelector:@selector(downloadFailedWithErrorDescription:forDownloader:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate downloadFailedWithErrorDescription:error.description
                                                        forDownloader:self];
                });
            }
        } else {
            APLog(@"http file download complete");
        }
        [self _downloadEnded];
    } else {
        APLog(@"http file download canceled");
    }
}

- (void)cancelDownload
{
    [_urlSessionTask cancel];
    /* remove partially downloaded content */
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:_fileURL.path])
        [fileManager removeItemAtURL:_fileURL error:nil];

    if ([self.delegate respondsToSelector:@selector(downloadFailedWithErrorDescription:forDownloader:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate downloadFailedWithErrorDescription:NSLocalizedString(@"HTTP_DOWNLOAD_CANCELLED",nil)
                                                forDownloader:self];
        });
    }

    [self _downloadEnded];
}

- (void)_downloadEnded
{
    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStopped];
    [activityManager activateIdleTimer];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[_fileURL path]]) {
        [[VLCMediaFileDiscoverer sharedInstance] performSelectorOnMainThread:@selector(updateMediaList) withObject:nil waitUntilDone:NO];
#if TARGET_OS_IOS
        dispatch_async(dispatch_get_main_queue(), ^{
            // FIXME: Replace notifications by cleaner observers
            [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.VLCNewFileAddedNotification
                                                                object:self];
        });
#endif
    }

    _downloadInProgress = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate mediaFileDownloadEnded:self];
    });
}

@end
