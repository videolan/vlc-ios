//
//  BoxSearchRequestBuilder.m
//  BoxSDK
//
//  Created on 11/21/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxSearchRequestBuilder.h"

NSString *const BoxAPISearchQueryParameter = @"query";

@implementation BoxSearchRequestBuilder

@synthesize query = _query;

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
        _query = nil;
    }

    return self;
}

- (id)initWithSearch:(NSString *)query queryStringParameters:(NSDictionary *)queryStringParameters
{
    NSMutableDictionary *qsp = [NSMutableDictionary dictionaryWithDictionary:queryStringParameters];
    if (query != nil)
    {
        [qsp setObject:query forKey:BoxAPISearchQueryParameter];
    }

    self = [self initWithQueryStringParameters:qsp];
    if (self != nil)
    {
        _query = query;
    }

    return self;
}

- (void)setQuery:(NSString *)query
{
    if (query != nil)
    {
        _query = query;
        [self.queryStringParameters setObject:query forKey:BoxAPISearchQueryParameter];
    }
    else
    {
        _query = nil;
        [self.queryStringParameters removeObjectForKey:BoxAPISearchQueryParameter];
    }
}

@end
