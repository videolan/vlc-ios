//
//  BoxAPIOperation.m
//  BoxSDK
//
//  Created on 2/27/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIOperation.h"

#import "BoxSDKErrors.h"
#import "BoxLog.h"
#import "NSString+BoxURLHelper.h"

typedef enum {
    BoxAPIOperationStateReady = 1,
    BoxAPIOperationStateExecuting,
    BoxAPIOperationStateFinished
} BoxAPIOperationState;

static NSString * BoxOperationKeyPathForState(BoxAPIOperationState state) {
    switch (state) {
        case BoxAPIOperationStateReady:
            return @"isReady";
        case BoxAPIOperationStateExecuting:
            return @"isExecuting";
        case BoxAPIOperationStateFinished:
            return @"isFinished";
        default:
            return @"state";
    }
}

static BOOL BoxOperationStateTransitionIsValid(BoxAPIOperationState fromState, BoxAPIOperationState toState, BOOL isCancelled) {
    switch (fromState) {
        case BoxAPIOperationStateReady:
            switch (toState) {
                case BoxAPIOperationStateExecuting:
                    return YES;
                case BoxAPIOperationStateFinished:
                    return isCancelled;
                default:
                    return NO;
            }
        case BoxAPIOperationStateExecuting:
            switch (toState) {
                case BoxAPIOperationStateFinished:
                    return YES;
                default:
                    return NO;
            }
        case BoxAPIOperationStateFinished:
            return NO;
        default:
            return YES;
    }
}

@interface BoxAPIOperation()

#pragma mark - Thread keepalive
+ (NSThread *)globalAPIOperationNetworkThread;
+ (void)globalAPIOperationNetworkThreadEntryPoint:(id)sender;

#pragma mark - Thread entry points for operation
- (void)executeOperation;
- (void)cancelConnection;

#pragma mark - NSOperation state
@property (nonatomic, readwrite, assign) BoxAPIOperationState state;
- (void)finish;

@end

@implementation BoxAPIOperation

@synthesize OAuth2Session = _OAuth2Session;
@synthesize OAuth2AccessToken = _OAuth2AccessToken;

// request properties
@synthesize baseRequestURL = _baseRequestURL;
@synthesize body = _body;
@synthesize queryStringParameters = _queryStringParameters;
@synthesize APIRequest = _APIRequest;
@synthesize connection = _connection;

// request response properties
@synthesize responseData = _responseData;
@synthesize HTTPResponse = _HTTPResponse;

// error handling
@synthesize error = _error;

@synthesize state = _state;

- (NSString *)description
{
    return [[super description] stringByAppendingFormat:@" %@ %@", self.HTTPMethod, self.baseRequestURL];
}

- (id)init
{
    self = [self initWithURL:nil HTTPMethod:nil body:nil queryParams:nil OAuth2Session:nil];
    BOXLog(@"Initialize operations with initWithURL:HTTPMethod:body:queryParams:OAuth2Session:. %@ cannot make an API call", self);
    return self;
}

- (id)initWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod body:(NSDictionary *)body queryParams:(NSDictionary *)queryParams OAuth2Session:(BoxOAuth2Session *)OAuth2Session
{
    self = [super init];
    if (self != nil)
    {
        _baseRequestURL = URL;
        _body = body;
        _queryStringParameters = queryParams;
        _OAuth2Session = OAuth2Session;

        _APIRequest = nil;
        _connection = nil; // delay setting up the connection as long as possible so the OAuth2 credentials remain fresh

        NSMutableURLRequest *APIRequest = [NSMutableURLRequest requestWithURL:[self requestURLWithURL:_baseRequestURL queryStringParameters:_queryStringParameters]];
        APIRequest.HTTPMethod = HTTPMethod;

        NSData *encodedBody = [self encodeBody:_body];
        APIRequest.HTTPBody = encodedBody;

        _APIRequest = APIRequest;

        _responseData = [NSMutableData data];

        self.state = BoxAPIOperationStateReady;
    }
    
    return self;
}

- (void)setState:(BoxAPIOperationState)state
{
    if (!BoxOperationStateTransitionIsValid(self.state, state, [self isCancelled]))
    {
        return;
    }
    NSString *oldStateKey = BoxOperationKeyPathForState(self.state);
    NSString *newStateKey = BoxOperationKeyPathForState(state);

    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
}

#pragma mark - Accessors
- (BoxAPIHTTPMethod *)HTTPMethod
{
    return self.APIRequest.HTTPMethod;
}

#pragma mark - Build NSURLRequest
- (NSData *)encodeBody:(NSDictionary *)bodyDictionary
{
    BOXAbstract();
    return nil;
}

- (NSURL *)requestURLWithURL:(NSURL *)baseURL queryStringParameters:(NSDictionary *)queryDictionary
{
    if ([queryDictionary count] == 0)
    {
        return baseURL;
    }

    NSMutableArray *queryParts = [NSMutableArray array];
    for (id key in queryDictionary)
    {
        id value = [queryDictionary objectForKey:key];
        NSString *keyString = [NSString box_stringWithString:[key description] URLEncoded:YES];
        NSString *valueString = [NSString box_stringWithString:[value description] URLEncoded:YES];

        [queryParts addObject:[NSString stringWithFormat:@"%@=%@", keyString, valueString]];
    }
    NSString *queryString = [queryParts componentsJoinedByString:@"&"];
    NSString *existingURLString = [baseURL absoluteString];

    NSRange startOfQueryString = [existingURLString rangeOfString:@"?"];
    NSString *joinString = nil;

    if (startOfQueryString.location == NSNotFound)
    {
        joinString = @"?";
    }
    else
    {
        joinString = @"&";
    }

    NSString *urlString = [[existingURLString stringByAppendingString:joinString] stringByAppendingString:queryString];

    return [NSURL URLWithString:urlString];
}

#pragma mark - Prepare to make API call
- (void)prepareAPIRequest
{
    BOXAbstract();
}

- (void)startURLConnection
{
    [self.connection start];
}

#pragma mark - Process API call results
- (void)processResponseData:(NSData *)data
{
    BOXAbstract();
}

#pragma mark - callbacks
- (void)performCompletionCallback
{
    BOXAbstract();
}

#pragma mark - Thread keepalive

+ (NSThread *)globalAPIOperationNetworkThread
{
    static NSThread *boxAPIOperationNewtorkRequestThread = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        boxAPIOperationNewtorkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(globalAPIOperationNetworkThreadEntryPoint:) object:nil];
        boxAPIOperationNewtorkRequestThread.name = @"Box API Operation Thread";
        [boxAPIOperationNewtorkRequestThread start];
        BOXLog(@"%@ started", boxAPIOperationNewtorkRequestThread);
    });
    return boxAPIOperationNewtorkRequestThread;
}

+ (void)globalAPIOperationNetworkThreadEntryPoint:(id)sender
{
    // Run this thread forever
    while (YES)
    {
        // Create an autorelease pool around each iteration of the runloop
        // API call completion blocks are run on this runloop which may
        // create autoreleased objects.
        //
        // See Apple documentation on using autorelease pool blocks
        // https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmAutoreleasePools.html#//apple_ref/doc/uid/20000047-CJBFBEDI
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] run];
        }
    }
}

#pragma mark - NSOperation
- (BOOL)isReady
{
    return self.state == BoxAPIOperationStateReady && [super isReady];
}

- (BOOL)isExecuting
{
    return self.state == BoxAPIOperationStateExecuting;
}

- (BOOL)isFinished
{
    return self.state == BoxAPIOperationStateFinished;
}

- (void)start
{
    [[BoxAPIOperation APIOperationGlobalLock] lock];

    if ([self isReady])
    {
        // Set state = executing once we have the lock
        // BoxAPIQueueManagers check to ensure that operations are not executing when
        // they grab the lock and are adding dependencies.
        self.state = BoxAPIOperationStateExecuting;

        [self performSelector:@selector(executeOperation) onThread:[[self class] globalAPIOperationNetworkThread] withObject:nil waitUntilDone:NO];
    }
    else
    {
        BOXAssertFail(@"Operation was not ready but start was called");
    }

    [[BoxAPIOperation APIOperationGlobalLock] unlock];
}

- (void)executeOperation
{
    BOXLog(@"BoxAPIOperation %@ was started", self);
    if (![self isCancelled])
    {
        @synchronized(self.OAuth2Session)
        {
            [self prepareAPIRequest];
            self.OAuth2AccessToken = self.OAuth2Session.accessToken;
        }

        if (self.error == nil && ![self isCancelled])
        {
            self.connection = [[NSURLConnection alloc] initWithRequest:self.APIRequest delegate:self];
            BOXLog(@"Starting %@", self);
            [self startURLConnection];
        }
        else
        {
            // if an error has already occured, do not attempt to start the API call.
            // short circuit instead.
            [self finish];
        }
    }
    else
    {
        BOXLog(@"BoxAPIOperation %@ was cancelled -- short circuiting and not making API call", self);
        [self finish];
    }
}

- (void)cancel
{
    [self performSelector:@selector(cancelConnection) onThread:[[self class] globalAPIOperationNetworkThread] withObject:nil waitUntilDone:NO];
    [super cancel];
    BOXLog(@"BoxAPIOperation %@ was cancelled", self);
}

- (void)cancelConnection
{
    NSDictionary *errorInfo = nil;
    if (self.baseRequestURL)
    {
        errorInfo = [NSDictionary dictionaryWithObject:self.baseRequestURL forKey:NSURLErrorFailingURLErrorKey];
    }
    self.error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:errorInfo];

    if (self.connection)
    {
        [self.connection cancel];
        [self connection:self.connection didFailWithError:self.error];
    }
}

- (void)finish
{
    [self performCompletionCallback];
    self.connection = nil;
    self.state = BoxAPIOperationStateFinished;
    BOXLog(@"BoxAPIOperation %@ finished with state %d", self, self.state);
}

#pragma mark - NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.HTTPResponse = (NSHTTPURLResponse *)response;

    if (self.HTTPResponse.statusCode == 202 || self.HTTPResponse.statusCode < 200 || self.HTTPResponse.statusCode >= 300)
    {
        BoxSDKAPIError errorCode = BoxSDKAPIErrorUnknownStatusCode;
        switch (self.HTTPResponse.statusCode)
        {
            case BoxSDKAPIErrorAccepted:
                errorCode = BoxSDKAPIErrorAccepted;
                break;
            case BoxSDKAPIErrorBadRequest:
                errorCode = BoxSDKAPIErrorBadRequest;
                break;
            case BoxSDKAPIErrorUnauthorized:
                errorCode = BoxSDKAPIErrorUnauthorized;
                break;
            case BoxSDKAPIErrorForbidden:
                errorCode = BoxSDKAPIErrorForbidden;
                break;
            case BoxSDKAPIErrorNotFound:
                errorCode = BoxSDKAPIErrorNotFound;
                break;
            case BoxSDKAPIErrorMethodNotAllowed:
                errorCode = BoxSDKAPIErrorMethodNotAllowed;
                break;
            case BoxSDKAPIErrorConflict:
                errorCode = BoxSDKAPIErrorConflict;
                break;
            case BoxSDKAPIErrorPreconditionFailed:
                errorCode = BoxSDKAPIErrorPreconditionFailed;
                break;
            case BoxSDKAPIErrorRequestEntityTooLarge:
                errorCode = BoxSDKAPIErrorRequestEntityTooLarge;
                break;
            case BoxSDKAPIErrorPreconditionRequired:
                errorCode = BoxSDKAPIErrorPreconditionRequired;
                break;
            case BoxSDKAPIErrorTooManyRequests:
                errorCode = BoxSDKAPIErrorTooManyRequests;
                break;
            case BoxSDKAPIErrorInternalServerError:
                errorCode = BoxSDKAPIErrorInternalServerError;
                break;
            case BoxSDKAPIErrorInsufficientStorage:
                errorCode = BoxSDKAPIErrorInsufficientStorage;
                break;
            default:
                errorCode = BoxSDKAPIErrorUnknownStatusCode;
        }

        self.error = [[NSError alloc] initWithDomain:BoxSDKErrorDomain code:errorCode userInfo:nil];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    BOXLog(@"BoxAPIOperation %@ did fail with error %@", self, error);
    if (self.error == nil)
    {
        self.error = error;
    }
    [self finish];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    BOXLog(@"BoxAPIOperation %@ did finsh loading", self);
    [self processResponseData:self.responseData];
    [self finish];
}

#pragma mark - Lock
+ (NSRecursiveLock *)APIOperationGlobalLock
{
    static NSRecursiveLock *boxAPIOperationLock = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        boxAPIOperationLock = [[NSRecursiveLock alloc] init];
        boxAPIOperationLock.name = @"Box API Operation Lock";
    });

    return boxAPIOperationLock;
}

@end
