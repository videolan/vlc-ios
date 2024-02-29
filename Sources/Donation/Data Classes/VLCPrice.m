/*****************************************************************************
 * VLCPrice.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPrice.h"
#import "VLCCurrency.h"

@implementation VLCPrice

- (instancetype)initWithDictionary:(NSDictionary *)dict forCurrency:(VLCCurrency *)currency
{
    self = [super init];
    if (self && dict != nil) {
        _id = dict[@"id"];
        NSDictionary *currencyOptions = dict[@"currency_options"];
        NSDictionary *option = currencyOptions[[currency.isoCode lowercaseString]];
        NSNumber *unitAmount = option[@"unit_amount"];
        if (unitAmount != (NSNumber *)[NSNull null]) {
            _amount = [NSNumber numberWithInt:[option[@"unit_amount"] intValue] / 100];
        } else {
            _amount = @(0.);
        }
        _recurring = [dict[@"type"] isEqualToString:@"recurring"];
    }
    return self;
}

@end
