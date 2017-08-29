/*****************************************************************************
 * VLCPlaybackNavigationController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackNavigationController.h"
#if TARGET_OS_IOS
#import "VLCMovieViewController.h"
#endif

@implementation VLCPlaybackNavigationController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

#if TARGET_OS_IOS
- (BOOL)shouldAutorotate
{
    id topVC = self.topViewController;
    if ([topVC isKindOfClass:[VLCMovieViewController class]])
        return ![(VLCMovieViewController *)topVC rotationIsDisabled];

    return YES;
}
#endif

@end
