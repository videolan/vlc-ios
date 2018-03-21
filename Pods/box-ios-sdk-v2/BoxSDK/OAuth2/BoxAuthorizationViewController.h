//
//  BoxAuthorizationViewController.h
//  BoxSDK
//
//  Created on 2/20/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BoxAuthorizationViewControllerDelegate;

/**
 * BoxAuthorizationViewController is a UIViewController that displays a UIWebview
 * that loads the OAuth2 authorize URL. An app may present this view controller to
 * log a user in to Box.
 *
 * This view controller also has extra logic to handle various Single Sign-ON (SSO)
 * configurations which require special handling beyond what a web view provides.
 * SSO is a session/user authentication process that allows a user to provide his
 * or her credentials once in order to access multiple applications. It is widely
 * used by corporations and institutions to secure and simplify the authentication
 * process for their users.
 *
 * **Important**: This controller performs valuable cookie-related operations on deallocation,
 * as such it should not be kept it memory after it is dismissed.
 *
 * @warning This is the only part of the Box SDK that is specific to iOS. If you wish to
 *   include the Box SDK in an OS X project, remove this source file.
 */
@interface BoxAuthorizationViewController : UIViewController <UIWebViewDelegate, NSURLConnectionDataDelegate, UIAlertViewDelegate>

/** @name Delegate */

/**
 * The object that acts as the delegate of the receiving authorization view controller.
 */
@property (nonatomic, readwrite, weak) id<BoxAuthorizationViewControllerDelegate> delegate;

/** @name Initializers */

/**
 * Designated initializer.
 * @param authorizationURL The authorization URL to load
 * @param redirectURI The OAuth2 redirect URI string, used to detect the OAuth2
 *   redirect URL and make sure the redirection happens correctly
 */
- (id)initWithAuthorizationURL:(NSURL *)authorizationURL redirectURI:(NSString *)redirectURI;

@end

/**
 * The BoxAuthorizationViewControllerDelegate protocol defines methods that your delegate
 * object must implement to interact with the authorization interface. The methods of this
 * protocol notify your delegate when the authorization web view starts and stops loading
 * content, or the user cancels the authorization operation.
 *
 * The delegate methods are responsible for showing any progress UI (such as a
 * UIActivityIndicatorView) and dismissing the controller when the operation is canceled.
 * To dismiss the controller, call the dismissViewControllerAnimated:completion: method
 * of the presenting controller responsible for displaying the BoxAuthorizationViewController
 * object.
 */
@protocol BoxAuthorizationViewControllerDelegate <NSObject>

/** @name Loading Content */

/**
 * Sent after the autorization view controller's web view starts loading a new frame.
 * @param authorizationViewController The authorization view controller whose web view has begun loading a new frame
 */
- (void)authorizationViewControllerDidStartLoading:(BoxAuthorizationViewController *)authorizationViewController;

/**
 * Sent after the autorization view controller's web view finishes loading a frame.
 * @param authorizationViewController The authorization view controller whose web view has finished loading
 */
- (void)authorizationViewControllerDidFinishLoading:(BoxAuthorizationViewController *)authorizationViewController;

@optional

/** @name Closing the Authorization View Controller */

/**
 * Tells the delegate that the user cancelled the authorization operation.
 *
 * Your delegate’s implementation of this method should dismiss the authorization view by calling the
 * dismissViewControllerAnimated:completion: method of the presenting view controller.
 *
 * @param authorizationViewController The authorization view controller object managing the authorization process
 */
- (void)authorizationViewControllerDidCancel:(BoxAuthorizationViewController *)authorizationViewController;

/**
 * Asks the delegate whether the view controller should load the OAuth2 redirect URL in the web view.
 *
 * If the delegate does not implement this method, the default is YES.
 *
 * If you wish to support iOS 5, you should implement this method and handle the OAuth2 redirect
 * URL in it. Web views on iOS 5 do not support loading custom URL schemes.
 *
 * @param authorizationViewController The authorization view controller object managing the authorization process
 * @param request The OAuth2 redirect URL request which the authorization web view is requesting to load
 *
 * @return YES if the redirect URL should be loaded, NO if it should not be.
 */
- (BOOL)authorizationViewController:(BoxAuthorizationViewController *)authorizationViewController shouldLoadReceivedOAuth2RedirectRequest:(NSURLRequest *)request;

@end
