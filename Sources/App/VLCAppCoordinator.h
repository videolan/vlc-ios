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

@class MediaLibraryService;
@class VLCRendererDiscovererManager;
@class VLCFavoriteService;
@class VLCMLMedia;

#if TARGET_OS_IOS || TARGET_OS_VISION
@class VLCStripeController;
#endif

#if !TARGET_OS_WATCH
@class VLCHTTPUploaderController;
#endif

@class VideoModel;
@class TrackModel;

@interface VLCAppCoordinator : NSObject

+ (nonnull instancetype)sharedInstance;

#if !TARGET_OS_WATCH
@property (readonly) VLCHTTPUploaderController *httpUploaderController;
@property (readonly) VLCFavoriteService *favoriteService;
#endif
@property (readonly) MediaLibraryService *mediaLibraryService;
#if !TARGET_OS_WATCH
@property (readonly) VLCRendererDiscovererManager *rendererDiscovererManager;
@property (retain) UITabBarController *tabBarController;
@property (nullable) UIWindow *externalWindow;
#endif

#if TARGET_OS_IOS || TARGET_OS_VISION
@property (readonly) VLCStripeController *stripeController;
#endif

#if TARGET_OS_TV
@property (readonly) VideoModel *videoModel;
@property (readonly) TrackModel *trackModel;
#endif

#if TARGET_OS_IOS || TARGET_OS_VISION
- (void)handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem;
- (void)setTabBarController:(UITabBarController *)tabBarController;
- (VLCMLMedia *)mediaForUserActivity:(NSUserActivity *)userActivity;
#endif

#if TARGET_OS_WATCH
- (nullable VLCMLMedia *)mediaForUserActivity:(NSUserActivity *)userActivity;
#endif

@end

NS_ASSUME_NONNULL_END
