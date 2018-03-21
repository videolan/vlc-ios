//
//  BoxAPIRequestBuilder.m
//  BoxSDK
//
//  Created on 3/12/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIRequestBuilder.h"

#import "BoxISO8601DateFormatter.h"
#import "BoxLog.h"

NSString *const BoxAPIQueryStringValueTrue = @"true";
NSString *const BoxAPIQueryStringValueFalse = @"false";

@implementation BoxAPIRequestBuilder

@synthesize queryStringParameters = _queryStringParameters;

- (id)init
{
    return [self initWithQueryStringParameters:nil];
}

- (id)initWithQueryStringParameters:(NSDictionary *)queryStringParameters
{
    self = [super init];
    if (self != nil)
    {
        _queryStringParameters = [NSMutableDictionary dictionaryWithDictionary:queryStringParameters];
    }
    return self;
}

- (NSDictionary *)bodyParameters
{
    BOXAbstract();
    return nil;
}

-(NSString *)ISO8601StringWithDate:(NSDate *)date
{
    static BoxISO8601DateFormatter *dateFormatter;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        dateFormatter = [[BoxISO8601DateFormatter alloc] init];
        dateFormatter.parsesStrictly = YES;
        dateFormatter.format = BoxISO8601DateFormatCalendar;
        dateFormatter.includeTime = YES;
        dateFormatter.defaultTimeZone = [[NSTimeZone alloc] initWithName:@"UTC"];
    });

    return [dateFormatter stringFromDate:date];
}

- (void)setObjectIfNotNil:(id)object forKey:(id<NSCopying>)key inDictionary:(NSMutableDictionary *)dictionary
{
    if (object != nil)
    {
        [dictionary setObject:object forKey:key];
    }
}

- (void)setDateStringIfNotNil:(NSDate *)date forKey:(id<NSCopying>)key inDictionary:(NSMutableDictionary *)dictionary;
{
    if (date != nil)
    {
        [dictionary setObject:[self ISO8601StringWithDate:date] forKey:key];
    }
}

@end
