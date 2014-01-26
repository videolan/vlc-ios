/*****************************************************************************
 * VLCHTTPConnection.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Jean-Baptiste Kempf <jb # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppDelegate.h"
#import "VLCHTTPConnection.h"
#import "HTTPConnection.h"
#import "MultipartFormDataParser.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "HTTPFileResponse.h"
#import "MultipartMessageHeaderField.h"
#import "VLCHTTPUploaderController.h"

@interface VLCHTTPConnection()
{
    MultipartFormDataParser *_parser;
    NSFileHandle *_storeFile;
    NSString *_filepath;
    UInt64 _contentLength;
    UInt64 _receivedContent;
}
@end

@implementation VLCHTTPConnection

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    // Add support for POST
    if ([method isEqualToString:@"POST"]) {
        if ([path isEqualToString:@"/upload.json"])
            return YES;
    }

    return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
    // Inform HTTP server that we expect a body to accompany a POST request
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.json"]) {
        // here we need to make sure, boundary is set in header
        NSString* contentType = [request headerField:@"Content-Type"];
        NSUInteger paramsSeparator = [contentType rangeOfString:@";"].location;
        if (NSNotFound == paramsSeparator)
            return NO;

        if (paramsSeparator >= contentType.length - 1)
            return NO;

        NSString* type = [contentType substringToIndex:paramsSeparator];
        if (![type isEqualToString:@"multipart/form-data"]) {
            // we expect multipart/form-data content type
            return NO;
        }

        // enumerate all params in content-type, and find boundary there
        NSArray* params = [[contentType substringFromIndex:paramsSeparator + 1] componentsSeparatedByString:@";"];
        for (NSString* param in params) {
            paramsSeparator = [param rangeOfString:@"="].location;
            if ((NSNotFound == paramsSeparator) || paramsSeparator >= param.length - 1)
                continue;

            NSString* paramName = [param substringWithRange:NSMakeRange(1, paramsSeparator-1)];
            NSString* paramValue = [param substringFromIndex:paramsSeparator+1];

            if ([paramName isEqualToString: @"boundary"])
                // let's separate the boundary from content-type, to make it more handy to handle
                [request setHeaderField:@"boundary" value:paramValue];
        }
        // check if boundary specified
        if (nil == [request headerField:@"boundary"])
            return NO;

        return YES;
    }
    return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.json"]) {
        return [[HTTPDataResponse alloc] initWithData:[@"\"OK\"" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    if ([method isEqualToString:@"GET"] && [path hasPrefix:@"/upload/"]) {
        // let download the uploaded files
        return [[HTTPFileResponse alloc] initWithFilePath: [[config documentRoot] stringByAppendingString:path] forConnection:self];
    }

    return [super httpResponseForMethod:method URI:path];
}

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
    // set up mime parser
    NSString* boundary = [request headerField:@"boundary"];
    _parser = [[MultipartFormDataParser alloc] initWithBoundary:boundary formEncoding:NSUTF8StringEncoding];
    _parser.delegate = self;

    APLog(@"expecting file of size %lli kB", contentLength / 1024);
    _contentLength = contentLength;
}

- (void)processBodyData:(NSData *)postDataChunk
{
    /* append data to the parser. It will invoke callbacks to let us handle
     * parsed data. */
    [_parser appendData:postDataChunk];

    _receivedContent += postDataChunk.length;

    APLog(@"received %lli kB (%lli %%)", _receivedContent / 1024, ((_receivedContent * 100) / _contentLength));
}

//-----------------------------------------------------------------
#pragma mark multipart form data parser delegate


- (void)processStartOfPartWithHeader:(MultipartMessageHeader*) header
{
    /* in this sample, we are not interested in parts, other then file parts.
     * check content disposition to find out filename */

    MultipartMessageHeaderField* disposition = (header.fields)[@"Content-Disposition"];
    NSString* filename = [(disposition.params)[@"filename"] lastPathComponent];

    if ((nil == filename) || [filename isEqualToString: @""]) {
        // it's either not a file part, or
        // an empty form sent. we won't handle it.
        return;
    }

    // create the path where to store the media temporarily
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* uploadDirPath = [searchPaths[0] stringByAppendingPathComponent:@"Upload"];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDir = YES;
    if (![fileManager fileExistsAtPath:uploadDirPath isDirectory:&isDir ]) {
        [fileManager createDirectoryAtPath:uploadDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    _filepath = [uploadDirPath stringByAppendingPathComponent: filename];

    APLog(@"Saving file to %@", _filepath);
    if (![fileManager createDirectoryAtPath:uploadDirPath withIntermediateDirectories:true attributes:nil error:nil])
        APLog(@"Could not create directory at path: %@", _filepath);

    if (![fileManager createFileAtPath:_filepath contents:nil attributes:nil])
        APLog(@"Could not create file at path: %@", _filepath);

    _storeFile = [NSFileHandle fileHandleForWritingAtPath:_filepath];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [(VLCAppDelegate*)[UIApplication sharedApplication].delegate disableIdleTimer];
}

- (void)processContent:(NSData*)data WithHeader:(MultipartMessageHeader*) header
{
    // here we just write the output from parser to the file.
    if (_storeFile) {
        @try {
            [_storeFile writeData:data];
        }
        @catch (NSException *exception) {
            APLog(@"File to write further data because storage is full.");
            [_storeFile closeFile];
            _storeFile = nil;
            /* don't block */
            [self performSelector:@selector(stop) withObject:nil afterDelay:0.1];
        }
    }

}

- (void)processEndOfPartWithHeader:(MultipartMessageHeader*)header
{
    // as the file part is over, we close the file.
    APLog(@"closing file");
    [_storeFile closeFile];
    _storeFile = nil;
}

- (BOOL)shouldDie
{
    if (_filepath) {
        if (_filepath.length > 0)
            [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate uploadController] moveFileFrom:_filepath];
    }
    return [super shouldDie];
}

@end
