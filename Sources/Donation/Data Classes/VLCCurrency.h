/*****************************************************************************
 * VLCCurrency.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import <UIKit/UIKit.h>

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
@property (readonly, nullable) UIImage *symbolImage;
@property (readonly) int stripeMultiplier;

@property (readonly) float minimalAmount;
@property (readonly) float maximalAmount;

@property (readonly) NSArray <NSNumber *> *values;

@end

NS_ASSUME_NONNULL_END
