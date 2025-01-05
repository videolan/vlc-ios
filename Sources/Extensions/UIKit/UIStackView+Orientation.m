/*****************************************************************************
 * UIStackView+Orientation.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "UIStackView+Orientation.h"
#import "VLCPlayerDisplayController.h"
#import "VLC-Swift.h"

@interface DummyViewController : UIViewController
@end

@implementation DummyViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end

@implementation UIStackView(Orientation)

- (void)vlc_toggleOrientation
{
    if (@available(iOS 16.0, visionOS 1.0, *)) {
        UIWindowScene *windowScene = self.window.windowScene;
        id prefs;
        if (windowScene.interfaceOrientation == UIInterfaceOrientationPortrait) {
            prefs = [[VLCWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations: UIInterfaceOrientationMaskLandscape];
        } else {
            prefs = [[VLCWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations: UIInterfaceOrientationMaskPortrait];
        }
        [windowScene requestGeometryUpdateWithPreferences:prefs errorHandler:nil];
#if TARGET_OS_VISION
    }
#else
    } else {
        UIInterfaceOrientationMask orientation;
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) {
            orientation = UIInterfaceOrientationMaskLandscapeRight;
        } else {
            orientation = UIInterfaceOrientationMaskPortrait;
        }
        VLCPlayerDisplayController *vpdc = [[VLCPlaybackService sharedInstance] playerDisplayController];
        VLCVideoPlayerViewController *videoVC = (VLCVideoPlayerViewController *)vpdc.videoPlayerViewController;
        videoVC.supportedInterfaceOrientations = orientation;

        /* this is a gross hack to force the OS to redraw */
        DummyViewController *dummyVC = [DummyViewController new];
        dummyVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [videoVC.navigationController presentViewController:dummyVC animated:NO completion:^{
            [dummyVC dismissViewControllerAnimated:NO completion:nil];
        }];
    }
#endif
}

@end

@implementation VLCWindowSceneGeometryPreferencesIOS

- (instancetype)initWithInterfaceOrientations:(UIInterfaceOrientationMask)interfaceOrientations
{
    return [[NSClassFromString(@"UIWindowSceneGeometryPreferencesIOS") alloc] initWithInterfaceOrientations:interfaceOrientations];
}

@end
