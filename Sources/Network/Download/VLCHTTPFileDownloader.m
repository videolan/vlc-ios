/*****************************************************************************
 * VLCHTTPFileDownloader.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2026 VideoLAN. All rights reserved.
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
#import "NSURLSessionConfiguration+default.h"

@interface VLCHTTPFileDownloader () <NSURLSessionDelegate>
{
    NSURL *_url;
    NSString *_fileName;
    NSString *_fileExtension;
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
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultMPTCPConfiguration]
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
#if TARGET_OS_IOS
                          UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone",
#else
                          @"vision Pro",
#endif
                          [[UIDevice currentDevice] systemVersion],
                          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]
      forHTTPHeaderField:@"User-Agent"];
    return theRequest;
}

- (BOOL)containsSpecialCharactersIn:(NSString *)fileName
{
    NSMutableCharacterSet *characterSet = NSMutableCharacterSet.alphanumericCharacterSet;
    [characterSet formUnionWithCharacterSet:NSMutableCharacterSet.whitespaceCharacterSet];

    if ([fileName rangeOfCharacterFromSet:characterSet.invertedSet].location != NSNotFound) {
        return YES;
    }

    return NO;
}

- (NSString *)downloadFileFromVLCMedia:(VLCMedia *)media withName:(NSString *)name expectedDownloadSize:(unsigned long long)expectedDownloadSize
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = [searchPaths firstObject];

    _url = media.url;
    if ([self containsSpecialCharactersIn:[name stringByDeletingPathExtension]]) {
        // Properly percent encode the special characters in the media's name to validate the URL
        _fileName = [[name stringByDeletingPathExtension] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet];
        _fileExtension = [name pathExtension];
        NSString *newFileName = [NSString stringWithFormat:@"%@.%@", _fileName, _fileExtension];
        NSArray<NSString *> *pathComponents = @[libraryPath, newFileName];
        _fileURL = [NSURL fileURLWithPathComponents:pathComponents];
    } else {
        _fileName = name;
        _fileURL = [NSURL fileURLWithPath:[libraryPath stringByAppendingPathComponent:name]];
    }

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
        NSError *error;
        [fileManager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil) {
            APLog(@"Creating upload directory failed: %@", error.localizedDescription);
        }
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
    /* check Content-Disposition header for a server-provided filename */
    if ([downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)downloadTask.response;
        NSString *suggestedFilename = [self filenameFromContentDisposition:httpResponse.allHeaderFields[@"Content-Disposition"]];
        if (suggestedFilename.length > 0) {
            NSString *directory = [_fileURL.path stringByDeletingLastPathComponent];
            _fileURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:suggestedFilename]];
        }
    }

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

- (NSString *)filenameFromContentDisposition:(NSString *)contentDisposition
{
    if (!contentDisposition)
        return nil;

    /* try filename*= (RFC 5987 extended notation) first, then filename= */
    NSArray<NSString *> *patterns = @[@"filename\\*=(?:UTF-8''|utf-8'')([^;]+)",
                                      @"filename=\"([^\"]+)\"",
                                      @"filename=([^;\\s]+)"];
    for (NSString *pattern in patterns) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                              options:NSRegularExpressionCaseInsensitive
                                                                                error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:contentDisposition
                                                        options:0
                                                          range:NSMakeRange(0, contentDisposition.length)];
        if (match && match.numberOfRanges > 1) {
            NSString *filename = [contentDisposition substringWithRange:[match rangeAtIndex:1]];
            filename = [filename stringByRemovingPercentEncoding];
            filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
            if (filename.length > 0)
                return filename;
        }
    }
    return nil;
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
