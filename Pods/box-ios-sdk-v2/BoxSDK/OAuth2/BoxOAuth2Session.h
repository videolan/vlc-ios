//
//  BoxOAuth2Session.h
//  BoxSDK
//
//  Created on 2/19/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BoxAPIQueueManager.h"

// notifications
extern NSString *const BoxOAuth2SessionDidBecomeAuthenticatedNotification;
extern NSString *const BoxOAuth2SessionDidReceiveAuthenticationErrorNotification;
extern NSString *const BoxOAuth2SessionDidRefreshTokensNotification;
extern NSString *const BoxOAuth2SessionDidReceiveRefreshErrorNotification;

// keys for notification error info
extern NSString *const BoxOAuth2AuthenticationErrorKey;

/**
 * BoxOAuth2Session is an abstract class you can use to encapsulate managing a set of OAuth2
 * credentials, an access token and a refresh token. Because this class is abstract, you should
 * not instantiate it directly. You can either use the provided BoxSerialOAuth2Session or implement your
 * own subclass (see subclassing notes). This class does enforce its abstractness via calls to the
 * `BOXAbstract` macro, which will raise an `NSAssert` when `DEBUG=1`.
 *
 * This class provides support for the [Authorization Code Grant](http://tools.ietf.org/html/rfc6749#section-4.1)
 * and [refreshing an access token](http://tools.ietf.org/html/rfc6749#section-6). See
 * [RFC 6749](http://tools.ietf.org/html/rfc6749) for more information about the OAuth2 spec.
 *
 * The Authorization Code Grant requires a web view to allow the user to authenticate with Box and Authorize your
 * application. Upon successful authorization, the webview will launch a custom URL scheme. Your app must capture
 * this open in request in your App delegate and forward the URL to performAuthorizationCodeGrantWithReceivedURL:.
 *
 * NSNotifications
 * ===============
 * An OAuth2 session will issue the following notifications when the authorization state changes:
 *
 * - `BoxOAuth2SessionDidBecomeAuthenticatedNotification` upon successfully exchanging an authorization code for a
 *   set of tokens.
 * - `BoxOAuth2SessionDidReceiveAuthenricationErrorNotification` when the authorization code grant fails.
 * - `BoxOAuth2SessionDidRefreshTokensNotification` upon successfully refreshing an access token.
 * - `BoxOAuth2SessionDidReceiveRefreshErrorNotification` when a refresh attempt has failed (for example because
 *   the refresh token has been revoked or is expired).
 *
 * Subclassing Notes
 * =================
 * Subclasses must implement all abstract methods in this class. These include:
 *
 * - performAuthorizationCodeGrantWithReceivedURL:
 * - grantTokensURL
 * - authorizeURL
 * - redirectURIString
 * - performRefreshTokenGrant
 * - isAuthorized
 *
 * Service Settings on Box
 * =======================
 * **Note**: When setting up your service on Box, leave the OAuth2 reditrect URI blank.
 * The SDK will provide a custom redirect URI when issuing OAuth2 calls; doing so requires
 * that no redirect URI be set in your service settings.
 */
@interface BoxOAuth2Session : NSObject

/** @name SDK framework objects */

/**
 * The base URL for API requests. This property is used to construct OAuth2 URLs.
 * @see grantTokensURL
 * @see authorizeURL
 */
@property (nonatomic, readwrite, strong) NSString *APIBaseURLString;
/**
 * The BoxAPIQueueManager on which to enqueue [BoxAPIOAuth2ToJSONOperations](BoxAPIOAuth2ToJSONOperation).
 */
@property (nonatomic, readwrite, weak) BoxAPIQueueManager *queueManager;

/** @name Service settings */

/**
 * The client identifier described in [Section 2.2 of the OAuth2 spec](http://tools.ietf.org/html/rfc6749#section-2.2)
 *
 * This is also known as an API key on Box. See the [Box OAuth2 documentation](http://developers.box.com/oauth/) for
 * information on where to find this value.
 */
@property (nonatomic, readwrite, strong) NSString *clientID;

/**
 * The client secret. This value is used during the authorization code grant and when refreshing tokens.
 * This value should be a secret. DO NOT publish this value.
 *
 * See the [Box OAuth2 documentation](http://developers.box.com/oauth/) for
 * information on where to find this value.
 */
@property (nonatomic, readwrite, strong) NSString *clientSecret;

/** @name OAuth2 credentials */

/**
 * This token identifies a user on Box. This token is included in every request in the
 * Authorization header as a Bearer token. Access tokens expire 60 minutes from when they are issued.
 *
 * accessToken is never stored by the SDK. If you choose to persist the access token, do so in
 * secure storage such as the Keychain.
 *
 * An access token of `accesstoken` is transformed into the following Authorization header:
 *
 * <pre><code>Authorization: Bearer accesstoken</code></pre>
 *
 * @see addAuthorizationParametersToRequest:
 */
@property (nonatomic, readwrite, strong) NSString *accessToken;

/**
 * This token may be exchanged for a new access token and refresh token. Refresh tokens expire
 * 14 days from when they are issued.
 *
 * refreshToken is never stored by the SDK. If you choose to persis the access token, do so in
 * secure storage such as the Keychain.
 *
 * If a refresh token is expired, it cannot be exchanged for new tokens, and the user is effectively
 * logged out of Box.
 *
 * @see performRefreshTokenGrant:
 */
@property (nonatomic, readwrite, strong) NSString *refreshToken;

/**
 * When an access token is expected to expire. There is no guarantee the access token will be valid
 * until this date. Tokens may be revoked by a user at any time.
 */
@property (nonatomic, readwrite, strong) NSDate *accessTokenExpiration;

#pragma mark - Initialization
/** @name Initialization */

/**
 * Designated initializer. Returns a BoxOAuth2Session capable of authorizing a user and signing requests.
 *
 * @param ID your client ID, also known as API key.
 * @param secret your client secret. DO NOT publish this secret.
 * @param baseURL The base URL String for accessing the Box API.
 * @param queueManager The queue manager on which to enqueue [BoxAPIOAuth2ToJSONOperations](BoxAPIOAuth2ToJSONOperation).
 *
 * @return A BoxOAuth2Session capable of a  uthorizing a user and signing requests.
 */
- (id)initWithClientID:(NSString *)ID secret:(NSString *)secret APIBaseURL:(NSString *)baseURL queueManager:(BoxAPIQueueManager *)queueManager;

#pragma mark - Authorization
/** @name Authorization */

/**
 * Exchange an authorization code for an access token and a refresh token.
 * 
 * This method should send the `BoxOAuth2SessionDidBecomeAuthenticatedNotification` notification when an
 * authorization code is successfully exchanged for an access token and a refresh
 * token.
 * 
 * This method should send the `BoxOAuth2SessionDidReceiveAuthenricationErrorNotification` notification
 * if an authorization code is not obtained from the authorization webview flow
 * (for example if the user denies authorizing your application).
 *
 * @param URL The URL received as a result of the OAuth2 server invoking the redirect URI. This URL will
 * contain query string params needed to complete the authorization_code grant type.
 *
 * @warning This method is intended to be called from your application delegate in response to
 * `application:openURL:sourceApplication:annotation:`.
 */
- (void)performAuthorizationCodeGrantWithReceivedURL:(NSURL *)URL;

/**
 * Returns the URL to POST to for exchanging an authorization code or refresh token for a new set of tokens.
 * @return The URL to POST to for exchanging an authorization code or refresh token for a new set of tokens.
 */
- (NSURL *)grantTokensURL;

/**
 * Returns the URL to load in a webview to start the authentication and authorization flow with Box.
 * @return The URL to load in a webview to start the authentication and authorization flow with Box.
 */
- (NSURL *)authorizeURL;

/**
 * Returns a string containing the URI to load after the user completes the webview authorization flow.
 * This URI allows Box to redirect back to your app with an authorization code.
 *
 * @warning This should be a custom url scheme registered to your app.
 * @warning Do not register a redirect URI in the Box developer settings pages.
 *
 * @return Redirect URI string
 */
- (NSString *)redirectURIString;

#pragma mark - Token Refresh
/** @name Token Refresh */

/**
 * This method exchanges a refresh token for a new access token and refresh token.
 *
 * This method may be called automatically by the SDK framework upon a failed API call.
 *
 * This method should send the `BoxOAuth2SessionDidRefreshTokensNotification` notification upon successfully
 * exchanging a refresh token for a new access token and refresh token.
 *
 * This method should send the `BoxOAuth2SessionDidReceiveRefreshErrorNotification` notification if a refresh
 * token cannot be exchanged for a new set of tokens (for example if it has been revoked or is expired)
 *
 * @param expiredAccessToken The access token that expired.
 */
- (void)performRefreshTokenGrant:(NSString *)expiredAccessToken;

#pragma mark - Logout
/** @name Logout */

/**
 * Logs the user out and sets the access and refresh token to invalid_token
 *
 * @warning when you call this method delete any saved tokens in your keychain
 *
 * @see accessToken
 */

- (void)logout;

#pragma mark - Session info
/** @name Session Information */

/**
 * Compares accessTokenExpiration to the current time to determine if an access token may be valid.
 *
 * This is not a guarantee that an access token is valid as it may have been revoked or already refreshed.
 *
 * @return A BOOL indicating whether the access token may be valid.
 */
- (BOOL)isAuthorized;

#pragma mark - Request Authorization
/** @name Request Signing */

/**
 * Add the Authorization header to a request.
 *
 * @param request the API request that should be modified with an Authorization header and Bearer token
 *
 * @see accessToken
 */
- (void)addAuthorizationParametersToRequest:(NSMutableURLRequest *)request;

@end
