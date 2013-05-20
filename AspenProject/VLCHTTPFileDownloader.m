//
//  VLCHTTPFileDownloader.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 20.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCHTTPFileDownloader.h"
#import "VLCAddMediaViewController.h"
#import "VLCCircularProgressIndicator.h"
#import "VLCAppDelegate.h"

@interface VLCHTTPFileDownloader ()
{
    VLCCircularProgressIndicator *_progressIndicator;
    NSString *_filePath;
    NSUInteger _expectedDownloadSize;
    NSUInteger _receivedDataSize;
}

@end

@implementation VLCHTTPFileDownloader

- (void)downloadFileFromURL:(NSURL *)url
{
    _progressIndicator = self.mediaViewController.httpDownloadProgressIndicator;
    _progressIndicator.progress = 0.;
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _filePath = [searchPaths[0] stringByAppendingPathComponent:url.lastPathComponent];
    _expectedDownloadSize = _receivedDataSize = 0;
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!theConnection) {
        APLog(@"failed to establish connection");
        _downloadInProgress = NO;
    } else {
        _downloadInProgress = YES;
        _progressIndicator.hidden = NO;
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    NSUInteger statusCode = [response statusCode];
    if (statusCode == 200) {
        _expectedDownloadSize = [response expectedContentLength];
        APLog(@"expected download size: %i", _expectedDownloadSize);
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
            return;
        }
    }

    @try {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];

        _receivedDataSize = _receivedDataSize + data.length;
        _progressIndicator.progress = (float)_receivedDataSize / (float)_expectedDownloadSize;
    }
    @catch (NSException * e) {
        APLog(@"exception when writing to file %@", _filePath);
    }

    [fileHandle closeFile];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    APLog(@"http file download complete");
    _downloadInProgress = NO;
    _progressIndicator.hidden = YES;

    VLCAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate updateMediaList];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    APLog(@"http file download failed (%i)", error.code);
    _downloadInProgress = NO;
    _progressIndicator.hidden = YES;
}

@end
