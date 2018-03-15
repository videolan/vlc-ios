///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

@class DBAccessToken;
@class DBOAuthResult;
@protocol DBSharedApplication;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Access token class

///
/// A Dropbox OAuth2 access token.
///
/// Stores a unique identifying key for storing in `DBKeychain`.
///
@interface DBAccessToken : NSObject

/// The OAuth2 access token.
@property (nonatomic, readonly, copy) NSString *accessToken;

/// The unique identifier of the access token used for storing in `DBKeychain`. Either the `account_id` (if user app) or
/// the `team_id` if (team app).
@property (nonatomic, readonly, copy) NSString *uid;

///
/// DBAccessToken full constructor.
///
/// @param accessToken The OAuth2 access token retrieved from the auth flow.
/// @param uid The unique identifier used to store in `DBKeychain`.
///
/// @return An initialized instance.
///
- (instancetype)initWithAccessToken:(NSString *)accessToken uid:(NSString *)uid;

@end

#pragma mark - OAuth manager base

///
/// Platform-neutral manager for performing OAuth linking.
///
/// @note OAuth flow webviews localize to environment locale.
///
///
@interface DBOAuthManager : NSObject {
@protected
  NSString *_appKey;
  NSURL *_redirectURL;
  NSURL *_cancelURL;
  NSString *_host;
  NSMutableArray<NSURL *> *_urls;
}

/// Sets the locale of the OAuth flow webpages. If `nil`, then defaults to device locale.
@property (nonatomic, strong) NSLocale *locale;

#pragma mark - Shared instance accessors and mutators

///
/// Accessor method for `DBOAuthManager` shared instance.
///
/// Shared instance is used to authenticate users through OAuth2, save access tokens, and retrieve access tokens.
///
/// @return The `DBOAuthManager` shared instance.
///
+ (nullable DBOAuthManager *)sharedOAuthManager;

///
/// Mutator method for `DBOAuthManager` shared instance.
///
/// Shared instance is used to authenticate users through OAuth2, save access tokens, and retrieve access tokens.
///
/// @param sharedOAuthManager The updated reference to the `DBOAuthManager` shared instance.
///
+ (void)setSharedOAuthManager:(DBOAuthManager *)sharedOAuthManager;

#pragma mark - Constructors

///
/// `DBOAuthManager` convenience constructor.
///
/// @param appKey The app key from the developer console that identifies this app.
///
/// @return An initialized instance.
///
- (instancetype)initWithAppKey:(NSString *)appKey;

///
/// `DBOAuthManager` full constructor.
///
/// @param appKey The app key from the developer console that identifies this app.
/// @param host The host of the OAuth web flow.
///
/// @return An initialized instance.
///
- (instancetype)initWithAppKey:(NSString *)appKey host:(NSString *)host;

#pragma mark - Auth flow methods

///
/// Commences the authorization flow (platform-neutral).
///
/// Interfaces with platform-specific rendering logic via the `DBSharedApplication` protocol.
///
///
/// @param sharedApplication A platform-neutral shared application abstraction for rendering auth flow.
///
- (void)authorizeFromSharedApplication:(id<DBSharedApplication>)sharedApplication;

///
/// Handles a redirect back into the application (from whichever auth flow was being used).
///
/// @param url The redirect URL to attempt to handle.
///
/// @return `nil` if SDK cannot handle the redirect URL, otherwise returns an instance of `DBOAuthResult`.
///
- (nullable DBOAuthResult *)handleRedirectURL:(NSURL *)url;

#pragma mark - Keychain methods

///
/// Saves an access token to the `DBKeychain` class.
///
/// @param accessToken The access token to save.
///
/// @return Whether the save operation succeeded.
///
- (BOOL)storeAccessToken:(DBAccessToken *)accessToken;

///
/// Utility function to return an arbitrary access token from the `DBKeychain` class, if any exist.
///
/// @return the "first" access token found, if any, otherwise nil.
///
- (nullable DBAccessToken *)retrieveFirstAccessToken;

///
/// Retrieves the access token for a particular user from the `DBKeychain` class.
///
/// @param tokenUid The uid of the access token to retrieve.
///
/// @return An access token if present, otherwise nil.
///
- (nullable DBAccessToken *)retrieveAccessToken:(NSString *)tokenUid;

///
/// Retrieves all stored access tokens from the `DBKeychain` class.
///
/// @return a dictionary mapping token uids to their access tokens.
///
- (NSDictionary<NSString *, DBAccessToken *> *)retrieveAllAccessTokens;

///
/// Checks if there are any stored access tokens in the `DBKeychain` class.
///
/// @return Whether there are stored access tokens.
///
- (BOOL)hasStoredAccessTokens;

///
/// Deletes a specific access tokens from the `DBKeychain` class.
///
/// @param tokenUid The uid of the access token to delete.
///
/// @return Whether the delete operation succeeded.
///
- (BOOL)clearStoredAccessToken:(NSString *)tokenUid;

///
/// Deletes all stored access tokens in the `DBKeychain` class.
///
/// @return Whether the batch deletion operation succeeded.
///
- (BOOL)clearStoredAccessTokens;

///
/// When YES users will not be able to sign up for a Dropbox account via the authorization page. Instead, the
/// authorization page will show a link to the Dropbox iOS app in the App Store. This is was originally intended for use
/// when necessary for compliance with App Store policies.
///
/// Default value is YES.
///
/// NOTE: Recent App Store policy suggests that sign up is now allowed, so it should be safe to enable signup. However
/// we are keeping the parameter and defaulting to YES to allow SDK users to make the appropriate decision for their
/// apps.
@property (nonatomic, assign) BOOL disableSignup;

@end

NS_ASSUME_NONNULL_END
