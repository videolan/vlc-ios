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

@implementation VLCCharge

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (dict != nil && self) {
        _creationDate = [NSDate dateWithTimeIntervalSince1970:[dict[@"created"] intValue]];
        _amount = [NSNumber numberWithInt:[dict[@"amount"] intValue] / 100];
        _currencyCode = [dict[@"currency"] uppercaseString];
        _receiptURL = [NSURL URLWithString:dict[@"receipt_url"]];
    }
    return self;
}

@end
