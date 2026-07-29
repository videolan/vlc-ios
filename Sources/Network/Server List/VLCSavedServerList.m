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
        [self migrateServerlistToCloudIfNeeded];
    }
    return self;
}

- (NSArray<NSString *> *)serverIdentifiers
{
    return [_serverList copy];
}

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

    [_serverList addObject:serviceIdentifier];
    [self storeServerList];

    return success;
}

- (BOOL)removeServerAtIndex:(NSUInteger)index error:(NSError **)error
{
    if (index >= _serverList.count) {
        return NO;
    }

    NSString *serviceString = _serverList[index];
    NSError *innerError = nil;
    BOOL success = [XKKeychainGenericPasswordItem removeItemsForService:serviceString error:&innerError];
    if (!success) {
        APLog(@"Failed to delete login with error: %@", innerError);
    }
    if (error) {
        *error = innerError;
    }

    [_serverList removeObjectAtIndex:index];
    [self storeServerList];

    return success;
}

- (VLCNetworkServerLoginInformation *)loginAtIndex:(NSUInteger)index error:(NSError **)error
{
    if (index >= _serverList.count) {
        return nil;
    }

    VLCNetworkServerLoginInformation *login = [VLCNetworkServerLoginInformation loginInformationWithKeychainIdentifier:_serverList[index]];
    if (![login loadLoginInformationFromKeychainWithError:error]) {
        return nil;
    }

    return login;
}

@end
