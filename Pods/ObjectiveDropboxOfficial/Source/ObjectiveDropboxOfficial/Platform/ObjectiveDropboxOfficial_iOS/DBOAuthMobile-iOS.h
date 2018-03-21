///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>
#import <UIKit/UIKit.h>

#import "DBSharedApplicationProtocol.h"

#pragma mark - Shared application

NS_ASSUME_NONNULL_BEGIN

///
/// Platform-specific (here, iOS) shared application.
///
/// Renders OAuth flow and implements `DBSharedApplication` protocol.
///
@interface DBMobileSharedApplication : NSObject <DBSharedApplication>

///
/// Full constructor.
///
/// @param sharedApplication The `UIApplication` with which to render the OAuth flow.
/// @param controller The `UIViewController` with which to render the OAuth flow.
/// @param openURL A wrapper around app-extension unsafe `openURL` call.
///
/// @return An initialized instance.
///
- (instancetype)initWithSharedApplication:(UIApplication *)sharedApplication
                               controller:(UIViewController *)controller
                                  openURL:(void (^_Nonnull)(NSURL *))openURL;

+ (nullable DBMobileSharedApplication *)mobileSharedApplication;

+ (void)setMobileSharedApplication:(DBMobileSharedApplication *)mobileSharedApplication;

- (void)dismissAuthController;

@end

#pragma mark - Web view controller

///
/// Platform-specific (here, iOS) `UIViewController` for rendering OAuth flow.
///
@interface DBMobileSafariViewController : SFSafariViewController <SFSafariViewControllerDelegate>

- (instancetype)initWithUrl:(NSURL *)url cancelHandler:(DBOAuthCancelBlock)cancelHandler;

@end

NS_ASSUME_NONNULL_END
