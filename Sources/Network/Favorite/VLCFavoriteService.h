/*****************************************************************************
 * VLCFavoriteService.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
@class VLCNetworkServerLoginInformation;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const VLCFavoriteGroupRadio;

@interface VLCFavorite : NSObject

@property (readwrite, retain) NSString *userVisibleName;
@property (readwrite, retain) NSURL *url;
@property (readwrite, retain, nullable) NSString *groupName;
@property (readwrite, retain, nullable) NSURL *artworkURL;
@property (readwrite) BOOL playable;
@property (readonly) NSString *protocolIdentifier;
@property (readonly, nullable) NSString *groupIdentifier;
@property (readonly, nullable) VLCNetworkServerLoginInformation *loginInformation;

@end

@interface VLCFavoriteService : NSObject

@property (readonly) NSInteger numberOfFavoritedServers;
- (NSInteger)numberOfFavoritesOfServerAtIndex:(NSInteger)index;
- (nullable VLCFavorite *)favoriteOfServerWithIndex:(NSInteger)serverIndex atIndex:(NSInteger)favoriteIndex;

- (NSString *)nameOfFavoritedServerAtIndex:(NSInteger)index;
- (void)setName:(NSString *)name ofFavoritedServerAtIndex:(NSInteger)index;

- (NSArray<VLCFavorite *> *)favoritesInGroupWithIdentifier:(NSString *)identifier;

- (BOOL)isFavoriteURL:(NSURL *)url;

- (void)addFavorite:(VLCFavorite *)favorite;
- (void)removeFavorite:(VLCFavorite *)favorite;
- (void)removeFavoriteOfServerWithIndex:(NSInteger)serverIndex atIndex:(NSInteger)favoriteIndex;

- (void)storeContentSynchronously;

@end

NS_ASSUME_NONNULL_END
