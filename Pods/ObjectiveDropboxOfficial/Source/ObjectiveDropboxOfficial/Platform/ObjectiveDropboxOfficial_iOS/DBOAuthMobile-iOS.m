///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBOAuthMobile-iOS.h"
#import "DBOAuthManager.h"
#import "DBSDKSystem.h"

#pragma mark - Shared application

static DBMobileSharedApplication *s_mobileSharedApplication;

@implementation DBMobileSharedApplication {
  UIApplication *_sharedApplication;
  UIViewController *_controller;
  void (^_openURL)(NSURL *);
}

+ (DBMobileSharedApplication *)mobileSharedApplication {
  return s_mobileSharedApplication;
}

+ (void)setMobileSharedApplication:(DBMobileSharedApplication *)mobileSharedApplication {
  s_mobileSharedApplication = mobileSharedApplication;
}

- (instancetype)initWithSharedApplication:(UIApplication *)sharedApplication
                               controller:(UIViewController *)controller
                                  openURL:(void (^)(NSURL *))openURL {
  self = [super init];
  if (self) {
    // fields saved for app-extension safety
    _sharedApplication = sharedApplication;
    _controller = controller;
    _openURL = openURL;
  }
  return self;
}

- (void)presentErrorMessage:(NSString *)message title:(NSString *)title {
  if (_controller) {
    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:(UIAlertControllerStyle)UIAlertControllerStyleAlert];
    [_controller presentViewController:alertController
                              animated:YES
                            completion:^{
                              [NSException raise:@"FatalError" format:@"%@", message];
                            }];
  }
}

- (void)presentErrorMessageWithHandlers:(NSString *)message
                                  title:(NSString *)title
                         buttonHandlers:(NSDictionary<NSString *, void (^)(void)> *)buttonHandlers {
  UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:(UIAlertControllerStyle)UIAlertControllerStyleAlert];

  [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancels the current window.")
                                                      style:(UIAlertActionStyle)UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction *action) {
#pragma unused(action)
                                                      void (^handler)(void) = buttonHandlers[@"Cancel"];

                                                      if (handler != nil) {
                                                        handler();
                                                      }
                                                    }]];
  [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", @"Retries the previous action.")
                                                      style:(UIAlertActionStyle)UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
#pragma unused(action)
                                                      void (^handler)(void) = buttonHandlers[@"Retry"];

                                                      if (handler != nil) {
                                                        handler();
                                                      }
                                                    }]];

  if (_controller) {
    [_controller presentViewController:alertController
                              animated:YES
                            completion:^{
                            }];
  }
}

- (BOOL)presentPlatformSpecificAuth:(NSURL *)authURL {
  [self presentExternalApp:authURL];
  return YES;
}

- (void)presentAuthChannel:(NSURL *)authURL cancelHandler:(DBOAuthCancelBlock)cancelHandler {
  if (_controller) {
    DBMobileSafariViewController *safariViewController =
        [[DBMobileSafariViewController alloc] initWithUrl:authURL cancelHandler:cancelHandler];
    [_controller presentViewController:safariViewController animated:YES completion:nil];
  }
}

- (void)presentExternalApp:(NSURL *)url {
  _openURL(url);
}

- (BOOL)canPresentExternalApp:(NSURL *)url {
  return [_sharedApplication canOpenURL:url];
}

- (void)dismissAuthController {
  if (_controller != nil) {
    if (_controller.presentedViewController != nil && _controller.presentedViewController.isBeingDismissed == NO &&
        [_controller.presentedViewController isKindOfClass:[DBMobileSafariViewController class]]) {
      [_controller dismissViewControllerAnimated:YES completion:nil];
    }
  }
}

@end

#pragma mark - Web view controller

@implementation DBMobileSafariViewController {
  DBOAuthCancelBlock _cancelHandler;
}

- (instancetype)initWithUrl:(NSURL *)url cancelHandler:(DBOAuthCancelBlock)cancelHandler {
  if (self = [super initWithURL:url]) {
    _cancelHandler = cancelHandler;
    self.delegate = self;
  }
  return self;
}

- (void)dealloc {
  self.delegate = nil;
}

- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
  if (!didLoadSuccessfully) {
    [controller dismissViewControllerAnimated:true completion:nil];
  }
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
#pragma unused(controller)
  _cancelHandler();
}

@end
