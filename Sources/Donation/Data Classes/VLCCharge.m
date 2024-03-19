/*****************************************************************************
 * VLCCharge.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCharge.h"
#import "VLCCurrency.h"

@implementation VLCCharge

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (dict != nil && self) {
        _creationDate = [NSDate dateWithTimeIntervalSince1970:[dict[@"created"] intValue]];
        _amount = [NSNumber numberWithInt:[dict[@"amount"] intValue] / 100];
        _currency = [VLCCurrency currencyForIsoCode:dict[@"currency"]];
        NSString *urlString = dict[@"receipt_url"];
        if (urlString != nil && urlString != (NSString *)[NSNull null]) {
            _receiptURL = [NSURL URLWithString:urlString];
        }
        if (dict[@"receipt_number"] == (NSString *)[NSNull null]) {
            _receiptNumber = @"";
        } else {
            _receiptNumber = dict[@"receipt_number"];
        }
    }
    return self;
}

@end
