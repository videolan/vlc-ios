///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBClientsManager.h"

@class DBTransportDefaultConfig;
@class UIApplication;
@class UIViewController;

NS_ASSUME_NONNULL_BEGIN

///
/// Code with platform-specific (here, iOS) dependencies.
///
/// Extends functionality of the `DBClientsManager` class.
///
@interface DBClientsManager (MobileAuth)

///
/// Commences OAuth mobile flow from supplied view controller.
///
/// @param sharedApplication The `UIApplication` with which to render the OAuth flow.
/// @param controller The `UIViewController` with which to render the OAuth flow.
/// @param openURL A wrapper around app-extension unsafe `openURL` call.
///
+ (void)authorizeFromController:(UIApplication *)sharedApplication
                     controller:(nullable UIViewController *)controller
                        openURL:(void (^_Nonnull)(NSURL *))openURL;

///
/// Stores the user app key. If any access token already exists, initializes an authorized shared `DBUserClient`
/// instance. Convenience method for `setupWithTransportConfig:`.
///
/// This method should be used in the single Dropbox user case. If any stored OAuth tokens exist, one will arbitrarily
/// be retrieved and used to authenticate API calls. Use `setupWithTransportConfig:`, if additional customization of
/// network calling parameters is necessary. This method should be called from the app delegate.
///
/// @param appKey The app key of the third-party Dropbox API user app that will be associated with all API calls. To
/// create an app or to locate your app's app key, please visit the App Console here:
/// https://www.dropbox.com/developers/apps.
///
+ (void)setupWithAppKey:(NSString *)appKey;

///
/// Stores the user transport config info. If any access token already exists, initializes an authorized shared
/// `DBUserClient` instance.
///
/// This method should be used in the single Dropbox user case. If any stored OAuth tokens exist, one will arbitrarily
/// be retrieved and used to authenticate API calls. You can customize some network calling parameters using the
/// different `DBTransportDefaultConfig` constructors. This method should be called from the app delegate.
///
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
///
+ (void)setupWithTransportConfig:(nullable DBTransportDefaultConfig *)transportConfig;

///
/// Stores the team app key. If any access token already exists, initializes an authorized shared `DBTeamClient`
/// instance. Convenience method for `setupWithTeamTransportConfig:`.
///
/// This method should be used in the single Dropbox user case. If any stored OAuth tokens exist, one will arbitrarily
/// be retrieved and used to authenticate API calls. Use `setupWithTeamTransportConfig:`, if additional customization of
/// network calling parameters is necessary. This method should be called from the app delegate.
///
/// @param appKey The app key of the third-party Dropbox API user app that will be associated with all API calls. To
/// create an app or to locate your app's app key, please visit the App Console here:
/// https://www.dropbox.com/developers/apps.
///
+ (void)setupWithTeamAppKey:(NSString *)appKey;

///
/// Stores the team transport config info. If any access token already exists, initializes an authorized shared
/// `DBTeamClient` instance.
///
/// This method should be used in the single Dropbox user case. If any stored OAuth tokens exist, one will arbitrarily
/// be retrieved and used to authenticate API calls. You can customize some network calling parameters using the
/// different `DBTransportDefaultConfig` constructors. This method should be called from the app delegate.
///
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
///
+ (void)setupWithTeamTransportConfig:(nullable DBTransportDefaultConfig *)transportConfig;

@end

NS_ASSUME_NONNULL_END
