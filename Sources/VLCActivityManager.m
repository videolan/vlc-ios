/*****************************************************************************
 * VLCActivityManager.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCActivityManager.h"

@interface VLCActivityManager ()
{
    int _idleCounter;
    int _networkActivityCounter;
}
@end

@implementation VLCActivityManager

+ (instancetype)defaultManager
{
    static VLCActivityManager *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [VLCActivityManager new];
    });

    return sharedInstance;
}

- (void)activateIdleTimer
{
    _idleCounter--;
    if (_idleCounter < 1)
        [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)disableIdleTimer
{
    _idleCounter++;
    if ([UIApplication sharedApplication].idleTimerDisabled == NO)
        [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)networkActivityStarted
{
    _networkActivityCounter++;
#if TARGET_OS_IOS
    if ([UIApplication sharedApplication].networkActivityIndicatorVisible == NO)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
}

- (BOOL)haveNetworkActivity
{
    return _networkActivityCounter >= 1;
}

- (void)networkActivityStopped
{
    _networkActivityCounter--;
#if TARGET_OS_IOS
    if (_networkActivityCounter < 1)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
}

@end
