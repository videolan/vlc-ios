/*****************************************************************************
 * VLCRadioService.h
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
@class VLCFavorite;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const VLCRadioCountriesDidUpdateNotification;
FOUNDATION_EXPORT NSString *const VLCRadioRecentStreamsDidChangeNotification;

@interface VLCRadioService : NSObject

@property (readonly) NSArray<VLCRadioCountry *> *allCountries;
@property (readonly) NSArray<VLCRadioCountry *> *visitedCountries;
@property (readonly) NSArray<VLCFavorite *> *recentStreams;
@property (readonly) BOOL hasCachedCountries;
@property (readonly) BOOL discoveryFailed;

- (void)startCountryDiscoveryIfNeeded;
- (void)stopCountryDiscovery;
- (void)retryCountryDiscovery;

- (void)markCountryVisited:(VLCRadioCountry *)country;

- (void)markStreamPlayed:(VLCFavorite *)stream;
- (void)removeRecentStream:(VLCFavorite *)stream;
- (nullable VLCFavorite *)recentStreamForURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
