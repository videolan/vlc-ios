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
#import "VLCAppDelegate.h"

@interface VLCHTTPFileDownloader ()
{
    NSString *_filePath;
    NSUInteger _expectedDownloadSize;
    NSUInteger _receivedDataSize;
    NSString *_fileName;
    NSURLConnection *_urlConnection;
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
    _urlConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!_urlConnection) {
        APLog(@"failed to establish connection");
        _downloadInProgress = NO;
    } else {
        _downloadInProgress = YES;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [(VLCAppDelegate*)[UIApplication sharedApplication].delegate disableIdleTimer];
    }
}

- (void)downloadFileFromURLwithFileName:(NSURL *)url fileNameOfMedia:(NSString*) fileName
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
    _urlConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!_urlConnection) {
        APLog(@"failed to establish connection");
        _downloadInProgress = NO;
    } else {
        _downloadInProgress = YES;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [(VLCAppDelegate*)[UIApplication sharedApplication].delegate disableIdleTimer];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    _statusCode = [response statusCode];
    if (_statusCode == 200) {
        _expectedDownloadSize = [response expectedContentLength];
        [self.delegate downloadStarted];
        APLog(@"expected download size: %lu", (unsigned long)_expectedDownloadSize);
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

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    APLog(@"http file download complete");

    [self _downloadEnded];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
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
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
