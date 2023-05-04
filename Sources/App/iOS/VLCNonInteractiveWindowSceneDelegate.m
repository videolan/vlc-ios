/*****************************************************************************
 * VLCNonInteractiveWindowSceneDelegate.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNonInteractiveWindowSceneDelegate.h"
#import "VLCExternalDisplayController.h"
#import "VLCAppCoordinator.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

NSString *VLCNonInteractiveWindowSceneBecameActive = @"VLCNonInteractiveWindowSceneBecameActive";
NSString *VLCNonInteractiveWindowSceneDisconnected = @"VLCNonInteractiveWindowSceneDisconnected";

@interface VLCNonInteractiveWindowSceneDelegate () <UISceneDelegate>
{
}
@end

@implementation VLCNonInteractiveWindowSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions
{
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    window.rootViewController = [[VLCExternalDisplayController alloc] initWithNibName:nil bundle:nil];
    [window makeKeyAndVisible];
    [VLCAppCoordinator sharedInstance].externalWindow = window;
}

- (void)sceneDidDisconnect:(UIScene *)scene
{
    [VLCAppCoordinator sharedInstance].externalWindow = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCNonInteractiveWindowSceneDisconnected object:self];
}

- (void)sceneDidBecomeActive:(UIScene *)scene
{
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCNonInteractiveWindowSceneBecameActive object:self];
}

@end

#pragma clang diagnostic pop
