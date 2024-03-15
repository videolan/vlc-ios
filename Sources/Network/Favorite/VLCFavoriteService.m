/*****************************************************************************
 * VLCFavoriteService.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023-2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFavoriteService.h"
#import "VLCNetworkServerLoginInformation+Keychain.h"

NSString *VLCFavoritesContent = @"VLCFavoritesContent";
NSString *VLCFavoriteUserVisibleName = @"VLCFavoriteUserVisibleName";
NSString *VLCFavoriteURL = @"VLCFavoriteURL";
NSString *VLCFavoriteArray = @"VLCFavoriteArray";
NSString *VLCFavoritesFile = @"Favorites.plist";

@implementation VLCFavorite

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.userVisibleName = [coder decodeObjectForKey:VLCFavoriteUserVisibleName];
        self.url = [coder decodeObjectForKey:VLCFavoriteURL];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.userVisibleName forKey:VLCFavoriteUserVisibleName];
    [coder encodeObject:self.url forKey:VLCFavoriteURL];
}

- (NSString *)protocolIdentifier
{
    return [[self.url scheme] uppercaseString];
}

- (VLCNetworkServerLoginInformation *)loginInformation
{
    VLCNetworkServerLoginInformation *login = [VLCNetworkServerLoginInformation loginInformationWithKeychainIdentifier: self.url.absoluteString];
    NSError *error = nil;
    if ([login loadLoginInformationFromKeychainWithError:&error]) {
        if (login.username == nil) {
            /* in case the username wasn't saved per directory, try for the entire server */
            NSString *identifier = [NSString stringWithFormat:@"%@://%@", self.protocolIdentifier, self.url.host];
            login = [VLCNetworkServerLoginInformation loginInformationWithKeychainIdentifier:identifier];
            [login loadLoginInformationFromKeychainWithError:&error];
            /* restore the trick from above so we open the actually requested directory */
            login.address = [self.url.host stringByAppendingPathComponent:self.url.path];
        }
    }
    return login;
}

@end

@interface VLCFavoriteServer : VLCFavorite

@property (readwrite, atomic) NSMutableArray *favorites;

@end

@implementation VLCFavoriteServer

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.favorites = [NSMutableArray arrayWithArray:[coder decodeObjectForKey:VLCFavoriteArray]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:self.favorites forKey:VLCFavoriteArray];
}

@end

@interface VLCFavoriteService ()
{
    NSMutableArray *_favoriteContentArray;
    NSMutableArray *_serverHostnameArray;
    NSString *_filePath;
}
@end

@implementation VLCFavoriteService

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSSearchPathDirectory directory;
#if TARGET_OS_IOS
        directory = NSLibraryDirectory;
#else
        // There is no permanent storage on tvOS, we need to store the favorites in the cache directory.
        // This data may be erased without a warning when the space runs low on the physical device.
        directory = NSCachesDirectory;
#endif
        NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
        NSString *libraryFolder = [paths firstObject];
        _filePath = [libraryFolder stringByAppendingPathComponent:VLCFavoritesFile];

        if ([[NSFileManager defaultManager] fileExistsAtPath:_filePath]) {
            NSData *data = [[NSData alloc] initWithContentsOfFile:_filePath];
            if (data != nil) {
                _favoriteContentArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
        }

        if (_favoriteContentArray == nil) {
            _favoriteContentArray = [NSMutableArray array];
        }
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
        @synchronized (self->_favoriteContentArray) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self->_favoriteContentArray];
            [data writeToFile:self->_filePath atomically:YES];
        }
    });
}

- (void)storeContentSynchronously
{
    @synchronized (self->_favoriteContentArray) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self->_favoriteContentArray];
        [data writeToFile:self->_filePath atomically:YES];
    }
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
            return 0;
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
        NSAssert(!hostname, @"invalid url for favorite");
        return;
    }
    @synchronized (_favoriteContentArray) {
        NSInteger serverIndex = [_serverHostnameArray indexOfObject:hostname];
        if (serverIndex == NSNotFound) {
            server = [[VLCFavoriteServer alloc] init];
            server.userVisibleName = hostname;
            server.url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", favorite.url.scheme, favorite.url.host]];
            server.favorites = [NSMutableArray array];
            [_serverHostnameArray addObject:hostname];
        } else {
            server = _favoriteContentArray[serverIndex];
        }
        [server.favorites addObject:favorite];
        if (serverIndex == NSNotFound) {
            [_favoriteContentArray addObject:server];
        } else {
            [_favoriteContentArray replaceObjectAtIndex:serverIndex withObject:server];
        }
    }
    [self storeContent];
}

- (void)removeFavorite:(VLCFavorite *)favorite
{
    VLCFavoriteServer *server;
    NSString *hostname = favorite.url.host;
    if (!hostname) {
        NSAssert(!hostname, @"invalid url for favorite");
        return;
    }
    @synchronized (_favoriteContentArray) {
        NSInteger serverIndex = [_serverHostnameArray indexOfObject:hostname];
        if (serverIndex == NSNotFound) {
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
                if (server.favorites.count == 0) {
                    [_favoriteContentArray removeObjectAtIndex:serverIndex];
                    [_serverHostnameArray removeObjectAtIndex:serverIndex];
                } else {
                    [_favoriteContentArray replaceObjectAtIndex:serverIndex withObject:server];
                }
                break;
            }
        }
    }
    [self storeContent];
}

- (void)removeFavoriteOfServerWithIndex:(NSInteger)serverIndex atIndex:(NSInteger)favoriteIndex
{
    @synchronized (_favoriteContentArray) {
        VLCFavoriteServer *server = _favoriteContentArray[serverIndex];
        [server.favorites removeObjectAtIndex:favoriteIndex];
        if (server.favorites.count == 0) {
            [_favoriteContentArray removeObjectAtIndex:serverIndex];
            [_serverHostnameArray removeObjectAtIndex:serverIndex];
        } else {
            [_favoriteContentArray replaceObjectAtIndex:serverIndex withObject:server];
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
