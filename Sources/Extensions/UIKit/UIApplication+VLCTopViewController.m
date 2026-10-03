/*****************************************************************************
 * UIApplication+VLCTopViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "UIApplication+VLCTopViewController.h"
#if !TARGET_OS_TV
#import "VLCPlaybackNavigationController.h"
#endif

@implementation UIApplication (VLCTopViewController)

- (UIWindow *)activeKeyWindow
{
    UIWindow *inactiveKeyWindow;
    for (UIScene *scene in self.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        BOOL sceneIsActive = scene.activationState == UISceneActivationStateForegroundActive;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (!window.isKeyWindow) {
                continue;
            }
            if (sceneIsActive) {
                return window;
            }
            if (!inactiveKeyWindow) {
                inactiveKeyWindow = window;
            }
        }
    }
    return inactiveKeyWindow;
}

- (UIViewController *)topViewController
{
    UIViewController *viewController = self.activeKeyWindow.rootViewController;
    while (viewController.presentedViewController) {
        viewController = viewController.presentedViewController;
    }
    return viewController;
}

#if !TARGET_OS_TV
- (UIViewController *)dismissPresentedScreensAbovePlayer
{
    UIViewController *presenter = self.activeKeyWindow.rootViewController;
    if ([presenter.presentedViewController isKindOfClass:[VLCPlaybackNavigationController class]]) {
        presenter = presenter.presentedViewController;
    }
    if (presenter.presentedViewController) {
        [presenter dismissViewControllerAnimated:NO completion:nil];
    }
    return presenter;
}
#endif

@end
