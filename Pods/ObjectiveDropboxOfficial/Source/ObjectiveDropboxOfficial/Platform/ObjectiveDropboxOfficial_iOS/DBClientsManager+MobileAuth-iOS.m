///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <UIKit/UIKit.h>

#import "DBClientsManager+Protected.h"
#import "DBClientsManager.h"
#import "DBOAuthManager.h"
#import "DBOAuthMobile-iOS.h"
#import "DBOAuthMobileManager-iOS.h"
#import "DBTransportDefaultConfig.h"

@implementation DBClientsManager (MobileAuth)

+ (void)authorizeFromController:(UIApplication *)sharedApplication
                     controller:(UIViewController *)controller
                        openURL:(void (^_Nonnull)(NSURL *))openURL {
  NSAssert([DBOAuthManager sharedOAuthManager] != nil,
           @"Call `Dropbox.setupWithAppKey` or `Dropbox.setupWithTeamAppKey` before calling this method");
  DBMobileSharedApplication *sharedMobileApplication =
      [[DBMobileSharedApplication alloc] initWithSharedApplication:sharedApplication
                                                        controller:controller
                                                           openURL:openURL];
  [DBMobileSharedApplication setMobileSharedApplication:sharedMobileApplication];
  [[DBOAuthManager sharedOAuthManager] authorizeFromSharedApplication:sharedMobileApplication];
}

+ (void)setupWithAppKey:(NSString *)appKey {
  [[self class] setupWithTransportConfig:[[DBTransportDefaultConfig alloc] initWithAppKey:appKey]];
}

+ (void)setupWithTransportConfig:(DBTransportDefaultConfig *)transportConfig {
  [[self class] setupWithOAuthManager:[[DBOAuthMobileManager alloc] initWithAppKey:transportConfig.appKey]
                      transportConfig:transportConfig];
}

+ (void)setupWithTeamAppKey:(NSString *)appKey {
  [[self class] setupWithTeamTransportConfig:[[DBTransportDefaultConfig alloc] initWithAppKey:appKey]];
}

+ (void)setupWithTeamTransportConfig:(DBTransportDefaultConfig *)transportConfig {
  [[self class] setupWithOAuthManagerTeam:[[DBOAuthMobileManager alloc] initWithAppKey:transportConfig.appKey]
                          transportConfig:transportConfig];
}

@end
