/*****************************************************************************
 * VLCSubscription.h
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

@interface VLCSubscription : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
@property (readonly) NSString *subscriptionid;
@property (readonly) NSString *subscriptionitemid;
@property (readonly) NSString *priceid;

@end

NS_ASSUME_NONNULL_END
