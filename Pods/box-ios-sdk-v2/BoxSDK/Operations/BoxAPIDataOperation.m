//
//  BoxAPIDataOperation.m
//  BoxSDK
//
//  Created on 2/27/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIDataOperation.h"

#import "BoxSDKErrors.h"
#import "BoxLog.h"

@interface BoxAPIDataOperation ()

// Buffer data received from the connection in an NSData. Write to the
// output stream from this NSData when space becomes availble
@property (nonatomic, readwrite, strong) NSMutableData *receivedDataBuffer;

// The output stream may trigger the has space available callback when no data
// is buffered. Use this BOOL to keep track of this state and manually invoke
// the callback if necessary
@property (nonatomic, readwrite, assign) BOOL outputStreamHasSpaceAvailable;

@property (nonatomic, readwrite, assign) unsigned long long bytesReceived;

- (void)writeDataToOutputStream;

- (long long)contentLength;

- (void)close;
- (void)abortWithError:(NSError *)error;

@end

@implementation BoxAPIDataOperation

@synthesize successBlock = _successBlock;
@synthesize failureBlock = _failureBlock;
@synthesize progressBlock = _progressBlock;
@synthesize fileID = _fileID;

@synthesize outputStream = _outputStream;
@synthesize receivedDataBuffer = _receivedDataBuffer;
@synthesize outputStreamHasSpaceAvailable = _outputStreamHasSpaceAvailable;
@synthesize bytesReceived = _bytesReceived;

- (id)initWithURL:(NSURL *)URL HTTPMethod:(NSString *)HTTPMethod body:(NSDictionary *)body queryParams:(NSDictionary *)queryParams OAuth2Session:(BoxOAuth2Session *)OAuth2Session
{
    self = [super initWithURL:URL HTTPMethod:HTTPMethod body:body queryParams:queryParams OAuth2Session:OAuth2Session];

    if (self != nil)
    {
        _outputStream = [NSOutputStream outputStreamToMemory];
        _receivedDataBuffer = [NSMutableData dataWithCapacity:0];
        _outputStreamHasSpaceAvailable = YES; // attempt to write to the output stream as soon as we receive data
        _bytesReceived = 0;
    }

    return self;
}

- (void)prepareAPIRequest
{
    [super prepareAPIRequest];

    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.outputStream.delegate = self;
}

// BoxAPIDataOperation should only ever be GET requests so there should not be a body
- (NSData *)encodeBody:(NSDictionary *)bodyDictionary
{
    return nil;
}

- (void)processResponseData:(NSData *)data
{
    // This method assumes that all data received from the NSURLConnection is buffered. This operation
    // streams all received data to its output stream, so do nothing in this method.
}

#pragma mark - Callback methods

- (void)performCompletionCallback
{
    if (self.error == nil)
    {
        if (self.successBlock)
        {
            self.successBlock(self.fileID, [self contentLength]);
        }
    }
    else
    {
        if (self.failureBlock)
        {
            self.failureBlock(self.APIRequest, self.HTTPResponse, self.error);
        }
    }
}

- (void)performProgressCallback
{
    if (self.progressBlock)
    {
        self.progressBlock([self contentLength], self.bytesReceived);
    }
}

- (void)cancel
{
    // Close the output stream before cancelling the operation
    [self close];

    [super cancel];
}

#pragma mark - Output Stream methods

- (long long)contentLength
{
    return [self.HTTPResponse expectedContentLength];
}

- (void)close
{
    self.outputStream.delegate = nil;
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    [self.outputStream close];
    _outputStream = nil;
}

- (void)abortWithError:(NSError *)error
{
    [self close];
    [self.connection cancel];
    [self connection:self.connection didFailWithError:error];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [super connection:connection didReceiveResponse:response];
    [self.outputStream open];
}

// Override this delegate method from the default BoxAPIOperation implementation
// By default, BoxAPIOperation buffers all received data from the connection in
// self.responseData. This operation differs in that it should write its received
// data immediately to its output stream. Failure to do so will cause downloads to
// be buffered entirely in memory.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Buffer received data in an NSMutableData ivar because the output stream
    // may not have space available for writing
    [self.receivedDataBuffer appendData:data];

    // If the output stream does have space available, trigger the writeDataToOutputStream
    // handler so the data is consumed by the output stream. This state would occur if
    // an NSStreamEventHasSpaceAvailable event was received but receivedDataBuffer was
    // empty.
    if (self.outputStreamHasSpaceAvailable)
    {
        self.outputStreamHasSpaceAvailable = NO;
        [self writeDataToOutputStream];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [super connection:connection didFailWithError:error];
    [self close];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [super connectionDidFinishLoading:connection];
    [self close];
}

#pragma mark - NSStream Delegate

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)eventCode
{
    if (eventCode & NSStreamEventHasSpaceAvailable)
    {
        [self writeDataToOutputStream];
    }
}

- (void)writeDataToOutputStream
{
    while ([self.outputStream hasSpaceAvailable])
    {
        if (self.receivedDataBuffer.length == 0)
        {
            BOXLog(@"BoxAPIDataOperation has space on output stream but no data to write to it.");
            self.outputStreamHasSpaceAvailable = YES;
            return; // bail out because we have nothing to write
        }

        NSInteger bytesWrittenToOutputStream = [self.outputStream write:[self.receivedDataBuffer bytes] maxLength:self.receivedDataBuffer.length];

        if (bytesWrittenToOutputStream == -1)
        {
            // Failed to write from to output stream. The download cannot be completed
            BOXLog(@"BoxAPIDataOperation failed to write to the output stream. Aborting download.");
            NSError *streamWriteError = [self.outputStream streamError];
            NSDictionary *userInfo = @{
                NSUnderlyingErrorKey : streamWriteError,
            };
            NSError *downloadError = [[NSError alloc] initWithDomain:BoxSDKErrorDomain code:BoxSDKStreamErrorWriteFailed userInfo:userInfo];
            [self abortWithError:downloadError];

            return; // Bail out due to error
        }
        else
        {
            self.bytesReceived += bytesWrittenToOutputStream;
            [self performProgressCallback];

            // truncate buffer by removing the consumed bytes from the front
            [self.receivedDataBuffer replaceBytesInRange:NSMakeRange(0, bytesWrittenToOutputStream) withBytes:NULL length:0];
        }
    }
}

@end
