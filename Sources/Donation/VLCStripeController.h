/*****************************************************************************
 * VLCStripeController.h
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

@class PKPayment;

NS_ASSUME_NONNULL_BEGIN

@protocol VLCStripeControllerDelegate <NSObject>

@required
- (void)stripeProcessingSucceeded;
- (void)stripeProcessingFailedWithError:(NSString *)errorMessage;

@end

@interface VLCStripeController : NSObject

@property (readwrite, weak) id<VLCStripeControllerDelegate> delegate;

- (void)processPayment:(PKPayment *)payment forAmount:(CGFloat)amount currency:(NSString *)currencyCode;
- (void)processPaymentWithCard:(NSString *)cardNumber cvv:(NSString *)cvv exprMonth:(NSString *)month exprYear:(NSString *)year forAmount:(CGFloat)amount currency:(NSString *)currencyCode;

@end

NS_ASSUME_NONNULL_END
