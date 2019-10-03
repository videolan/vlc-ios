/*****************************************************************************
 * VLCHTTPFileDownloader.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCHTTPFileDownloader.h"
#import "NSString+SupportedMedia.h"
#import "VLCActivityManager.h"
#import "UIDevice+VLC.h"
#import "VLCMediaFileDiscoverer.h"
#import "VLC-Swift.h"

@interface VLCHTTPFileDownloaderTask: NSObject
@property (nonatomic) NSURLSessionTask *sessionTask;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSURL *fileURL;
@end

@implementation VLCHTTPFileDownloaderTask

- (NSMutableURLRequest *)buildRequest
{
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:self.url];
    [theRequest addValue:[NSString stringWithFormat:@"Mozilla/5.0 (%@; CPU OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/%@ Safari/9537.53 VLC for iOS/%@", UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone", [[UIDevice currentDevice] systemVersion], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]] forHTTPHeaderField:@"User-Agent"];
    return theRequest;
}
@end

@interface VLCHTTPFileDownloader () <NSURLSessionDelegate>

@property (nonatomic) NSURLSession *urlSession;
@property (nonatomic) NSMutableDictionary *downloads;
@property (nonatomic) dispatch_queue_t downloadsAccessQueue;
@end

@implementation VLCHTTPFileDownloader

- (instancetype)init
{
    if (self = [super init]) {
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                    delegate:self
                                               delegateQueue:nil];
        _downloads = [[NSMutableDictionary alloc] init];
        _downloadsAccessQueue = dispatch_queue_create("VLCHTTPFileDownloader.downloadsQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSString *)downloadFileFromURL:(NSURL *)url
{
    return [self downloadFileFromURL:url withFileName:nil];
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
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fileName = [path lastPathComponent];
    NSString *finalFilePath = [path stringByDeletingLastPathComponent];

    if ([fileManager fileExistsAtPath:path]) {
        NSString *potentialFilename;
        NSString *fileExtension = [fileName pathExtension];
        NSString *rawFileName = [fileName stringByDeletingPathExtension];
        for (NSUInteger x = 1; x < 100; x++) {
            potentialFilename = [NSString stringWithFormat:@"%@_%lu.%@",
                                 rawFileName, (unsigned long)x, fileExtension];
            if (![fileManager fileExistsAtPath:[finalFilePath stringByAppendingPathComponent:potentialFilename]]) {
                break;
            }
        }
        return [finalFilePath stringByAppendingPathComponent:potentialFilename];
    }
    return path;
}

- (NSString *)downloadFileFromURL:(NSURL *)url withFileName:(NSString*)fileName
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = [searchPaths firstObject];

    VLCHTTPFileDownloaderTask *downloadTask = [[VLCHTTPFileDownloaderTask alloc] init];
    downloadTask.url = url;
    NSString *downloadFileName;

    fileName = fileName ?: [url.lastPathComponent stringByRemovingPercentEncoding];

    downloadFileName = [self createPotentialNameFromName:fileName];

    if (downloadFileName.pathExtension.length == 0 || ![downloadFileName isSupportedFormat]) {
        NSString *urlExtension = url.pathExtension;
        NSString *extension = urlExtension.length != 0 ? urlExtension : @"vlc";
        downloadFileName = [fileName stringByAppendingPathExtension:extension];
    }
    downloadTask.fileName = downloadFileName;
    downloadTask.fileURL = [NSURL fileURLWithPath:[libraryPath stringByAppendingPathComponent:downloadFileName]];

    NSString *identifier = [[NSUUID UUID] UUIDString];

    NSURLSessionTask *sessionTask = [self.urlSession downloadTaskWithRequest:[downloadTask buildRequest]];
    sessionTask.taskDescription = identifier;
    [sessionTask resume];

    if (!sessionTask) {
        APLog(@"failed to establish connection");
        return nil;
    } else {
        VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
        [activityManager networkActivityStarted];
        [activityManager disableIdleTimer];
    }

    downloadTask.sessionTask = sessionTask;
    [self _addDownloadTask:downloadTask identifier:identifier];
    _downloadInProgress = YES;
    return identifier;
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    VLCHTTPFileDownloaderTask *downloadTask = [self _downloadTaskWithIdentifier:task.taskDescription];
    NSURL *newUrl = request.URL;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:[downloadTask.fileURL path]])
        [fileManager removeItemAtURL:downloadTask.fileURL error:nil];

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = [[searchPaths firstObject] stringByAppendingPathComponent:kVLCHTTPUploadDirectory];
    downloadTask.fileName = [[newUrl lastPathComponent] stringByRemovingPercentEncoding];
    downloadTask.fileURL = [NSURL fileURLWithPath:[basePath stringByAppendingPathComponent:downloadTask.fileName]];

    if (![fileManager fileExistsAtPath:basePath]) {
        [fileManager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    completionHandler(nil);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if ([self.delegate respondsToSelector:@selector(progressUpdatedTo:receivedDataSize:expectedDownloadSize:identifier:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate progressUpdatedTo: (float)totalBytesWritten / (float)totalBytesExpectedToWrite receivedDataSize:bytesWritten expectedDownloadSize:totalBytesExpectedToWrite identifier:downloadTask.taskDescription];
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    VLCHTTPFileDownloaderTask *task = [self _downloadTaskWithIdentifier:downloadTask.taskDescription];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:[task.fileURL path]]) {
        if (@available(iOS 10.3, *)) {
            //The copy should be instant iOS 10.3+ with AFS
            [fileManager copyItemAtURL:location toURL:task.fileURL error:nil];
        } else {
            [fileManager moveItemAtURL:location toURL:task.fileURL error:nil];
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error.code != -999) {
        if (error) {
            APLog(@"http file download failed (%li)", (long)error.code);

            if ([self.delegate respondsToSelector:@selector(downloadFailedWithIdentifier:errorDescription:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate downloadFailedWithIdentifier:task.taskDescription errorDescription:error.description];
                });
            }
        } else {
            APLog(@"http file download complete");
        }
        [self _downloadEndedWithIdentifier:task.taskDescription];
    } else {
        APLog(@"http file download canceled");
    }
}

- (void)cancelDownloadWithIdentifier:(NSString *)identifier
{
    VLCHTTPFileDownloaderTask *downloadTask = [self _downloadTaskWithIdentifier:identifier];
    [downloadTask.sessionTask cancel];
    /* remove partially downloaded content */
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:downloadTask.fileURL.path])
        [fileManager removeItemAtURL:downloadTask.fileURL error:nil];

    if ([self.delegate respondsToSelector:@selector(downloadFailedWithIdentifier:errorDescription:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate downloadFailedWithIdentifier:identifier errorDescription:NSLocalizedString(@"HTTP_DOWNLOAD_CANCELLED",nil)];
        });
    }

    [self _downloadEndedWithIdentifier:identifier];
}

- (void)_downloadEndedWithIdentifier:(NSString *)identifier
{
    VLCHTTPFileDownloaderTask *task = [self _downloadTaskWithIdentifier:identifier];

    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStopped];
    [activityManager activateIdleTimer];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[task.fileURL path]]) {
        [[VLCMediaFileDiscoverer sharedInstance] performSelectorOnMainThread:@selector(updateMediaList) withObject:nil waitUntilDone:NO];
#if TARGET_OS_IOS
        dispatch_async(dispatch_get_main_queue(), ^{
            // FIXME: Replace notifications by cleaner observers
            [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.VLCNewFileAddedNotification
                                                                object:self];
        });
#endif
    }

    [self _removeDownloadWithIdentifier:identifier];
    _downloadInProgress = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate downloadEndedWithIdentifier:identifier];
    });
}


- (void)_removeDownloadWithIdentifier:(NSString *)identifier
{
    dispatch_async(_downloadsAccessQueue, ^{
        [self.downloads removeObjectForKey:identifier];
    });
}

- (VLCHTTPFileDownloaderTask *)_downloadTaskWithIdentifier:(NSString *)identifier
{
    __block VLCHTTPFileDownloaderTask *task;
    dispatch_sync(_downloadsAccessQueue, ^{
        task = [self.downloads objectForKey:identifier];
    });
    return task;
}

- (void)_addDownloadTask:(VLCHTTPFileDownloaderTask *)task identifier:(NSString *)identifier
{
    dispatch_async(_downloadsAccessQueue, ^{
        [self.downloads setObject:task forKey:identifier];
    });
}

@end
