//
//  BoxFilesResourceManager.m
//  BoxSDK
//
//  Created on 3/22/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxFilesResourceManager.h"

#import "BoxFile.h"
#import "BoxFilesRequestBuilder.h"

#define BOX_API_FILES_RESOURCE              (@"files")
#define BOX_API_FILES_SUBRESOURCE_COPY      (@"copy")
#define BOX_API_FILES_SUBRESOURCE_CONTENT   (@"content")
#define BOX_API_FILES_SUBRESOURCE_THUMBNAIL (@"thumbnail.png")

#define BOX_API_MULTIPART_FILENAME_FIELD   (@"file")
#define BOX_API_MULTIPART_FILENAME_DEFAULT (@"upload")

#define BOX_THUMBNAIL_MIN_HEIGHT (@"min_height")
#define BOX_THUMBNAIL_MIN_WIDTH  (@"min_width")

@interface BoxFilesResourceManager ()

- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary fileSuccessBlock:(BoxFileBlock)success failureBlock:(BoxAPIJSONFailureBlock)failure mini:(BOOL)mini;

- (NSString *)nonEmptyFilename:(NSString *)filename;

@end

@implementation BoxFilesResourceManager

@synthesize uploadBaseURL = _uploadBaseURL;
@synthesize uploadAPIVersion = _uploadAPIVersion;

- (id)initWithAPIBaseURL:(NSString *)baseURL OAuth2Session:(BoxOAuth2Session *)OAuth2Session queueManager:(BoxAPIQueueManager *)queueManager
{
    self = [super initWithAPIBaseURL:baseURL OAuth2Session:OAuth2Session queueManager:queueManager];
    if (self != nil)
    {
        _uploadBaseURL = self.APIBaseURL;
        _uploadAPIVersion = self.APIVersion;
    }

    return self;
}

- (NSURL *)uploadURLWithResource:(NSString *)resource ID:(NSString *)ID subresource:(NSString *)subresource
{
    NSString *formatString = @"/%@";
    if ([self.uploadBaseURL hasSuffix:@"/"])
    {
        formatString = @"%@"; // do not append a trailing slash if the base url already has one
    }

    NSString *URLString = [self.uploadBaseURL stringByAppendingFormat:formatString, self.uploadAPIVersion];

    if (resource != nil)
    {
        URLString = [URLString stringByAppendingFormat:@"/%@", resource];
        if (ID != nil)
        {
            URLString = [URLString stringByAppendingFormat:@"/%@", ID];
            if (subresource != nil)
            {
                URLString = [URLString stringByAppendingFormat:@"/%@", subresource];
            }
        }
    }

    return [[NSURL alloc] initWithString:URLString];
}

- (NSString *)nonEmptyFilename:(NSString *)filename
{
    if ([filename length] == 0)
    {
        NSDate *now = [NSDate date];
        NSString *nowString = [NSDateFormatter localizedStringFromDate:now
                                                             dateStyle:NSDateFormatterShortStyle
                                                             timeStyle:NSDateFormatterShortStyle];
        filename = [BOX_API_MULTIPART_FILENAME_DEFAULT stringByAppendingFormat:@" %@", nowString];
    }
    return filename;
}

- (BoxAPIJSONOperation *)JSONOperationWithURL:(NSURL *)URL HTTPMethod:(BoxAPIHTTPMethod *)HTTPMethod queryStringParameters:(NSDictionary *)queryParameters bodyDictionary:(NSDictionary *)bodyDictionary fileSuccessBlock:(BoxFileBlock)success failureBlock:(BoxAPIJSONFailureBlock)failure mini:(BOOL)mini
{
    BoxAPIJSONSuccessBlock JSONSuccessBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSONDictionary)
    {
        if (success != nil)
        {
            success([[BoxFile alloc] initWithResponseJSON:JSONDictionary mini:mini]);
        }
    };

    return [self JSONOperationWithURL:URL
                           HTTPMethod:HTTPMethod
                queryStringParameters:queryParameters
                       bodyDictionary:bodyDictionary
                     JSONSuccessBlock:JSONSuccessBlock
                         failureBlock:failure];

}

- (BoxAPIJSONOperation *)fileInfoWithID:(NSString *)fileID requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FILES_RESOURCE
                                    ID:fileID
                           subresource:nil
                                 subID:nil];

    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodGET
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:nil
                                               fileSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];

    [self.queueManager enqueueOperation:operation];

    return operation;
}

- (BoxAPIJSONOperation *)editFileWithID:(NSString *)fileID requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FILES_RESOURCE
                                    ID:fileID
                           subresource:nil
                                 subID:nil];

    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodPUT
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:builder.bodyParameters
                                               fileSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];

    [self.queueManager enqueueOperation:operation];

    return operation;
}

- (BoxAPIJSONOperation *)copyFileWithID:(NSString *)fileID requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FILES_RESOURCE
                                    ID:fileID
                           subresource:BOX_API_FILES_SUBRESOURCE_COPY
                                 subID:nil];

    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodPOST
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:builder.bodyParameters
                                               fileSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                           mini:NO];

    [self.queueManager enqueueOperation:operation];

    return operation;
}

- (BoxAPIJSONOperation *)deleteFileWithID:(NSString *)fileID requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxSuccessfulDeleteBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FILES_RESOURCE
                                    ID:fileID
                           subresource:nil
                                 subID:nil];

    BoxAPIJSONOperation *operation = [self JSONOperationWithURL:URL
                                                     HTTPMethod:BoxAPIHTTPMethodDELETE
                                          queryStringParameters:builder.queryStringParameters
                                                 bodyDictionary:nil
                                             deleteSuccessBlock:successBlock
                                                   failureBlock:failureBlock
                                                        modelID:fileID];

    [self.queueManager enqueueOperation:operation];

    return operation;
}

#pragma mark - uploadFileWithData:

- (BoxAPIMultipartToJSONOperation *)uploadFileWithData:(NSData *)data requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock progress:(BoxAPIMultipartProgressBlock)progressBlock
{
    return [self uploadFileWithData:data MIMEType:nil requestBuilder:builder success:successBlock failure:failureBlock progress:progressBlock];
}

- (BoxAPIMultipartToJSONOperation *)uploadFileWithData:(NSData *)data MIMEType:(NSString *)MIMEType requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock progress:(BoxAPIMultipartProgressBlock)progressBlock
{
    NSURL *URL = [self uploadURLWithResource:BOX_API_FILES_RESOURCE
                                          ID:BOX_API_FILES_SUBRESOURCE_CONTENT
                                 subresource:nil];

    BoxAPIMultipartToJSONOperation *operation = [[BoxAPIMultipartToJSONOperation alloc] initWithURL:URL
                                                                                         HTTPMethod:BoxAPIHTTPMethodPOST
                                                                                               body:builder.multipartBodyParameters
                                                                                        queryParams:builder.queryStringParameters
                                                                                      OAuth2Session:self.OAuth2Session];

    NSString *filename = [self nonEmptyFilename:builder.name];
    [operation appendMultipartPieceWithData:data
                                  fieldName:BOX_API_MULTIPART_FILENAME_FIELD
                                   filename:filename
                                   MIMEType:MIMEType];

    BoxAPIJSONSuccessBlock JSONSuccessBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSONDictionary)
    {
        if (successBlock != nil)
        {
            BoxFile *file = [[BoxFile alloc] initWithResponseJSON:JSONDictionary mini:NO];
            successBlock(file);
        }
    };

    operation.success = JSONSuccessBlock;
    operation.failure = failureBlock;
    operation.progressBlock = progressBlock;

    [self.queueManager enqueueOperation:operation];

    return operation;
}

#pragma mark - uploadFileWithInputStream:

- (BoxAPIMultipartToJSONOperation *)uploadFileAtPath:(NSString *)path requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock progress:(BoxAPIMultipartProgressBlock)progressBlock
{
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:path];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    long long contentLength = [[fileAttributes objectForKey:NSFileSize] longLongValue];
    
    return [self uploadFileWithInputStream:inputStream contentLength:contentLength MIMEType:nil requestBuilder:builder success:successBlock failure:failureBlock progress:progressBlock];
}

- (BoxAPIMultipartToJSONOperation *)uploadFileWithInputStream:(NSInputStream *)inputStream contentLength:(unsigned long long)contentLength requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    return [self uploadFileWithInputStream:inputStream contentLength:contentLength MIMEType:nil requestBuilder:builder success:successBlock failure:failureBlock progress:nil];
}

- (BoxAPIMultipartToJSONOperation *)uploadFileWithInputStream:(NSInputStream *)inputStream contentLength:(unsigned long long)contentLength MIMEType:(NSString *)MIMEType requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock progress:(BoxAPIMultipartProgressBlock)progressBlock
{
    NSURL *URL = [self uploadURLWithResource:BOX_API_FILES_RESOURCE
                                          ID:BOX_API_FILES_SUBRESOURCE_CONTENT
                                 subresource:nil];

    BoxAPIMultipartToJSONOperation *operation = [[BoxAPIMultipartToJSONOperation alloc] initWithURL:URL
                                                                                         HTTPMethod:BoxAPIHTTPMethodPOST
                                                                                               body:builder.multipartBodyParameters
                                                                                        queryParams:builder.queryStringParameters
                                                                                      OAuth2Session:self.OAuth2Session];

    NSString *filename = [self nonEmptyFilename:builder.name];
    [operation appendMultipartPieceWithInputStream:inputStream
                                     contentLength:contentLength
                                         fieldName:BOX_API_MULTIPART_FILENAME_FIELD
                                          filename:filename
                                          MIMEType:MIMEType];

    BoxAPIJSONSuccessBlock JSONSuccessBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSONDictionary)
    {
        if (successBlock != nil)
        {
            BoxFile *file = [[BoxFile alloc] initWithResponseJSON:JSONDictionary mini:NO];
            successBlock(file);
        }
    };

    operation.success = JSONSuccessBlock;
    operation.failure = failureBlock;
    operation.progressBlock = progressBlock;

    [self.queueManager enqueueOperation:operation];

    return operation;
}

#pragma mark - overwriteFileWithID:data:
- (BoxAPIMultipartToJSONOperation *)overwriteFileWithID:(NSString *)fileID data:(NSData *)data requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    return [self overwriteFileWithID:fileID data:data MIMEType:nil requestBuilder:builder success:successBlock failure:failureBlock progress:nil];
}

- (BoxAPIMultipartToJSONOperation *)overwriteFileWithID:(NSString *)fileID data:(NSData *)data MIMEType:(NSString *)MIMEType requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock progress:(BoxAPIMultipartProgressBlock)progressBlock
{
    NSURL *URL = [self uploadURLWithResource:BOX_API_FILES_RESOURCE
                                          ID:fileID
                                 subresource:BOX_API_FILES_SUBRESOURCE_CONTENT];

    BoxAPIMultipartToJSONOperation *operation = [[BoxAPIMultipartToJSONOperation alloc] initWithURL:URL
                                                                                         HTTPMethod:BoxAPIHTTPMethodPOST
                                                                                               body:builder.multipartBodyParameters
                                                                                        queryParams:builder.queryStringParameters
                                                                                      OAuth2Session:self.OAuth2Session];

    NSString *filename = [self nonEmptyFilename:builder.name];
    [operation appendMultipartPieceWithData:data
                                  fieldName:BOX_API_MULTIPART_FILENAME_FIELD
                                   filename:filename
                                   MIMEType:MIMEType];

    BoxAPIJSONSuccessBlock JSONSuccessBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSONDictionary)
    {
        if (successBlock != nil)
        {
            BoxFile *file = [[BoxFile alloc] initWithResponseJSON:JSONDictionary mini:NO];
            successBlock(file);
        }
    };

    operation.success = JSONSuccessBlock;
    operation.failure = failureBlock;
    operation.progressBlock = progressBlock;

    [self.queueManager enqueueOperation:operation];

    return operation;
}

#pragma mark - overwriteFileWithID:inputStream:
- (BoxAPIMultipartToJSONOperation *)overwriteFileWithID:(NSString *)fileID inputStream:(NSInputStream *)inputStream contentLength:(unsigned long long)contentLength requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    return [self overwriteFileWithID:fileID inputStream:inputStream contentLength:contentLength MIMEType:nil requestBuilder:builder success:successBlock failure:failureBlock progress:nil];
}

- (BoxAPIMultipartToJSONOperation *)overwriteFileWithID:(NSString *)fileID inputStream:(NSInputStream *)inputStream contentLength:(unsigned long long)contentLength MIMEType:(NSString *)MIMEType requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock progress:(BoxAPIMultipartProgressBlock)progressBlock
{
    NSURL *URL = [self uploadURLWithResource:BOX_API_FILES_RESOURCE
                                          ID:fileID
                                 subresource:BOX_API_FILES_SUBRESOURCE_CONTENT];

    BoxAPIMultipartToJSONOperation *operation = [[BoxAPIMultipartToJSONOperation alloc] initWithURL:URL
                                                                                         HTTPMethod:BoxAPIHTTPMethodPOST
                                                                                               body:builder.multipartBodyParameters
                                                                                        queryParams:builder.queryStringParameters
                                                                                      OAuth2Session:self.OAuth2Session];

    NSString *filename = [self nonEmptyFilename:builder.name];
    [operation appendMultipartPieceWithInputStream:inputStream
                                     contentLength:contentLength
                                         fieldName:BOX_API_MULTIPART_FILENAME_FIELD
                                          filename:filename
                                          MIMEType:MIMEType];

    BoxAPIJSONSuccessBlock JSONSuccessBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSONDictionary)
    {
        if (successBlock != nil)
        {
            BoxFile *file = [[BoxFile alloc] initWithResponseJSON:JSONDictionary mini:NO];
            successBlock(file);
        }
    };

    operation.success = JSONSuccessBlock;
    operation.failure = failureBlock;
    operation.progressBlock = progressBlock;

    [self.queueManager enqueueOperation:operation];

    return operation;
}

#pragma mark - downloadFileWithID:


- (BoxAPIDataOperation *)downloadFileWithID:(NSString *)fileID outputStream:(NSOutputStream *)outputStream requestBuilder:(BoxFilesRequestBuilder *)builder success:(BoxDownloadSuccessBlock)successBlock failure:(BoxDownloadFailureBlock)failureBlock progress:(BoxAPIDataProgressBlock)progressBlock
{
    NSURL *URL = [self URLWithResource:BOX_API_FILES_RESOURCE
                                    ID:fileID
                           subresource:BOX_API_FILES_SUBRESOURCE_CONTENT
                                 subID:nil];

    BoxAPIDataOperation *operation = [[BoxAPIDataOperation alloc] initWithURL:URL
                                                                   HTTPMethod:BoxAPIHTTPMethodGET
                                                                         body:nil
                                                                  queryParams:builder.queryStringParameters
                                                                OAuth2Session:self.OAuth2Session];

    operation.outputStream = outputStream;

    operation.fileID = fileID;
    operation.successBlock = successBlock;
    operation.failureBlock = failureBlock;
    operation.progressBlock = progressBlock;

    [self.queueManager enqueueOperation:operation];

    return operation;
}

- (BoxAPIDataOperation *)downloadFile:(BoxFile *)file destinationPath:(NSString *)destinationPath success:(BoxDownloadSuccessBlock)successBlock failure:(BoxDownloadFailureBlock)failureBlock progress:(BoxAPIDataProgressBlock)progressBlock
{
    NSOutputStream *outputStream = [[NSOutputStream alloc] initToFileAtPath:destinationPath append:NO];
    return  [self downloadFileWithID:file.modelID outputStream:outputStream requestBuilder:nil success:successBlock failure:failureBlock progress:progressBlock];
}


- (BoxAPIDataOperation *)thumbnailForFileWithID:(NSString *)fileID outputStream:(NSOutputStream *)outputStream thumbnailSize:(BoxThumbnailSize)thumbnailSize success:(BoxDownloadSuccessBlock)successBlock failure:(BoxDownloadFailureBlock)failureBlock;
{
    NSURL *URL = [self URLWithResource:BOX_API_FILES_RESOURCE
                                    ID:fileID
                           subresource:BOX_API_FILES_SUBRESOURCE_THUMBNAIL
                                 subID:nil];

    NSDictionary *thumbnailQueryParameters = @{
        BOX_THUMBNAIL_MIN_HEIGHT : [NSNumber numberWithInt:thumbnailSize],
        BOX_THUMBNAIL_MIN_WIDTH : [NSNumber numberWithInt:thumbnailSize]
    };

    BoxAPIDataOperation *operation = [[BoxAPIDataOperation alloc] initWithURL:URL
                                                                   HTTPMethod:BoxAPIHTTPMethodGET
                                                                         body:nil
                                                                  queryParams:thumbnailQueryParameters
                                                                OAuth2Session:self.OAuth2Session];

    operation.outputStream = outputStream;

    operation.fileID = fileID;
    operation.successBlock = successBlock;
    operation.failureBlock = failureBlock;

    [self.queueManager enqueueOperation:operation];

    return operation;
}

#pragma mark - share

- (BoxAPIJSONOperation *)createSharedLinkForItem:(BoxItem *)item withBuilder:(BoxFilesRequestBuilder *)builder success:(BoxFileBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock
{
    return [self editFileWithID:item.modelID requestBuilder:builder success:successBlock failure:failureBlock];
}

@end
