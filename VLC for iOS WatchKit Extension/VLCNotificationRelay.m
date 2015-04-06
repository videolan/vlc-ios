/*****************************************************************************
 * VLCNotificationRelay.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNotificationRelay.h"

@interface VLCNotificationRelay ()
@property (nonatomic, readonly) NSMutableDictionary *localToRemote;
@property (nonatomic, readonly) NSMutableDictionary *remoteToLocal;
@end

@implementation VLCNotificationRelay

+ (instancetype)sharedRelay
{
    static dispatch_once_t onceToken;
    static VLCNotificationRelay *instance;
    dispatch_once(&onceToken, ^{
        instance = [VLCNotificationRelay new];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _localToRemote = [NSMutableDictionary dictionary];
        _remoteToLocal = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterRemoveObserver(center, (__bridge const void *)(self), NULL, NULL);
}

- (void)addRelayLocalName:(NSString *)localName toRemoteName:(NSString *)remoteName {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localNotification:) name:localName object:nil];
    self.localToRemote[localName] = remoteName;
}

- (void)removeRelayLocalName:(NSString *)localName {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:localName object:nil];
    [self.localToRemote removeObjectForKey:localName];
}

- (void)addRelayRemoteName:(NSString *)remoteName toLocalName:(NSString *)localName {
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(center, (__bridge  const void *)(self), notificationCallback, (__bridge CFStringRef)remoteName, NULL, CFNotificationSuspensionBehaviorHold);
    self.remoteToLocal[remoteName] = localName;
}

- (void)removeRelayRemoteName:(NSString *)remoteName {
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterRemoveObserver(center, (__bridge const void *)(self), (__bridge CFStringRef)remoteName, NULL);
    [self.remoteToLocal removeObjectForKey:remoteName];
}

#pragma mark - notification handeling
- (void)localNotification:(NSNotification *)notification {

    NSString *localName = notification.name;
    NSString *remoteName = self.localToRemote[localName];

    /* 
     * in current version of iOS this is ignored for the darwin center
     * nevertheless we use it to be future proof
     */
    NSDictionary *userInfo = notification.userInfo;

    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterPostNotification(center, (__bridge CFStringRef)remoteName, NULL, (__bridge CFDictionaryRef)userInfo, false);
}

static void notificationCallback(CFNotificationCenterRef center, void* observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    VLCNotificationRelay *relay = (__bridge VLCNotificationRelay*) observer;
    NSString *remoteName = (__bridge NSString *)name;
    NSString *localName = relay.remoteToLocal[remoteName];

    /*
     * in current version of iOS this is ignored for the darwin center
     * nevertheless we use it to be future proof
     */
    NSDictionary *dict = (__bridge NSDictionary *)userInfo;
    [[NSNotificationCenter defaultCenter] postNotificationName:localName object:nil userInfo:dict];
}


@end
