/*****************************************************************************
 * VLCFavoriteService.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFavoriteService.h"

@implementation VLCFavorite

@end

@implementation VLCFavoriteService

- (NSUInteger)numberOfFavoritedServers
{
    return 0;
}

- (NSString *)nameOfFavoritedServerAtIndex:(NSUInteger)index
{
    return @"";
}

- (void)addFavorite:(VLCFavorite *)favorite
{

}

- (void)removeFavorite:(VLCFavorite *)favorite
{

}

- (BOOL)isFavoriteURL:(NSURL *)url
{
    return NO;
}

@end
