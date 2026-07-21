/*****************************************************************************
 * VLCRadioCountryService.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

@class VLCRadioCountry;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const VLCRadioCountriesDidUpdateNotification;

@interface VLCRadioCountryService : NSObject

@property (readonly) NSArray<VLCRadioCountry *> *allCountries;
@property (readonly) NSArray<VLCRadioCountry *> *visitedCountries;
@property (readonly) BOOL hasCachedCountries;
@property (readonly) BOOL discoveryFailed;

- (void)startCountryDiscoveryIfNeeded;
- (void)stopCountryDiscovery;
- (void)retryCountryDiscovery;

- (void)markCountryVisited:(VLCRadioCountry *)country;

@end

NS_ASSUME_NONNULL_END
