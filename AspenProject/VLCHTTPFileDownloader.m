//
//  VLCHTTPFileDownloader.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 20.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCHTTPFileDownloader.h"
#import "VLCMenuViewController.h"
#import "VLCAppDelegate.h"

@interface VLCHTTPFileDownloader ()
{
    NSString *_filePath;
    NSUInteger _expectedDownloadSize;
    NSUInteger _receivedDataSize;
    NSString *_fileName;
    NSURLConnection *_urlConnection;
}

@end

@implementation VLCHTTPFileDownloader

- (NSString *)userReadableDownloadName
{
    return _fileName;
}

- (void)downloadFileFromURL:(NSURL *)url
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _fileName = url.lastPathComponent;
    _filePath = [searchPaths[0] stringByAppendingPathComponent:_fileName];
    _expectedDownloadSize = _receivedDataSize = 0;
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
    _urlConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!_urlConnection) {
        APLog(@"failed to establish connection");
        _downloadInProgress = NO;
    } else {
        _downloadInProgress = YES;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    NSUInteger statusCode = [response statusCode];
    if (statusCode == 200) {
        _expectedDownloadSize = [response expectedContentLength];
        [self.delegate downloadStarted];
        APLog(@"expected download size: %i", _expectedDownloadSize);
    } else {
        APLog(@"unhandled status code %i", statusCode);
        if ([self.delegate respondsToSelector:@selector(downloadFailedWithErrorDescription:)])
            [self.delegate downloadFailedWithErrorDescription:[NSString stringWithFormat:@"Download failed with HTTP code %i", statusCode]];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
    if (!fileHandle) {
        // create file
        [[NSFileManager defaultManager] createFileAtPath:_filePath contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];

        if (!fileHandle) {
            APLog(@"file creation failed, no data was saved");
            if ([self.delegate respondsToSelector:@selector(downloadFailedWithErrorDescription:)])
                [self.delegate downloadFailedWithErrorDescription:@"File creation failed"];
            return;
        }
    }

    @try {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];

        _receivedDataSize = _receivedDataSize + data.length;
        if ([self.delegate respondsToSelector:@selector(progressUpdatedTo:)])
            [self.delegate progressUpdatedTo: (float)_receivedDataSize / (float)_expectedDownloadSize];
    }
    @catch (NSException * e) {
        APLog(@"exception when writing to file %@", _filePath);
    }

    [fileHandle closeFile];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    APLog(@"http file download complete");
    VLCAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate updateMediaList];

    [self _downloadEnded];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    APLog(@"http file download failed (%i)", error.code);

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
        [self.delegate downloadFailedWithErrorDescription:@"Download canceled by user"];

    [self _downloadEnded];
}

- (void)_downloadEnded
{
    _downloadInProgress = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    [self.delegate downloadEnded];
}

@end
