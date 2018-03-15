//
//  BoxFoldersRequestBuilder.m
//  BoxSDK
//
//  Created on 3/12/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxFoldersRequestBuilder.h"

#import "BoxLog.h"
#import "BoxSDKConstants.h"

BoxAPIFolderUploadEmailAccess *const BoxAPIFolderUploadEmailAccessCollaborators = @"collaborators";
BoxAPIFolderUploadEmailAccess *const BoxAPIFolderUploadEmailAccessOpen = @"open";
BoxAPIFolderUploadEmailAccess *const BoxAPIFolderUploadEmailAccessDisable = @"disabled";

NSString *const BoxAPIFolderRecursiveQueryParameter = @"recursive";

// Use an instance of NSNull because nil cannot be inserted into a collection and
// we want to ensure that the value of folder_upload_email is JSON encoded as
// null
#define FOLDER_REQUEST_CONFIG_DICTIONARY @{\
    @"folder_upload_email" : @{\
        BoxAPIFolderUploadEmailAccessDisable : [NSNull null],\
        BoxAPIFolderUploadEmailAccessCollaborators : @{ @"access" : BoxAPIFolderUploadEmailAccessCollaborators },\
        BoxAPIFolderUploadEmailAccessOpen : @{ @"access" : BoxAPIFolderUploadEmailAccessOpen },\
    },\
};

@interface BoxFoldersRequestBuilder ()

@property (nonatomic, readonly, strong) NSDictionary *JSONLookup;

@end

@implementation BoxFoldersRequestBuilder

@synthesize JSONLookup = _JSONLookup;

@synthesize folderUploadEmailAccess = _folderUploadEmailAccess;

static dispatch_once_t pred;
static NSDictionary *JSONStructures;

- (id)init
{
    self = [self initWithQueryStringParameters:nil];

    return self;
}

- (id)initWithQueryStringParameters:(NSDictionary *)queryStringParameters
{
    self = [super initWithQueryStringParameters:queryStringParameters];
    if (self != nil)
    {
        _folderUploadEmailAccess = nil;

        dispatch_once(&pred, ^{
            JSONStructures = FOLDER_REQUEST_CONFIG_DICTIONARY;
        });

        _JSONLookup = JSONStructures;
    }

    return self;
}

- (id)initWithRecursiveKey:(BOOL)recursive
{
    NSDictionary * queryParameters = nil;

    if (recursive)
    {
        queryParameters = @{BoxAPIFolderRecursiveQueryParameter : BoxAPIQueryStringValueTrue};
    }
    else
    {
        queryParameters = @{BoxAPIFolderRecursiveQueryParameter : BoxAPIQueryStringValueFalse};
    }

    self = [self initWithQueryStringParameters:queryParameters];

    return self;
}

- (NSDictionary *)bodyParameters
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super bodyParameters]];

    if (self.folderUploadEmailAccess != nil)
    {
        id uploadFolderEmailJSONConfiguration = [self.JSONLookup objectForKey:BoxAPIObjectKeyFolderUploadEmail];
        id JSONDictionaryForValue = [uploadFolderEmailJSONConfiguration objectForKey:self.folderUploadEmailAccess];

        BOXAssert(JSONDictionaryForValue != nil, @"Invalid value for folderUploadEmailAccess");

        [dictionary setObject:JSONDictionaryForValue forKey:BoxAPIObjectKeyFolderUploadEmail];
    }


    return [NSDictionary dictionaryWithDictionary:dictionary];
}

@end
