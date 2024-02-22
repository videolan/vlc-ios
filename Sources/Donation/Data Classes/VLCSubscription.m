/*****************************************************************************
 * VLCSubscription.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSubscription.h"

@implementation VLCSubscription

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self && dict != nil) {
        _subscriptionid = dict[@"id"];
        NSDictionary *items = dict[@"items"];
        NSArray *data = items[@"data"];
        NSDictionary *subscriptionItem = data.firstObject;
        _subscriptionitemid = subscriptionItem[@"id"];
        NSDictionary *price = subscriptionItem[@"price"];
        _priceid = price[@"id"];
    }
    return self;
}

@end
