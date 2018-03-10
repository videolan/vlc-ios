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

@interface VLCHTTPFileDownloader () <NSURLSessionDelegate>
{
    NSString *_filePath;
    long long _expectedDownloadSize;
    NSUInteger _receivedDataSize;
    NSString *_fileName;
    NSURLSessionTask *_sessionTask;
    NSMutableURLRequest *_originalRequest;
    NSUInteger _statusCode;
}

@end

@implementation VLCHTTPFileDownloader

- (NSString *)userReadableDownloadName
{
    return _fileName;
}

- (void)downloadFileFromURL:(NSURL *)url
{
    [self downloadFileFromURL:url withFileName:nil];
}

- (void)downloadFileFromURL:(NSURL *)url withFileName:(NSString*)fileName
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = [searchPaths[0] stringByAppendingPathComponent:@"Upload"];
    if (fileName)
        _fileName = fileName;
    else
        _fileName = [url.lastPathComponent stringByRemovingPercentEncoding];

    if (_fileName.pathExtension.length == 0 || ![_fileName isSupportedFormat]) {
        _fileName = [_fileName stringByAppendingPathExtension:@"vlc"];
    }

    _filePath = [basePath stringByAppendingPathComponent:_fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:basePath])
        [fileManager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];
    _expectedDownloadSize = _receivedDataSize = 0;
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
    [theRequest addValue:[NSString stringWithFormat:@"Mozilla/5.0 (%@; CPU OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/%@ Mobile/11A465 Safari/9537.53 VLC for iOS/%@", UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone", [[UIDevice currentDevice] systemVersion], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]] forHTTPHeaderField:@"User-Agent"];
    _originalRequest = [theRequest mutableCopy];

    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    _sessionTask = [urlSession dataTaskWithRequest:theRequest];
    [_sessionTask resume];
    if (!_sessionTask) {
        APLog(@"failed to establish connection");
        _downloadInProgress = NO;
    } else {
        _downloadInProgress = YES;
        VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
        [activityManager networkActivityStarted];
        [activityManager disableIdleTimer];
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    if (redirectResponse) {
        NSURL *URL = [request URL];

        NSFileManager *fileManager = [NSFileManager defaultManager];

        if ([fileManager fileExistsAtPath:_filePath])
            [fileManager removeItemAtPath:_filePath error:nil];

        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *basePath = [searchPaths[0] stringByAppendingPathComponent:@"Upload"];
        _fileName = [[URL lastPathComponent] stringByRemovingPercentEncoding];
        _filePath = [basePath stringByAppendingPathComponent:_fileName];
        if (![fileManager fileExistsAtPath:basePath])
            [fileManager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];

        NSMutableURLRequest *newRequest = [_originalRequest mutableCopy];
        [newRequest setURL:URL];
        return newRequest;
    } else
        return request;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    completionHandler(NSURLSessionResponseAllow);
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    _statusCode = [httpResponse statusCode];
    if (_statusCode == 200) {
        _expectedDownloadSize = [response expectedContentLength];
        APLog(@"expected download size: %lli", _expectedDownloadSize);
        if (![[response suggestedFilename] isSupportedFormat]) { //handle unsupported format
            VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil)
                                                              message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), [response suggestedFilename]]
                                                    cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                    otherButtonTitles:nil];
            [alert show];
            [_sessionTask cancel];
            [self _downloadEnded];
            return;
        }
        if (_expectedDownloadSize  > [[UIDevice currentDevice] VLCFreeDiskSpace].longLongValue) { //handle too big a download
            VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                             message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), _fileName, [[UIDevice currentDevice] model]]
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                    otherButtonTitles:nil];
            [alert show];
            [_sessionTask cancel];
            [self _downloadEnded];
            return;
        }
        [self.delegate downloadStarted];
    } else {
        APLog(@"unhandled status code %lu", (unsigned long)_statusCode);
        if ([self.delegate respondsToSelector:@selector(downloadFailedWithErrorDescription:)])
            [self.delegate downloadFailedWithErrorDescription:[NSString stringWithFormat:NSLocalizedString(@"HTTP_DOWNLOAD_FAILED",nil), _statusCode]];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
    if (!fileHandle && _statusCode != 404) {
        // create file
        [[NSFileManager defaultManager] createFileAtPath:_filePath contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];

        if (!fileHandle) {
            APLog(@"file creation failed, no data was saved");
            if ([self.delegate respondsToSelector:@selector(downloadFailedWithErrorDescription:)])
                [self.delegate downloadFailedWithErrorDescription:NSLocalizedString(@"HTTP_FILE_CREATION_FAILED",nil)];
            return;
        }
    }

    @try {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];

        _receivedDataSize = _receivedDataSize + [data length];
        if ([self.delegate respondsToSelector:@selector(progressUpdatedTo:receivedDataSize:expectedDownloadSize:)])
            [self.delegate progressUpdatedTo: (float)_receivedDataSize / (float)_expectedDownloadSize receivedDataSize:_receivedDataSize expectedDownloadSize:_expectedDownloadSize];
    }
    @catch (NSException * e) {
        APLog(@"exception when writing to file %@", _filePath);
    }

    [fileHandle closeFile];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error.code != -999) {
        if (error) {
            APLog(@"http file download failed (%li)", (long)error.code);
            if ([self.delegate respondsToSelector:@selector(downloadFailedWithErrorDescription:)])
                [self.delegate downloadFailedWithErrorDescription:error.description];
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
    [_sessionTask cancel];
    /* remove partially downloaded content */
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:_filePath])
        [fileManager removeItemAtPath:_filePath error:nil];

    if ([self.delegate respondsToSelector:@selector(downloadFailedWithErrorDescription:)])
        [self.delegate downloadFailedWithErrorDescription:NSLocalizedString(@"HTTP_DOWNLOAD_CANCELLED",nil)];

    [self _downloadEnded];
}

- (void)_downloadEnded
{
    _downloadInProgress = NO;
    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStopped];
    [activityManager activateIdleTimer];

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = searchPaths[0];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *finalFilePath = [libraryPath stringByAppendingPathComponent:_fileName];

    if ([fileManager fileExistsAtPath:_filePath]) {
        [fileManager moveItemAtPath:_filePath toPath:finalFilePath error:nil];
        [[VLCMediaFileDiscoverer sharedInstance] performSelectorOnMainThread:@selector(updateMediaList) withObject:nil waitUntilDone:NO];
    }

    [self.delegate downloadEnded];
}

@end
