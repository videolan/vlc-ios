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
#import "VLCPlaybackService.h"
#import "VLCPlayerDisplayController.h"

@implementation VLCPlaybackNavigationController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.isBeingPresented) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];
        if (!playbackService.playerIsSetup) {
            [playbackService.playerDisplayController dismissPlaybackView];
        }
    });
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

- (BOOL)prefersStatusBarHidden
{
    return [self.topViewController prefersStatusBarHidden];
}

@end
