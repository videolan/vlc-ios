/*****************************************************************************
 * VLCHTTPFileDownloader.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCHTTPFileDownloader.h"
#import "NSString+SupportedMedia.h"
#import "VLCAppDelegate.h"
#import "UIDevice+VLC.h"

@interface VLCHTTPFileDownloader ()
{
    NSString *_filePath;
    NSUInteger _expectedDownloadSize;
    NSUInteger _receivedDataSize;
    NSString *_fileName;
    NSURLConnection *_urlConnection;
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
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = [searchPaths[0] stringByAppendingPathComponent:@"Upload"];
    _fileName = url.lastPathComponent;
    _filePath = [basePath stringByAppendingPathComponent:_fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:basePath])
        [fileManager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];
    _expectedDownloadSize = _receivedDataSize = 0;
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
    [theRequest addValue:[NSString stringWithFormat:@"Mozilla/5.0 (%@; CPU OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/%@ Mobile/11A465 Safari/9537.53 VLC for iOS/%@", UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone", [[UIDevice currentDevice] systemVersion], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] forHTTPHeaderField:@"User-Agent"];
    _originalRequest = [theRequest mutableCopy];
    _urlConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!_urlConnection) {
        APLog(@"failed to establish connection");
        _downloadInProgress = NO;
    } else {
        _downloadInProgress = YES;
        [(VLCAppDelegate*)[UIApplication sharedApplication].delegate networkActivityStarted];
        [(VLCAppDelegate*)[UIApplication sharedApplication].delegate disableIdleTimer];
    }
}

- (void)downloadFileFromURLwithFileName:(NSURL *)url fileNameOfMedia:(NSString*)fileName
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = [searchPaths[0] stringByAppendingPathComponent:@"Upload"];
    _fileName = fileName;
    _filePath = [basePath stringByAppendingPathComponent:_fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:basePath])
        [fileManager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];
    _expectedDownloadSize = _receivedDataSize = 0;
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
    [theRequest addValue:[NSString stringWithFormat:@"Mozilla/5.0 (%@; CPU OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/%@ Mobile/11A465 Safari/9537.53 VLC for iOS/%@", UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone", [[UIDevice currentDevice] systemVersion], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] forHTTPHeaderField:@"User-Agent"];
    _originalRequest = [theRequest mutableCopy];
    _urlConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!_urlConnection) {
        APLog(@"failed to establish connection");
        _downloadInProgress = NO;
    } else {
        _downloadInProgress = YES;
        [(VLCAppDelegate*)[UIApplication sharedApplication].delegate networkActivityStarted];
        [(VLCAppDelegate*)[UIApplication sharedApplication].delegate disableIdleTimer];
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
        _fileName = [URL lastPathComponent];
        _filePath = [basePath stringByAppendingPathComponent:_fileName];
        if (![fileManager fileExistsAtPath:basePath])
            [fileManager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];

        NSMutableURLRequest *newRequest = [_originalRequest mutableCopy];
        [newRequest setURL:URL];
        return newRequest;
    } else
        return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    _statusCode = [response statusCode];
    if (_statusCode == 200) {
        if (![[response suggestedFilename] isSupportedFormat]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil) message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), [response suggestedFilename]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:nil];
            [alert show];

            [_urlConnection cancel];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:_filePath])
                [fileManager removeItemAtPath:_filePath error:nil];
            [self _downloadEnded];
        } else {
            _expectedDownloadSize = [response expectedContentLength];
            if (_expectedDownloadSize  < [[UIDevice currentDevice] freeDiskspace].longLongValue)
                [self.delegate downloadStarted];
            else {
                [_urlConnection cancel];
                [self _downloadEnded];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), _fileName, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) otherButtonTitles:nil];
                [alert show];
            }
            APLog(@"expected download size: %lu", (unsigned long)_expectedDownloadSize);
        }
    } else {
        APLog(@"unhandled status code %lu", (unsigned long)_statusCode);
        if ([self.delegate respondsToSelector:@selector(downloadFailedWithErrorDescription:)])
            [self.delegate downloadFailedWithErrorDescription:[NSString stringWithFormat:NSLocalizedString(@"HTTP_DOWNLOAD_FAILED",nil), _statusCode]];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
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

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    APLog(@"http file download complete");

    [self _downloadEnded];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    APLog(@"http file download failed (%li)", (long)error.code);

    if ([self.delegate respondsToSelector:@selector(downloadFailedWithErrorDescription:)])
        [self.delegate downloadFailedWithErrorDescription:error.description];

    [self _downloadEnded];
}

- (void)cancelDownload
{
    [_urlConnection cancel];

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
    [(VLCAppDelegate*)[UIApplication sharedApplication].delegate networkActivityStopped];
    [(VLCAppDelegate*)[UIApplication sharedApplication].delegate activateIdleTimer];

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = searchPaths[0];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *finalFilePath = [libraryPath stringByAppendingPathComponent:_fileName];

    if ([fileManager fileExistsAtPath:_filePath]) {
        [fileManager moveItemAtPath:_filePath toPath:finalFilePath error:nil];
        VLCAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate performSelectorOnMainThread:@selector(updateMediaList) withObject:nil waitUntilDone:NO];
    }

    [self.delegate downloadEnded];
}

@end
