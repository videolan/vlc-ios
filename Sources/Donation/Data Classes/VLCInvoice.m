/*****************************************************************************
 * VLCInvoice.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCInvoice.h"
#import "VLCCurrency.h"

@implementation VLCInvoice

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (dict != nil && self) {
        _creationDate = [NSDate dateWithTimeIntervalSince1970:[dict[@"created"] intValue]];
        _amount = [NSNumber numberWithInt:[dict[@"amount_paid"] intValue] / 100];
        _currency = [VLCCurrency currencyForIsoCode:dict[@"currency"]];
        NSString *urlString = dict[@"hosted_invoice_url"];
        if (urlString != nil) {
            _hostedInvoiceURL = [NSURL URLWithString:urlString];
        }
        if (dict[@"number"] == (NSString *)[NSNull null]) {
            _invoiceNumber = @"";
        } else {
            _invoiceNumber = dict[@"number"];
        }
    }
    return self;
}

@end
