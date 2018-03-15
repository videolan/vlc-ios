//
//  BoxAPIResourceManager.m
//  BoxSDK
//
//  Created on 3/12/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIResourceManager.h"

#import "BoxCollection.h"
#import "BoxSDKConstants.h"

@implementation BoxAPIResourceManager

@synthesize APIBaseURL = _APIBaseURL;
@synthesize APIVersion = _APIVersion;
@synthesize OAuth2Session = _OAuth2Session;
@synthesize queueManager = _queueManager;

- (id)initWithAPIBaseURL:(NSString *)baseURL OAuth2Session:(BoxOAuth2Session *)OAuth2Session queueManager:(BoxAPIQueueManager *)queueManager
{
    self = [super init];
    if (self != nil)
    {
        _APIVersion = BoxAPIVersion;
        _APIBaseURL = baseURL;
        _OAuth2Session = OAuth2Session;
        _queueManager = queueManager;
    }
    return self;
}

- (NSURL *)URLWithResource:(NSString *)resource ID:(NSString *)ID subresource:(NSString *)subresource subID:(NSString *)subID;
{
    NSString *formatString = @"/%@";
    if ([self.APIBaseURL hasSuffix:@"/"])
    {
        formatString = @"%@"; // do not append a trailing slash if the base url already has one
    }

    NSString *URLString = [self.APIBaseURL stringByAppendingFormat:formatString, self.APIVersion];

    if (resource != nil)
    {
        URLString = [URLString stringByAppendingFormat:@"/%@", resource];
        if (ID != nil)
        {
            URLString = [URLString stringByAppendingFormat:@"/%@", ID];
            if (subresource != nil)
            {
                URLString = [URLString stringByAppendingFormat:@"/%@", subresource];
                if (subID != nil)
                {
                    URLString = [URLString stringByAppendingFormat:@"/%@", subID];
                }
            }
        }
    }

    return [[NSURL alloc] initWithString:URLString];
}

- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary JSONSuccessBlock:(BoxAPIJSONSuccessBlock)successBlock failureBlock:(BoxAPIJSONFailureBlock)failureBlock
{
    BoxAPIJSONOperation *operation = [[BoxAPIJSONOperation alloc] initWithURL:URL HTTPMethod:HTTPMethod body:bodyDictionary queryParams:queryParameters OAuth2Session:self.OAuth2Session];

    // calling a nil block results in a crash, so only set the operation's success block if it is non-nil
    // BoxAPIJSONOperation initializes blocks to empty blocks
    if (successBlock != nil)
    {
        operation.success = successBlock;
    }
    if (failureBlock != nil)
    {
        operation.failure = failureBlock;
    }

    return operation;
}

- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary collectionSuccessBlock:(BoxCollectionBlock)successBlock failureBlock:(BoxAPIJSONFailureBlock)failureBlock
{
    BoxAPIJSONSuccessBlock JSONSuccessBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSONDictionary)
    {
        if (successBlock != nil)
        {
            BoxCollection *collection = [[BoxCollection alloc] initWithResponseJSON:JSONDictionary mini:YES];
            successBlock(collection);
        }
    };

    return [self JSONOperationWithURL:URL HTTPMethod:HTTPMethod queryStringParameters:queryParameters bodyDictionary:bodyDictionary JSONSuccessBlock:JSONSuccessBlock failureBlock:failureBlock];
}

- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary deleteSuccessBlock:(BoxSuccessfulDeleteBlock)successBlock failureBlock:(BoxAPIJSONFailureBlock)failureBlock modelID:(NSString *)modelID
{
    BoxAPIJSONSuccessBlock JSONSuccessBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSONDictionary)
    {
        if (successBlock != nil)
        {
            successBlock(modelID);
        }
    };

    return [self JSONOperationWithURL:URL HTTPMethod:HTTPMethod queryStringParameters:queryParameters bodyDictionary:bodyDictionary JSONSuccessBlock:JSONSuccessBlock failureBlock:failureBlock];
}

@end
