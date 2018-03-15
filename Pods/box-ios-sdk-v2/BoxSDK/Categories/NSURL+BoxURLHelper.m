//
//  NSURL+BoxURLHelper.m
//  BoxSDK
//
//  Created on 2/25/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxLog.h"
#import "NSURL+BoxURLHelper.h"

@implementation NSURL (BoxURLHelper)

- (NSDictionary *)box_queryDictionary
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSArray *keyValuePairs = [self.query componentsSeparatedByString:@"&"];
    NSArray *keyValuePairComponents = nil;

    for (NSString *keyValuePair in keyValuePairs)
    {
        keyValuePairComponents = [keyValuePair componentsSeparatedByString:@"="];
        BOXAssert(keyValuePairComponents.count == 2, @"Inconsistent information in keyValuePair=%@", keyValuePair);
        [params setValue:[keyValuePairComponents objectAtIndex:1]
                  forKey:[keyValuePairComponents objectAtIndex:0]];
    }

    return [NSDictionary dictionaryWithDictionary:params];
}

@end
