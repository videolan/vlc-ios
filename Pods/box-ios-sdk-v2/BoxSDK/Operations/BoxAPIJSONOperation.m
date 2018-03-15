//
//  BoxAPIJSONOperation.m
//  BoxSDK
//
//  Created on 2/26/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIJSONOperation.h"
#import "BoxSDKErrors.h"

#define BOX_API_CONTENT_TYPE_JSON  (@"application/json")

@implementation BoxAPIJSONOperation

@synthesize success = _success;
@synthesize failure = _failure;
@synthesize responseJSON = _responseJSON;

- (id)copyWithZone:(NSZone *)zone
{
    NSURL *URLCopy = [self.baseRequestURL copy];
    NSDictionary *bodyCopy = [self.body copy];
    NSDictionary *queryStringParametersCopy = [self.queryStringParameters copy];
    
    BoxAPIJSONOperation *operationCopy = [[BoxAPIJSONOperation allocWithZone:zone] initWithURL:URLCopy HTTPMethod:self.HTTPMethod body:bodyCopy queryParams:queryStringParametersCopy OAuth2Session:self.OAuth2Session];
    operationCopy.success = [self.success copy];
    operationCopy.failure = [self.failure copy];
    operationCopy.timesReenqueued = self.timesReenqueued;
    
    return operationCopy;
}

- (id)initWithURL:(NSURL *)URL HTTPMethod:(NSString *)HTTPMethod body:(NSDictionary *)body queryParams:(NSDictionary *)queryParams OAuth2Session:(BoxOAuth2Session *)OAuth2Session
{
    self = [super initWithURL:URL HTTPMethod:HTTPMethod body:body queryParams:queryParams OAuth2Session:OAuth2Session];
    
    if (self != nil)
    {
        // initialize all blocks to empty blocks so they can be called without crashing
        // nil blocks cannot be called.
        _success = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSONDictionary){};
        _failure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSDictionary *JSONDictionary){};
        
        _responseJSON = nil;
    }
    
    return self;
}

- (void)prepareAPIRequest
{
    [super prepareAPIRequest];
    if ([self.HTTPMethod isEqualToString:BoxAPIHTTPMethodPOST] || [self.HTTPMethod isEqualToString:BoxAPIHTTPMethodPUT])
    {
        [self.APIRequest addValue:BOX_API_CONTENT_TYPE_JSON forHTTPHeaderField:BoxAPIHTTPHeaderContentType];
    }
}

- (NSData *)encodeBody:(NSDictionary *)bodyDictionary
{
    // encode the body dictionary as JSON
    if (bodyDictionary == nil)
    {
        return nil;
    }
    
    NSError *JSONEncodeError = nil;
    NSData *JSONEncodedBody = [NSJSONSerialization dataWithJSONObject:bodyDictionary options:0 error:&JSONEncodeError];
    if (self.error == nil && JSONEncodeError != nil)
    {
        NSDictionary *userInfo = @{
        NSUnderlyingErrorKey : JSONEncodeError,
        };
        self.error = [[NSError alloc] initWithDomain:BoxSDKErrorDomain code:BoxSDKJSONErrorEncodeFailed userInfo:userInfo];
        
        // return dummy JSON body
        return [NSData data];
    }
    
    return JSONEncodedBody;
}

- (void)processResponseData:(NSData *)data
{
    if (self.HTTPResponse.statusCode == 204) // 204 No Content has no body, so don't decode it
    {
        self.responseJSON = nil;
        return;
    }
    
    NSError *JSONError = nil;
    id decodedJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
    
    if (JSONError != nil)
    {
        if (self.error == nil) {
            NSDictionary *userInfo = @{
            NSUnderlyingErrorKey : JSONError,
            };
            self.error = [[NSError alloc] initWithDomain:BoxSDKErrorDomain code:BoxSDKJSONErrorDecodeFailed userInfo:userInfo];
        }
    }
    else if ([decodedJSON isKindOfClass:[NSDictionary class]] == NO)
    {
        NSDictionary *userInfo = @{
        BoxJSONErrorResponseKey : decodedJSON,
        };
        self.error = [[NSError alloc] initWithDomain:BoxSDKErrorDomain code:BoxSDKJSONErrorUnexpectedType userInfo:userInfo];
    }
    else if (self.error != nil)
    {
        // if this operation has already encountered an error, include the decoded JSON in the error info
        NSDictionary *userInfo = @{
        BoxJSONErrorResponseKey : decodedJSON,
        };
        self.error = [[NSError alloc] initWithDomain:BoxSDKErrorDomain code:self.error.code userInfo:userInfo];
    }
    else
    {
        self.responseJSON = (NSDictionary *)decodedJSON;
    }
}

- (void)performCompletionCallback
{
    if (self.error == nil)
    {
        if (self.success)
        {
            self.success(self.APIRequest, self.HTTPResponse, self.responseJSON);
        }
    }
    else
    {
        if (self.failure)
        {
            self.failure(self.APIRequest, self.HTTPResponse, self.error, self.responseJSON);
        }
    }
}

@end
