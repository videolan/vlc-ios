/*****************************************************************************
 * VLCAppSceneDelegate.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppSceneDelegate.h"
#import "VLCAppDelegate.h"
#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@interface VLCAppSceneDelegate () <UISceneDelegate>
{
}

@end

@implementation VLCAppSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions
{
    [VLCAppearanceManager setupAppearanceWithTheme:PresentationTheme.current];

    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    window.rootViewController = [UITabBarController new];
    [window makeKeyAndVisible];

    [VLCAppearanceManager setupUserInterfaceStyleWithTheme:PresentationTheme.current];

    VLCAppDelegate *appDelegate = (VLCAppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.window = window;
    [appDelegate setupTabBarAppearance];

    [self scene:scene openURLContexts:connectionOptions.URLContexts];
}

- (void)sceneDidDisconnect:(UIScene *)scene
{
}

- (void)sceneDidBecomeActive:(UIScene *)scene
{
    UIApplication *sharedApplication = [UIApplication sharedApplication];
    VLCAppDelegate *appDelegate = (VLCAppDelegate *)sharedApplication.delegate;
    [appDelegate applicationDidBecomeActive:sharedApplication];
}

- (void)sceneWillResignActive:(UIScene *)scene
{
    UIApplication *sharedApplication = [UIApplication sharedApplication];
    VLCAppDelegate *appDelegate = (VLCAppDelegate *)sharedApplication.delegate;
    [appDelegate applicationWillResignActive:sharedApplication];
}

- (void)sceneWillEnterForeground:(UIScene *)scene
{
}

- (void)sceneDidEnterBackground:(UIScene *)scene
{
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts
{
    NSURL *url = URLContexts.anyObject.URL;
    if (!url) {
        return;
    }

    UIApplication *sharedApplication = [UIApplication sharedApplication];
    VLCAppDelegate *appDelegate = (VLCAppDelegate *)sharedApplication.delegate;
    [appDelegate application:sharedApplication openURL:url options:@{}];
}

@end

#pragma clang diagnostic pop
