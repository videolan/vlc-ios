/*****************************************************************************
 * VLCAppCoordinator.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022-2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppCoordinator.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import "VLCRemoteControlService.h"
#import "VLCHTTPUploaderController.h"
#import "VLCTransferController.h"
#import "VLCFavoriteService.h"
#import "VLCRadioService.h"
#import "VLCSavedServerList.h"
#import "VLCStripeController.h"
#import "VLC-Swift.h"

@interface VLCAppCoordinator()
{
    MediaLibraryService *_mediaLibraryService;
    VLCFavoriteService *_favoriteService;
    VLCRadioService *_radioService;
    VLCSavedServerList *_savedServerList;
    VLCHTTPUploaderController *_httpUploaderController;
    VLCTransferController *_transferController;
    VLCRemoteControlService *_remoteControlService;

#if TARGET_OS_IOS || TARGET_OS_VISION
    VLCBottomTabBarController *_tabBarController;
    TabBarCoordinator *_tabCoordinator;
    VLCPlayerDisplayController *_playerDisplayController;
    VLCStripeController *_stripeController;
#endif

#if TARGET_OS_IOS
    VLCRendererDiscovererManager *_rendererDiscovererManager;
#endif
}

@end

@implementation VLCAppCoordinator

+ (instancetype)sharedInstance
{
    static VLCAppCoordinator *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [VLCAppCoordinator new];
        if (sharedInstance) {
            sharedInstance->_mediaLibraryService = [[MediaLibraryService alloc] initWithLibraryType:MLServiceTypeMediaLibrary];
        }
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self initializeServices];
        });
    }
    return self;
}


- (MediaLibraryService *)mediaLibraryService
{
    if (!_mediaLibraryService) {
        _mediaLibraryService = [[MediaLibraryService alloc] initWithLibraryType:MLServiceTypeMediaLibrary];
    }
    return _mediaLibraryService;
}

- (VLCFavoriteService *)favoriteService
{
    if (!_favoriteService) {
        _favoriteService = [[VLCFavoriteService alloc] init];
    }

    return _favoriteService;
}

- (VLCRadioService *)radioService
{
    if (!_radioService) {
        _radioService = [[VLCRadioService alloc] init];
    }

    return _radioService;
}

- (VLCSavedServerList *)savedServerList
{
    if (!_savedServerList) {
        _savedServerList = [[VLCSavedServerList alloc] init];
    }

    return _savedServerList;
}

- (void)initializeServices
{
    if (_httpUploaderController) {
        return;
    }

    // Init the HTTP Server and clean its cache if on iOS
    _httpUploaderController = [[VLCHTTPUploaderController alloc] init];
    #if TARGET_OS_IOS
    [_httpUploaderController cleanCache];
    #endif
    _httpUploaderController.medialibrary = self.mediaLibraryService;

    // start the remote control service
    _remoteControlService = [[VLCRemoteControlService alloc] init];
}

- (VLCHTTPUploaderController *)httpUploaderController
{
    if (!_httpUploaderController) {
        [self initializeServices];
    }
    return _httpUploaderController;
}

- (VLCTransferController *)transferController
{
    @synchronized (self) {
        if (!_transferController) {
            _transferController = [[VLCTransferController alloc] init];
        }
    }
    return _transferController;
}

#if !TARGET_OS_TV

#if TARGET_OS_IOS
- (VLCRendererDiscovererManager *)rendererDiscovererManager
{
    if (!_rendererDiscovererManager) {
        _rendererDiscovererManager = [[VLCRendererDiscovererManager alloc] initWithPresentingViewController:nil];
    }

    return _rendererDiscovererManager;
}
#endif

- (void)setTabBarController:(VLCBottomTabBarController *)tabBarController
{
    _tabBarController = tabBarController;
    _tabCoordinator = [[TabBarCoordinator alloc] initWithTabBarController:_tabBarController mediaLibraryService:self.mediaLibraryService];

    _playerDisplayController = [[VLCPlayerDisplayController alloc] init];
    [_tabBarController.view addSubview:_playerDisplayController.view];
    _playerDisplayController.view.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(0, 0, tabBarController.tabBar.frame.size.height, 0);
    _playerDisplayController.realBottomAnchor = tabBarController.tabBar.topAnchor;
    _playerDisplayController.realTopAnchor = tabBarController.view.safeAreaLayoutGuide.topAnchor;
    _playerDisplayController.miniPlayerReferenceTabBar = tabBarController.tabBar;

    if (@available(iOS 18.0, *)) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            // Adjust the margins and the constraint to the previous tab bar appearance on iPadOS
            _playerDisplayController.view.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(0, 0, tabBarController.bottomBar.frame.size.height, 0);
            _playerDisplayController.realBottomAnchor = tabBarController.view.safeAreaLayoutGuide.bottomAnchor;
            _playerDisplayController.miniPlayerReferenceTabBar = nil;
        }
    }

    [_playerDisplayController didMoveToParentViewController:tabBarController];
}

- (VLCBottomTabBarController*)tabBarController
{
    return _tabBarController;
}

- (void)handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem
{
    [_tabCoordinator handleShortcutItem:shortcutItem];
}

- (VLCMLMedia *)mediaForUserActivity:(NSUserActivity *)userActivity
{
    VLCMLIdentifier identifier = 0;
    NSDictionary *userInfo = userActivity.userInfo;

    if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
        identifier = [userInfo[CSSearchableItemActivityIdentifier] integerValue];
    } else {
        identifier = [userInfo[@"playingmedia"] integerValue];
    }

    if (identifier > 0) {
        return [self.mediaLibraryService mediaFor:identifier];
    }

    return nil;
}


- (VLCStripeController *)stripeController
{
    if (!_stripeController) {
        _stripeController = [[VLCStripeController alloc] init];
    }
    return _stripeController;
}
#endif

@end
