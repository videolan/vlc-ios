/*****************************************************************************
 * VLCAppleTVSceneDelegate.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppleTVSceneDelegate.h"
#import "AppleTVAppDelegate.h"
#import "VLCTopShelfManager.h"

@implementation VLCAppleTVSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions
{
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];

    AppleTVAppDelegate *appDelegate = (AppleTVAppDelegate *)[UIApplication sharedApplication].delegate;
    window.rootViewController = [appDelegate setupMainViewController];
    [window makeKeyAndVisible];
    appDelegate.window = window;

    [[VLCTopShelfManager sharedManager] update];

    [self scene:scene openURLContexts:connectionOptions.URLContexts];
}

- (void)sceneDidDisconnect:(UIScene *)scene
{
}

- (void)sceneDidEnterBackground:(UIScene *)scene
{
    UIApplication *sharedApplication = [UIApplication sharedApplication];
    AppleTVAppDelegate *appDelegate = (AppleTVAppDelegate *)sharedApplication.delegate;
    [appDelegate applicationWillTerminate:sharedApplication];

    [[VLCTopShelfManager sharedManager] update];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts
{
    NSURL *url = URLContexts.anyObject.URL;
    if (!url) {
        return;
    }

    UIApplication *sharedApplication = [UIApplication sharedApplication];
    AppleTVAppDelegate *appDelegate = (AppleTVAppDelegate *)sharedApplication.delegate;
    [appDelegate application:sharedApplication openURL:url options:@{}];
}

@end
