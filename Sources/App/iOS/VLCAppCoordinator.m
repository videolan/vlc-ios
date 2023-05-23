/*****************************************************************************
 * VLCAppCoordinator.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppCoordinator.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import "VLCRemoteControlService.h"
#import "VLC-Swift.h"

@interface VLCAppCoordinator()
{
    MediaLibraryService *_mediaLibraryService;
    VLCRendererDiscovererManager *_rendererDiscovererManager;
    VLCHTTPUploaderController *_httpUploaderController;
    UITabBarController *_tabBarController;
    TabBarCoordinator *_tabCoordinator;
    VLCPlayerDisplayController *_playerDisplayController;
    VLCRemoteControlService *_remoteControlService;
    UIWindow *_externalWindow;
}

@end

@implementation VLCAppCoordinator

+ (instancetype)sharedInstance
{
    static VLCAppCoordinator *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [VLCAppCoordinator new];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mediaLibraryService = [[MediaLibraryService alloc] init];

        // Init the HTTP Server and clean its cache
        // FIXME: VLCHTTPUploaderController should perhaps be a service?
        _httpUploaderController = [VLCHTTPUploaderController sharedInstance];
        [_httpUploaderController cleanCache];
        _httpUploaderController.medialibrary = _mediaLibraryService;

        _remoteControlService = [[VLCRemoteControlService alloc] init];
    }
    return self;
}

- (MediaLibraryService *)mediaLibraryService
{
    return _mediaLibraryService;
}

- (VLCRendererDiscovererManager *)rendererDiscovererManager
{
    if (!_rendererDiscovererManager) {
        _rendererDiscovererManager = [[VLCRendererDiscovererManager alloc] initWithPresentingViewController:nil];
    }

    return _rendererDiscovererManager;
}

- (void)setExternalWindow:(UIWindow *)externalWindow
{
    _externalWindow = externalWindow;
}

- (UIWindow *)externalWindow
{
    if (@available(iOS 13.0, *)) {
        return _externalWindow;
    } else {
        NSArray *screens = UIScreen.screens;
        if (screens.count <= 1)
            return nil;

        UIScreen *externalScreen = screens[1];
        externalScreen.overscanCompensation = UIScreenOverscanCompensationNone;

        _externalWindow = [[UIWindow alloc] initWithFrame:externalScreen.bounds];
        _externalWindow.rootViewController = [[VLCExternalDisplayController alloc] initWithNibName:nil bundle:nil];
        _externalWindow.screen = externalScreen;
        [_externalWindow makeKeyAndVisible];
    }
    return _externalWindow;
}

- (void)setTabBarController:(UITabBarController *)tabBarController
{
    _tabBarController = tabBarController;
    _tabCoordinator = [[TabBarCoordinator alloc] initWithTabBarController:_tabBarController mediaLibraryService:self.mediaLibraryService];

    _playerDisplayController = [[VLCPlayerDisplayController alloc] init];
    [_tabBarController.view addSubview:_playerDisplayController.view];
    _playerDisplayController.view.layoutMargins = UIEdgeInsetsMake(0, 0, tabBarController.tabBar.frame.size.height, 0);
    _playerDisplayController.realBottomAnchor = tabBarController.tabBar.topAnchor;
    [_playerDisplayController didMoveToParentViewController:tabBarController];
}

- (void)handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem
{
    [_tabCoordinator handleShortcutItem:shortcutItem];
}

- (VLCMLMedia *)mediaForUserActivity:(NSUserActivity *)userActivity
{
    VLCMLIdentifier identifier = 0;
    NSDictionary *userInfo = userActivity.userInfo;

    if (userActivity.activityType == CSSearchableItemActionType) {
        identifier = [userInfo[CSSearchableItemActivityIdentifier] integerValue];
    } else {
        identifier = [userInfo[@"playingmedia"] integerValue];
    }

    if (identifier > 0) {
        return [_mediaLibraryService mediaFor:identifier];
    }

    return nil;
}

@end
