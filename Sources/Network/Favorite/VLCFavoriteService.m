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

NSString *VLCFavoritesContent = @"VLCFavoritesContent";

@implementation VLCFavorite

@end

@interface VLCFavoriteServer : VLCFavorite

@property (readwrite, atomic) NSMutableArray *favorites;

@end

@implementation VLCFavoriteServer

@end

@interface VLCFavoriteService ()
{
    NSMutableArray *_favoriteContentArray;
    NSMutableArray *_serverHostnameArray;
}
@end

@implementation VLCFavoriteService

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _favoriteContentArray = [NSMutableArray arrayWithArray:[defaults objectForKey:VLCFavoritesContent]];
        _serverHostnameArray = [NSMutableArray arrayWithCapacity:_favoriteContentArray.count];
        for (VLCFavoriteServer *server in _favoriteContentArray) {
            [_serverHostnameArray addObject:server.url.host];
        }
    }
    return self;
}

- (void)storeContent
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        @synchronized (self->_favoriteContentArray) {
            [defaults setObject:self->_favoriteContentArray forKey:VLCFavoritesContent];
        }
    });
}

- (NSInteger)numberOfFavoritedServers
{
    return _serverHostnameArray.count;
}

- (NSInteger)numberOfFavoritesOfServerAtIndex:(NSInteger)index
{
    VLCFavoriteServer *server;
    @synchronized (_favoriteContentArray) {
        if (index < _favoriteContentArray.count) {
            server = _favoriteContentArray[index];
        } else {
            return NSNotFound;
        }
    }
    return server.favorites.count;
}

- (NSString *)nameOfFavoritedServerAtIndex:(NSInteger)index
{
    VLCFavoriteServer *server;
    @synchronized (_favoriteContentArray) {
        if (index < _favoriteContentArray.count) {
            server = _favoriteContentArray[index];
        } else {
            return @"";
        }
    }
    return server.userVisibleName;
}

- (void)setName:(NSString *)name ofFavoritedServerAtIndex:(NSInteger)index
{
    @synchronized (_favoriteContentArray) {
        VLCFavoriteServer *server = _favoriteContentArray[index];
        server.userVisibleName = name;
        _favoriteContentArray[index] = server;
    }
    [self storeContent];
}

- (VLCFavorite *)favoriteOfServerWithIndex:(NSInteger)serverIndex atIndex:(NSInteger)favoriteIndex
{
    VLCFavoriteServer *server;
    @synchronized (_favoriteContentArray) {
        if (serverIndex < _favoriteContentArray.count) {
            server = _favoriteContentArray[serverIndex];
        } else {
            return nil;
        }
    }
    NSArray *favorites = server.favorites;
    if (favoriteIndex < favorites.count) {
        return favorites[favoriteIndex];
    }
    return nil;
}

- (void)addFavorite:(VLCFavorite *)favorite
{
    VLCFavoriteServer *server;
    NSString *hostname = favorite.url.host;
    if (!hostname) {
        NSLog(@"%s: Invalid hostname: %@ for url: %@", __func__, hostname, favorite.url);
        NSAssert(!hostname, @"invalid url for favorite");
        return;
    }
    @synchronized (_favoriteContentArray) {
        NSInteger serverIndex = [_serverHostnameArray indexOfObject:hostname];
        if (serverIndex == NSNotFound) {
            server = [[VLCFavoriteServer alloc] init];
            [_serverHostnameArray addObject:hostname];
            serverIndex = _serverHostnameArray.count - 1;
        } else {
            server = _favoriteContentArray[serverIndex];
        }
        [server.favorites addObject:favorite];
        [_favoriteContentArray replaceObjectAtIndex:serverIndex withObject:server];
    }
    [self storeContent];
}

- (void)removeFavorite:(VLCFavorite *)favorite
{
    VLCFavoriteServer *server;
    NSString *hostname = favorite.url.host;
    if (!hostname) {
        NSLog(@"Invalid hostname: %@ for url: %@", hostname, favorite.url);
        NSAssert(!hostname, @"invalid url for favorite");
        return;
    }
    @synchronized (_favoriteContentArray) {
        NSInteger serverIndex = [_serverHostnameArray indexOfObject:hostname];
        if (serverIndex == NSNotFound) {
            NSLog(@"%s: No server found for hostname %@", __func__, hostname);
            NSAssert(serverIndex == NSNotFound, @"No server for hostname");
            return;
        }
        server = _favoriteContentArray[serverIndex];
        NSArray *favorites = server.favorites;
        NSUInteger count = favorites.count;
        for (NSUInteger index = 0; index < count; index++) {
            VLCFavorite *iter = favorites[index];
            if ([iter.url isEqual: favorite.url]) {
                [server.favorites removeObjectAtIndex:index];
                break;
            }
        }
    }
    [self storeContent];
}

- (BOOL)isFavoriteURL:(NSURL *)url
{
    NSString *hostname = url.host;
    NSUInteger serverIndex = [_serverHostnameArray indexOfObject:hostname];
    if (serverIndex == NSNotFound) {
        return NO;
    }

    VLCFavoriteServer *server;
    @synchronized (_favoriteContentArray) {
        server = _favoriteContentArray[serverIndex];
    }

    for (VLCFavorite *favorite in server.favorites) {
        if ([favorite.url isEqual:url]) {
            return YES;
        }
    }
    return NO;
}

@end
