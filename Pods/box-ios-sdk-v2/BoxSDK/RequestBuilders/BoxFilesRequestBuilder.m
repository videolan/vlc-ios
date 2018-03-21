//
//  BoxFilesRequestBuilder.m
//  BoxSDK
//
//  Created on 3/22/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxFilesRequestBuilder.h"
#import "BoxSDKConstants.h"

#define MULTIPART_PARENT_ID (@"parent_id")

@implementation BoxFilesRequestBuilder

- (NSDictionary *)multipartBodyParameters
{
    NSMutableDictionary *multipartBody = [NSMutableDictionary dictionary];

    // The only parameters allowed in multipart form requests for files are parent ID, content created at,
    // and content modified at
    //
    // name should be included as part of the content disposition of the file blob
    [self setObjectIfNotNil:self.parentID forKey:MULTIPART_PARENT_ID inDictionary:multipartBody];
    [self setDateStringIfNotNil:self.contentCreatedAt forKey:BoxAPIObjectKeyContentCreatedAt inDictionary:multipartBody];
    [self setDateStringIfNotNil:self.contentModifiedAt forKey:BoxAPIObjectKeyContentModifiedAt inDictionary:multipartBody];

    return [NSDictionary dictionaryWithDictionary:multipartBody];
}

@end
