///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///
/// Protocol implemented by platform-specific builds of the Obj-C SDK
/// for properly rendering the OAuth linking flow.
///
@protocol DBSharedApplication <NSObject>

typedef void (^DBOAuthCancelBlock)(void);

///
/// Presents a platform-specific error message, and halts the auth flow.
///
/// @param message String to display which describes the error.
/// @param title String to display which titles the error view.
///
- (void)presentErrorMessage:(NSString *)message title:(NSString *)title;

///
/// Presents a platform-specific error message, and halts the auth flow. Optional handlers may be provided for view
/// display buttons (mainly useful in the mobile case).
///
/// @param message String to display which describes the error.
/// @param title String to display which titles the error view.
/// @param buttonHandlers Map from button name to button handler.
///
- (void)presentErrorMessageWithHandlers:(NSString *)message
                                  title:(NSString *)title
                         buttonHandlers:(NSDictionary<NSString *, void (^)(void)> *)buttonHandlers;

///
/// Presents platform-specific authorization paths.
///
/// This method is called before more generic, platform-neutral auth methods. For example, in the mobile case, the Obj-C
/// SDK will use a direct authorization route with the Dropbox mobile app, if it is installed on the current device.
///
/// @param authURL Gateway url to commence auth flow.
///
- (BOOL)presentPlatformSpecificAuth:(NSURL *)authURL;

///
/// Presents platform-neutral auth flow.
///
/// @param authURL Gateway url to commence auth flow.
/// @param cancelHandler Handler for cancelling auth flow. Opens "cancel" url to signal cancellation.
///
- (void)presentAuthChannel:(NSURL *)authURL cancelHandler:(DBOAuthCancelBlock)cancelHandler;

///
/// Opens external app to handle url.
///
/// This method opens whichever app is registered to handle the type of the supplied url, and then passes the supplied
/// url into the newly opened app.
///
/// @param url Url to open with external app.
///
- (void)presentExternalApp:(NSURL *)url;

///
/// Checks whether there is an external app registered to open the url type.
///
/// @param url Url to check.
///
/// @return Whether there is an external app registered to open the url type.
///
- (BOOL)canPresentExternalApp:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
