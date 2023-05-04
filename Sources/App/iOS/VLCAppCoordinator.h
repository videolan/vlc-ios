/*****************************************************************************
 * VLCAppCoordinator.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MediaLibraryService;
@class VLCRendererDiscovererManager;
@class VLCMLMedia;

@interface VLCAppCoordinator : NSObject

+ (nonnull instancetype)sharedInstance;

@property (readonly) MediaLibraryService *mediaLibraryService;
@property (readonly) VLCRendererDiscovererManager *rendererDiscovererManager;
@property (nullable) UIWindow *externalWindow;

- (void)setTabBarController:(UITabBarController *)tabBarController;

- (void)handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem;

- (VLCMLMedia *)mediaForUserActivity:(NSUserActivity *)userActivity;

@end

NS_ASSUME_NONNULL_END
