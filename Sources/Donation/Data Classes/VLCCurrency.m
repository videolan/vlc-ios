/*****************************************************************************
 * VLCCurrency.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCurrency.h"

@implementation VLCCurrency

+ (NSArray<VLCCurrency *> *)availableCurrencies
{
    return @[[[VLCCurrency alloc] initEUR],
             [[VLCCurrency alloc] initUSD],
             [[VLCCurrency alloc] initAUD],
             [[VLCCurrency alloc] initGBP],
             [[VLCCurrency alloc] initBRL],
             [[VLCCurrency alloc] initCAD],
             [[VLCCurrency alloc] initCHF],
             [[VLCCurrency alloc] initCNY],
             [[VLCCurrency alloc] initINR],
             [[VLCCurrency alloc] initJPY],
             [[VLCCurrency alloc] initKRW],
             [[VLCCurrency alloc] initPLN],
             [[VLCCurrency alloc] initSEK]];
}

+ (VLCCurrency *)currencyForIsoCode:(NSString *)isoCode
{
    NSArray *availableCurrencies = [VLCCurrency availableCurrencies];
    for (VLCCurrency *currency in availableCurrencies) {
        if ([[isoCode uppercaseString] isEqualToString:currency.isoCode]) {
            return currency;
        }
    }
    return nil;
}

- (NSString *)userReadableName
{
    return [[NSLocale currentLocale] displayNameForKey:NSLocaleCurrencyCode value:_isoCode];
}

- (instancetype)initEUR
{
    self = [super init];

    if (self) {
        _isoCode = @"EUR";
        _values = @[@(5), @(10), @(20), @(30), @(50), @(100)];
        _localCurrencySymbol = @"€";
        _supportsPayPal = YES;
        _supportsSEPA = YES;
        _stripeMultiplier = 100;
    }

    return self;
}

- (instancetype)initUSD
{
    self = [super init];

    if (self) {
        _isoCode = @"USD";
        _values = @[@(5), @(10), @(20), @(30), @(50), @(100)];
        _localCurrencySymbol = @"$";
        _supportsPayPal = YES;
        _supportsSEPA = NO;
        _stripeMultiplier = 100;
    }

    return self;
}

- (instancetype)initAUD
{
    self = [super init];

    if (self) {
        _isoCode = @"AUD";
        _values = @[@(8), @(15), @(30), @(50), @(75), @(150)];
        _localCurrencySymbol = @"$";
        _supportsPayPal = YES;
        _supportsSEPA = NO;
        _stripeMultiplier = 100;
    }

    return self;
}

- (instancetype)initGBP
{
    self = [super init];

    if (self) {
        _isoCode = @"GBP";
        _values = @[@(5), @(10), @(20), @(30), @(50), @(100)];
        _localCurrencySymbol = @"£";
        _supportsPayPal = YES;
        _supportsSEPA = NO;
        _stripeMultiplier = 100;
    }

    return self;
}

- (instancetype)initBRL
{
    self = [super init];

    if (self) {
        _isoCode = @"BRL";
        _values = @[@(20), @(50), @(100), @(125), @(250), @(500)];
        _localCurrencySymbol = @"R$";
        _supportsPayPal = YES;
        _supportsSEPA = NO;
        _stripeMultiplier = 100;
    }

    return self;
}

- (instancetype)initCAD
{
    self = [super init];

    if (self) {
        _isoCode = @"CAD";
        _values = @[@(7), @(15), @(30), @(40), @(70), @(140)];
        _localCurrencySymbol = @"$";
        _supportsPayPal = YES;
        _supportsSEPA = NO;
        _stripeMultiplier = 100;
    }

    return self;
}

- (instancetype)initCNY
{
    self = [super init];

    if (self) {
        _isoCode = @"CNY";
        _values = @[@(30), @(60), @(125), @(200), @(300), @(600)];
        _localCurrencySymbol = @"CN¥";
        _supportsPayPal = NO;
        _supportsSEPA = NO;
        _stripeMultiplier = 100;
    }

    return self;
}

- (instancetype)initINR
{
    self = [super init];

    if (self) {
        _isoCode = @"INR";
        _values = @[@(300), @(750), @(1500), @(2000), @(4000), @(8000)];
        _localCurrencySymbol = @"₹";
        _supportsPayPal = NO;
        _supportsSEPA = NO;
        _stripeMultiplier = 100;
    }

    return self;
}

- (instancetype)initJPY
{
    self = [super init];

    if (self) {
        _isoCode = @"JPY";
        _values = @[@(500), @(1000), @(2000), @(3000), @(5000), @(10000)];
        _localCurrencySymbol = @"¥";
        _supportsPayPal = YES;
        _supportsSEPA = NO;
        _stripeMultiplier = 1;
    }

    return self;
}

- (instancetype)initKRW
{
    self = [super init];

    if (self) {
        _isoCode = @"KRW";
        _values = @[@(5000), @(10000), @(20000), @(30000), @(50000), @(100000)];
        _localCurrencySymbol = @"₩";
        _supportsPayPal = NO;
        _supportsSEPA = NO;
        _stripeMultiplier = 1;
    }

    return self;
}

- (instancetype)initPLN
{
    self = [super init];

    if (self) {
        _isoCode = @"PLN";
        _values = @[@(20), @(40), @(80), @(125), @(250), @(500)];
        _localCurrencySymbol = @"zł";
        _supportsPayPal = YES;
        _supportsSEPA = YES;
        _stripeMultiplier = 100;
    }

    return self;
}

- (instancetype)initSEK
{
    self = [super init];

    if (self) {
        _isoCode = @"SEK";
        _values = @[@(50), @(100), @(200), @(300), @(500), @(1000)];
        _localCurrencySymbol = @"kr‎";
        _supportsPayPal = YES;
        _supportsSEPA = YES;
        _stripeMultiplier = 100;
    }

    return self;
}

- (instancetype)initCHF
{
    self = [super init];

    if (self) {
        _isoCode = @"CHF";
        _values = @[@(5), @(10), @(20), @(30), @(50), @(100)];
        _localCurrencySymbol = @"CHF";
        _supportsPayPal = YES;
        _supportsSEPA = YES;
        _stripeMultiplier = 100;
    }

    return self;
}

@end
