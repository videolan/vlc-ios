//
//  BoxModel.m
//  BoxSDK
//
//  Created on 3/14/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxModel.h"

#import "BoxLog.h"
#import "BoxSDKConstants.h"
#import "BoxISO8601DateFormatter.h"

@implementation BoxModel

@synthesize rawResponseJSON = _rawResponseJSON;
@synthesize mini = _mini;

- (id)initWithResponseJSON:(NSDictionary *)responseJSON mini:(BOOL)mini
{
    self = [super init];
    if (self != nil)
    {
        _rawResponseJSON = responseJSON;
        _mini = mini;
    }

    return self;
}

- (NSDate *)dateWithISO8601String:(NSString *)timestamp
{
    static BoxISO8601DateFormatter *dateFormatter;
    static dispatch_once_t pred;

    if (dateFormatter == nil)
    {
        // use one date formatter for all models
        dispatch_once(&pred, ^{
            dateFormatter = [[BoxISO8601DateFormatter alloc] init];
            dateFormatter.parsesStrictly = YES;
        });
    }

    NSDate *returnDate = nil;
    if (timestamp != nil)
    {
        returnDate = [dateFormatter dateFromString:timestamp];
    }

    return returnDate;
}

- (NSComparisonResult)compare:(BoxModel *)model usingComparator:(NSComparator)comparator
{
    return comparator(self, model);
}

- (NSString *)type
{
    id type = [self.rawResponseJSON objectForKey:BoxAPIObjectKeyType];
    if (![type isKindOfClass:[NSString class]])
    {
        BOXAssertFail(@"type should be a string");
        return nil;
    }
    return (NSString *)type;
}

- (NSString *)modelID
{
    id ID = [self.rawResponseJSON objectForKey:BoxAPIObjectKeyID];
    if (![ID isKindOfClass:[NSString class]])
    {
        BOXAssertFail(@"id should be a string");
        return nil;
    }
    return (NSString *)ID;
}

@end
