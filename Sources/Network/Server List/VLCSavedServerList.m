/*****************************************************************************
 * VLCSavedServerList.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSavedServerList.h"
#import <XKKeychain/XKKeychainGenericPasswordItem.h>
#import "VLCNetworkServerLoginInformation+Keychain.h"

NSString *const VLCSavedServerListDidChange = @"VLCSavedServerListDidChange";

@implementation VLCSavedServerList
{
    NSMutableArray<NSString *> *_serverList;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _serverList = [NSMutableArray array];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(ubiquitousKeyValueStoreDidChange:)
                                                     name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                   object:[NSUbiquitousKeyValueStore defaultStore]];

        NSUbiquitousKeyValueStore *ukvStore = [NSUbiquitousKeyValueStore defaultStore];
        [ukvStore synchronize];
        NSArray *ukvServerList = [ukvStore arrayForKey:kVLCStoredServerList];
        if (ukvServerList) {
            [_serverList addObjectsFromArray:ukvServerList];
        }
#if !TARGET_OS_TV
        [self migrateServerlistToCloudIfNeeded];
#endif
    }
    return self;
}

- (NSArray<NSString *> *)serverIdentifiers
{
    return [_serverList copy];
}

#if !TARGET_OS_TV
- (void)migrateServerlistToCloudIfNeeded
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults boolForKey:kVLCMigratedToUbiquitousStoredServerList]) {
        return;
    }

    /* we need to migrate from previous, insecure storage fields */
    NSArray *ftpServerList = [defaults objectForKey:kVLCFTPServer];
    NSArray *ftpLoginList = [defaults objectForKey:kVLCFTPLogin];
    NSArray *ftpPasswordList = [defaults objectForKey:kVLCFTPPassword];
    NSUInteger count = ftpServerList.count;

    if (count > 0) {
        for (NSUInteger i = 0; i < count; i++) {
            XKKeychainGenericPasswordItem *keychainItem = [[XKKeychainGenericPasswordItem alloc] init];
            keychainItem.service = ftpServerList[i];
            keychainItem.account = ftpLoginList[i];
            keychainItem.secret.stringValue = ftpPasswordList[i];
            [keychainItem saveWithError:nil];
            [_serverList addObject:ftpServerList[i]];
        }
    }

    NSArray *plexServerList = [defaults objectForKey:kVLCPLEXServer];
    NSArray *plexPortList = [defaults objectForKey:kVLCPLEXPort];
    count = plexServerList.count;
    if (count > 0) {
        for (NSUInteger i = 0; i < count; i++) {
            [_serverList addObject:[NSString stringWithFormat:@"plex://%@:%@", plexServerList[i], plexPortList[i]]];
        }
    }

    NSUbiquitousKeyValueStore *ukvStore = [NSUbiquitousKeyValueStore defaultStore];
    [ukvStore setArray:_serverList forKey:kVLCStoredServerList];
    [ukvStore synchronize];
    [defaults setBool:YES forKey:kVLCMigratedToUbiquitousStoredServerList];
}
#endif

- (void)ubiquitousKeyValueStoreDidChange:(NSNotification *)notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(ubiquitousKeyValueStoreDidChange:) withObject:notification waitUntilDone:NO];
        return;
    }

    /* TODO: don't blindly trust that the Cloud knows best */
    _serverList = [NSMutableArray arrayWithArray:[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:kVLCStoredServerList]];
    [self postChangeNotification];
}

- (void)storeServerList
{
    NSUbiquitousKeyValueStore *ukvStore = [NSUbiquitousKeyValueStore defaultStore];
    [ukvStore setArray:_serverList forKey:kVLCStoredServerList];
    [ukvStore synchronize];

    [self postChangeNotification];
}

- (void)postChangeNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCSavedServerListDidChange object:self];
}

- (BOOL)addLogin:(VLCNetworkServerLoginInformation *)login error:(NSError **)error
{
    NSError *innerError = nil;
    BOOL success = [login saveLoginInformationToKeychainWithError:&innerError];
    if (!success) {
        APLog(@"Failed to save login with error: %@", innerError);
        if (error) {
            *error = innerError;
        }
    }

    // even if the save fails we want to add the server identifier to the iCloud list
    NSString *serviceIdentifier = [login keychainServiceIdentifier];
    if (!serviceIdentifier) {
        if (error) {
            *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
        }
        return NO;
    }

    NSString *entry = serviceIdentifier;
    if (login.username.length > 0) {
        NSURLComponents *components = [NSURLComponents componentsWithString:serviceIdentifier];
        components.user = login.username;
        entry = components.string ?: serviceIdentifier;
    }

    if (![_serverList containsObject:entry]) {
        [_serverList addObject:entry];
    }
    [self storeServerList];

    return success;
}

- (BOOL)removeServerAtIndex:(NSUInteger)index error:(NSError **)error
{
    if (index >= _serverList.count) {
        return NO;
    }

    NSString *entry = _serverList[index];
    [_serverList removeObjectAtIndex:index];

    NSError *innerError = nil;
    BOOL success = YES;
    if (![self keychainItemOfEntryIsInUse:entry]) {
        XKKeychainGenericPasswordItem *keychainItem = [[XKKeychainGenericPasswordItem alloc] init];
        keychainItem.service = [self serviceOfEntry:entry];
        keychainItem.account = [self userOfEntry:entry];
        success = [keychainItem deleteWithError:&innerError];
        if (!success) {
            APLog(@"Failed to delete login with error: %@", innerError);
        }
    }
    if (error) {
        *error = innerError;
    }

    [self storeServerList];

    return success;
}

- (VLCNetworkServerLoginInformation *)loginAtIndex:(NSUInteger)index error:(NSError **)error
{
    if (index >= _serverList.count) {
        return nil;
    }

    NSString *entry = _serverList[index];
    VLCNetworkServerLoginInformation *login = [VLCNetworkServerLoginInformation loginInformationWithKeychainIdentifier:entry];
    login.username = [self userOfEntry:entry];
    if (![login loadLoginInformationFromKeychainWithError:error]) {
        return nil;
    }

    return login;
}

- (NSString *)usernameAtIndex:(NSUInteger)index
{
    if (index >= _serverList.count) {
        return nil;
    }

    NSString *entry = _serverList[index];
    NSString *user = [self userOfEntry:entry];
    if (user) {
        return user;
    }

    XKKeychainGenericPasswordItem *keychainItem = [XKKeychainGenericPasswordItem itemsForService:entry error:nil].firstObject;
    return keychainItem.account;
}

- (NSString *)userOfEntry:(NSString *)entry
{
    return [NSURLComponents componentsWithString:entry].user;
}

- (NSString *)serviceOfEntry:(NSString *)entry
{
    NSURLComponents *components = [NSURLComponents componentsWithString:entry];
    if (!components.user) {
        return entry;
    }

    components.user = nil;
    return components.string;
}

- (BOOL)keychainItemOfEntryIsInUse:(NSString *)entry
{
    NSString *service = [self serviceOfEntry:entry];
    NSString *user = [self userOfEntry:entry];
    for (NSString *otherEntry in _serverList) {
        if (![[self serviceOfEntry:otherEntry] isEqualToString:service]) {
            continue;
        }
        if (!user || [[self userOfEntry:otherEntry] isEqualToString:user]) {
            return YES;
        }
    }
    return NO;
}

@end
