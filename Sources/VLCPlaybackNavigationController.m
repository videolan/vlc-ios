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
#import "VLCMovieViewController.h"

@interface VLCPlaybackNavigationController ()

@end

@implementation VLCPlaybackNavigationController

- (NSUInteger)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

- (BOOL)shouldAutorotate
{
    id topVC = self.topViewController;
    if ([topVC isKindOfClass:[VLCMovieViewController class]])
        return ![(VLCMovieViewController *)topVC rotationIsDisabled];

    return YES;
}

@end
