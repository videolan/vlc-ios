//
//  VLCNotificationRelay.h
//  VLC for iOS
//
//  Created by Tobias Conradi on 02.04.15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VLCNotificationRelay : NSObject
+ (instancetype)sharedRelay;

/* relays NSNotificationCenter notifications with localName to CFNotifactionCenter with remoteName */
- (void)addRelayLocalName:(NSString *)localName toRemoteName:(NSString *)remoteName;
- (void)removeRelayLocalName:(NSString *)localName;


/* relays CFNotifactionCenter with remoteName to  NSNotificationCenter notifications with localName */
- (void)addRelayRemoteName:(NSString *)remoteName toLocalName:(NSString *)localName;
- (void)removeRelayRemoteName:(NSString *)remoteName;

@end
