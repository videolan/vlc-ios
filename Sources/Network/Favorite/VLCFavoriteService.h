/*****************************************************************************
 * VLCFavoriteService.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCFavorite : NSObject

@property (readwrite, retain) NSString *userVisibleName;
@property (readwrite, retain) NSURL *url;

@end

@interface VLCFavoriteService : NSObject

@property (readonly) NSUInteger numberOfFavoritedServers;
- (NSString *)nameOfFavoritedServerAtIndex:(NSUInteger)index;

- (BOOL)isFavoriteURL:(NSURL *)url;

- (void)addFavorite:(VLCFavorite *)favorite;
- (void)removeFavorite:(VLCFavorite *)favorite;

@end

NS_ASSUME_NONNULL_END
