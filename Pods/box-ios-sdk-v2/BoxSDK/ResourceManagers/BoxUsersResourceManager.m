//
//  BoxUsersResourceManager.m
//  BoxSDK
//
//  Created on 8/15/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxUsersResourceManager.h"
#import "BoxUsersRequestBuilder.h"
#import "BoxOAuth2Session.h"
#import "BoxSDKConstants.h"

NSString *const BoxAPIUserIDMe = @"me";

#define BOX_API_USERS_RESOURCE              (@"users")

@interface BoxUsersResourceManager ()

- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary
    userSuccessBlock:(BoxUserBlock)success failureBlock:(BoxAPIJSONFailureBlock)failure mini:(BOOL)mini;

@end

@implementation BoxUsersResourceManager

- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary
    userSuccessBlock:(BoxUserBlock)success failureBlock:(BoxAPIJSONFailureBlock)failure mini:(BOOL)mini
{
    BoxAPIJSONSuccessBlock JSONSuccessBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSONDictionary)
    {
        if (success != nil)
        {
            success([[BoxUser alloc] initWithResponseJSON:JSONDictionary mini:mini]);
        }
    };
    
    return [self JSONOperationWithURL:URL
                           HTTPMethod:HTTPMethod
                queryStringParameters:queryParameters
                       bodyDictionary:bodyDictionary
                     JSONSuccessBlock:JSONSuccessBlock
                         failureBlock:failure];
    
}

- (BoxAPIJSONOperation *)userInfoWithID:(NSString *)userID requestBuilder:(BoxUsersRequestBuilder *)builder success:(BoxUserBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{   
    NSURL *URL = [self URLWithResource:BOX_API_USERS_RESOURCE
                                    ID:userID
                           subresource:nil
                                 subID:nil];
    
    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodGET
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:nil
                                               userSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];
    
    [self.queueManager enqueueOperation:operation];
    
    return operation;
}

- (BoxAPIJSONOperation *)userInfos:(BoxUsersRequestBuilder *)builder success:(BoxCollectionBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_USERS_RESOURCE
                                    ID:nil
                           subresource:nil
                                 subID:nil];
    
    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodGET
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:nil
                                         collectionSuccessBlock:successBlock
                                                   failureBlock:failureBlock];
    
    [self.queueManager enqueueOperation:operation];
    
    return operation;
}

- (BoxAPIJSONOperation *)createUserWithRequestBuilder:(BoxUsersRequestBuilder *)builder success:(BoxUserBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{  
    NSURL *URL = [self URLWithResource:BOX_API_USERS_RESOURCE
                                    ID:nil
                           subresource:nil
                                 subID:nil];
    
    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodPOST
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:builder.bodyParameters
                                               userSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];
    
    [self.queueManager enqueueOperation:operation];
    
    return operation;
}

- (BoxAPIJSONOperation *)editUserWithID:(NSString *)userID requestBuilder:(BoxUsersRequestBuilder *)builder success:(BoxUserBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_USERS_RESOURCE
                                    ID:userID
                           subresource:nil
                                 subID:nil];
    
    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodPUT
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:builder.bodyParameters
                                               userSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];
    
    [self.queueManager enqueueOperation:operation];
    
    return operation;
}

- (BoxAPIJSONOperation *)deleteUserWithID:(NSString *)userID requestBuilder:(BoxUsersRequestBuilder *)builder success:(BoxSuccessfulDeleteBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_USERS_RESOURCE
                                    ID:userID
                           subresource:nil
                                 subID:nil];
    
    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodDELETE
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:nil
                                             deleteSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                        modelID:userID];
    
    [self.queueManager enqueueOperation:operation];
    
    return operation;
}

@end
