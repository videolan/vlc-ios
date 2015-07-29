/*****************************************************************************
 * VLCWatchCommunication.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCWatchCommunication : NSObject <WCSessionDelegate>

+ (BOOL)isSupported;
+ (instancetype)sharedInstance;

- (void)startRelayingNotificationName:(nullable NSString *)name object:(nullable id)object;
- (void)stopRelayingNotificationName:(nullable NSString *)name object:(nullable id)object;

@end

NS_ASSUME_NONNULL_END