//
//  BoxCommentsResourceManager.m
//  BoxSDK
//
//  Created by Boxcomment on 11/21/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxCommentsResourceManager.h"
#import "BoxCommentsRequestBuilder.h"
#import "BoxOAuth2Session.h"
#import "BoxSDKConstants.h"

#define BOX_API_COMMENTS_RESOURCE              (@"comments")

@interface BoxCommentsResourceManager ()

- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary
                             commentSuccessBlock:(BoxCommentBlock)success failureBlock:(BoxAPIJSONFailureBlock)failure mini:(BOOL)mini;

@end

@implementation BoxCommentsResourceManager

- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary
                             commentSuccessBlock:(BoxCommentBlock)success failureBlock:(BoxAPIJSONFailureBlock)failure mini:(BOOL)mini
{
    BoxAPIJSONSuccessBlock JSONSuccessBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSONDictionary)
    {
        if (success != nil)
        {
            success([[BoxComment alloc] initWithResponseJSON:JSONDictionary mini:mini]);
        }
    };
    
    return [self JSONOperationWithURL:URL
                           HTTPMethod:HTTPMethod
                queryStringParameters:queryParameters
                       bodyDictionary:bodyDictionary
                     JSONSuccessBlock:JSONSuccessBlock
                         failureBlock:failure];
    
}

- (BoxAPIJSONOperation *)commentInfoWithID:(NSString *)commentID requestBuilder:(BoxCommentsRequestBuilder *)builder success:(BoxCommentBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_COMMENTS_RESOURCE
                                    ID:commentID
                           subresource:nil
                                 subID:nil];
    
    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodGET
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:nil
                                               commentSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];
    
    [self.queueManager enqueueOperation:operation];
    
    return operation;
}

- (BoxAPIJSONOperation *)createCommentWithRequestBuilder:(BoxCommentsRequestBuilder *)builder success:(BoxCommentBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_COMMENTS_RESOURCE
                                    ID:nil
                           subresource:nil
                                 subID:nil];
    
    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodPOST
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:builder.bodyParameters
                                               commentSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];
    
    [self.queueManager enqueueOperation:operation];
    
    return operation;
}

- (BoxAPIJSONOperation *)editCommentWithID:(NSString *)commentID requestBuilder:(BoxCommentsRequestBuilder *)builder success:(BoxCommentBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_COMMENTS_RESOURCE
                                    ID:commentID
                           subresource:nil
                                 subID:nil];
    
    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodPUT
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:builder.bodyParameters
                                               commentSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];
    
    [self.queueManager enqueueOperation:operation];
    
    return operation;
}

- (BoxAPIJSONOperation *)deleteCommentWithID:(NSString *)commentID requestBuilder:(BoxCommentsRequestBuilder *)builder success:(BoxSuccessfulDeleteBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_COMMENTS_RESOURCE
                                    ID:commentID
                           subresource:nil
                                 subID:nil];
    
    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodDELETE
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:nil
                                             deleteSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                        modelID:commentID];
    
    [self.queueManager enqueueOperation:operation];
    
    return operation;
}

@end
