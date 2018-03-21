//
//  BoxFoldersResourceManager.m
//  BoxSDK
//
//  Created on 3/12/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxFoldersResourceManager.h"
#import "BoxFoldersRequestBuilder.h"
#import "BoxOAuth2Session.h"
#import "BoxSDKConstants.h"

NSString *const BoxAPIFolderIDRoot = @"0";
NSString *const BoxAPIFolderIDTrash = @"trash";

#define BOX_API_FOLDERS_RESOURCE              (@"folders")
#define BOX_API_FOLDERS_SUBRESOURCE_ITEMS     (@"items")
#define BOX_API_FOLDERS_SUBRESOURCE_COPY      (@"copy")
#define BOX_API_FOLDERS_SUBRESOURCE_TRASH     (@"trash")

@interface BoxFoldersResourceManager ()

- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary folderSuccessBlock:(BoxFolderBlock)success failureBlock:(BoxAPIJSONFailureBlock)failure mini:(BOOL)mini;

@end

@implementation BoxFoldersResourceManager

- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary folderSuccessBlock:(BoxFolderBlock)success failureBlock:(BoxAPIJSONFailureBlock)failure mini:(BOOL)mini
{
    BoxAPIJSONSuccessBlock JSONSuccessBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSONDictionary)
    {
        if (success != nil)
        {
            success([[BoxFolder alloc] initWithResponseJSON:JSONDictionary mini:mini]);
        }
    };

    return [self JSONOperationWithURL:URL HTTPMethod:HTTPMethod queryStringParameters:queryParameters bodyDictionary:bodyDictionary JSONSuccessBlock:JSONSuccessBlock failureBlock:failure];
}


- (BoxAPIJSONOperation *)folderInfoWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxFolderBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FOLDERS_RESOURCE
                                    ID:folderID
                           subresource:nil
                                 subID:nil];

    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodGET
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:nil
                                               folderSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];

    [self.queueManager enqueueOperation:operation];

    return operation;
}

- (BoxAPIJSONOperation *)createFolderWithRequestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxFolderBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FOLDERS_RESOURCE
                                    ID:nil
                           subresource:nil
                                 subID:nil];

    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodPOST
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:builder.bodyParameters
                                               folderSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];

    [self.queueManager enqueueOperation:operation];

    return operation;
}

- (BoxAPIJSONOperation *)folderItemsWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxCollectionBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FOLDERS_RESOURCE
                                    ID:folderID
                           subresource:BOX_API_FOLDERS_SUBRESOURCE_ITEMS
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

- (BoxAPIJSONOperation *)editFolderWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxFolderBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FOLDERS_RESOURCE
                                    ID:folderID
                           subresource:nil
                                 subID:nil];

    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodPUT
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:builder.bodyParameters
                                               folderSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];

    [self.queueManager enqueueOperation:operation];

    return operation;
}

- (BoxAPIJSONOperation *)deleteFolderWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxSuccessfulDeleteBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FOLDERS_RESOURCE
                                    ID:folderID
                           subresource:nil
                                 subID:nil];

    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodDELETE
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:nil
                                               deleteSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                        modelID:folderID];

    [self.queueManager enqueueOperation:operation];

    return operation;
}

- (BoxAPIJSONOperation *)copyFolderWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxFolderBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FOLDERS_RESOURCE
                                    ID:folderID
                           subresource:BOX_API_FOLDERS_SUBRESOURCE_COPY
                                 subID:nil];

    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodPOST
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:builder.bodyParameters
                                               folderSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];

    [self.queueManager enqueueOperation:operation];

    return operation;
}

- (BoxAPIJSONOperation *)folderInfoFromTrashWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxFolderBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FOLDERS_RESOURCE
                                    ID:folderID
                           subresource:BOX_API_FOLDERS_SUBRESOURCE_TRASH
                                 subID:nil];

    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodGET
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:nil
                                               folderSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];

    [self.queueManager enqueueOperation:operation];

    return operation;
}

- (BoxAPIJSONOperation *)restoreFolderFromTrashWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxFolderBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FOLDERS_RESOURCE
                                    ID:folderID
                           subresource:nil
                                 subID:nil];

    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodPOST
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:builder.bodyParameters
                                               folderSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];

    [self.queueManager enqueueOperation:operation];

    return operation;
}


- (BoxAPIJSONOperation *)deleteFolderFromTrashWithID:(NSString *)folderID requestBuilder:(BoxFoldersRequestBuilder *)builder success:(BoxSuccessfulDeleteBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FOLDERS_RESOURCE
                                    ID:folderID
                           subresource:BOX_API_FOLDERS_SUBRESOURCE_TRASH
                                 subID:nil];

    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodDELETE
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:nil
                                               deleteSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                        modelID:folderID];

    [self.queueManager enqueueOperation:operation];

    return operation;
}

@end
