/*****************************************************************************
 * VLCCharge.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCCharge : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@property (readonly) NSDate *creationDate;
@property (readonly) NSNumber *amount;
@property (readonly) NSString *currencyCode;
@property (readonly) NSURL *receiptURL;

@end

NS_ASSUME_NONNULL_END
