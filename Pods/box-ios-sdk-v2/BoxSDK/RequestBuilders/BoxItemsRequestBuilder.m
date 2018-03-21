//
//  BoxItemsRequestBuilder.m
//  BoxSDK
//
//  Created on 3/28/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxItemsRequestBuilder.h"

#import "BoxSDKConstants.h"
#import "BoxSharedObjectBuilder.h"

@implementation BoxItemsRequestBuilder

@synthesize name = _name;
@synthesize description = _description;
@synthesize contentCreatedAt = _contentCreatedAt;
@synthesize contentModifiedAt = _contentModifiedAt;
@synthesize parentID = _parentID;
@synthesize sharedLink = _sharedLink;

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
        _name = nil;
        _description = nil;
        _contentCreatedAt = nil;
        _contentModifiedAt = nil;
        _parentID = nil;
        _sharedLink = nil;
    }

    return self;
}

- (NSDictionary *)bodyParameters
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (self.parentID != nil)
    {
        [dictionary setObject:@{ BoxAPIObjectKeyID : self.parentID, } forKey:BoxAPIObjectKeyParent];
    }

    [self setObjectIfNotNil:self.name forKey:BoxAPIObjectKeyName inDictionary:dictionary];
    [self setObjectIfNotNil:self.description forKey:BoxAPIObjectKeyDescription inDictionary:dictionary];

    [self setDateStringIfNotNil:self.contentCreatedAt forKey:BoxAPIObjectKeyContentCreatedAt inDictionary:dictionary];
    [self setDateStringIfNotNil:self.contentModifiedAt forKey:BoxAPIObjectKeyContentModifiedAt inDictionary:dictionary];

    [self setObjectIfNotNil:[self.sharedLink bodyParameters] forKey:BoxAPIObjectKeySharedLink inDictionary:dictionary];

    return [NSDictionary dictionaryWithDictionary:dictionary];
}

@end
