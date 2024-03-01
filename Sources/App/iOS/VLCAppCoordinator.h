/*****************************************************************************
 * VLCAppCoordinator.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022-2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_IOS
@class MediaLibraryService;
@class VLCRendererDiscovererManager;
@class VLCMLMedia;
@class VLCStripeController;
#endif
@class VLCFavoriteService;


@class VLCHTTPUploaderController;

@interface VLCAppCoordinator : NSObject

+ (nonnull instancetype)sharedInstance;

@property (readonly) VLCHTTPUploaderController *httpUploaderController;
@property (readonly) VLCFavoriteService *favoriteService;

#if TARGET_OS_IOS
@property (readonly) MediaLibraryService *mediaLibraryService;
@property (readonly) VLCRendererDiscovererManager *rendererDiscovererManager;
@property (readonly) VLCStripeController *stripeController;

@property (nullable) UIWindow *externalWindow;
@property (retain) UITabBarController *tabBarController;

- (void)handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem;

- (nullable VLCMLMedia *)mediaForUserActivity:(NSUserActivity *)userActivity;
#endif

@end

NS_ASSUME_NONNULL_END
