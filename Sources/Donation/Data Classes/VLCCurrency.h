/*****************************************************************************
 * VLCCurrency.h
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

@interface VLCCurrency : NSObject

+ (NSArray <VLCCurrency *> *)availableCurrencies;
+ (nullable VLCCurrency *)currencyForIsoCode:(NSString *)isoCode;

- (instancetype)initEUR;

@property (readonly) NSString *isoCode;
@property (readonly) NSString *userReadableName;
@property (readonly) BOOL supportsPayPal;
@property (readonly) BOOL supportsSEPA;
@property (readonly) NSString *localCurrencySymbol;
@property (readonly) int stripeMultiplier;

@property (readonly) NSArray <NSNumber *> *values;

@end

NS_ASSUME_NONNULL_END
