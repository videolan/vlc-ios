///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

@class DBAccessToken;

NS_ASSUME_NONNULL_BEGIN

///
/// Union result type from OAuth linking attempt.
///
@interface DBOAuthResult : NSObject

#pragma mark - Tag type definition

/// The `DBAuthResultTag` enum type represents the possible tag states that the DBOAuthResult union can exist in.
typedef NS_ENUM(NSInteger, DBOAuthResultTag) {
  /// The authorization succeeded. Includes a `DBAccessToken`.
  DBAuthSuccess,

  /// The authorization failed. Includes an `OAuth2Error` and a descriptive message.
  DBAuthError,

  /// The authorization was manually canceled by the user.
  DBAuthCancel,
};

/// Represents the possible error types that can be returned from OAuth linking.
typedef NS_ENUM(NSInteger, DBOAuthErrorType) {
  /// The client is not authorized to request an access token using this method.
  DBAuthUnauthorizedClient,

  /// The resource owner or authorization server denied the request.
  DBAuthAccessDenied,

  /// The authorization server does not support obtaining an access token using
  /// this method.
  DBAuthUnsupportedResponseType,

  /// The requested scope is invalid, unknown, or malformed.
  DBAuthInvalidScope,

  /// The authorization server encountered an unexpected condition that prevented it from fulfilling the request.
  DBAuthServerError,

  /// The authorization server is currently unable to handle the request due to a temporary overloading or maintenance
  /// of the server.
  DBAuthTemporarilyUnavailable,

  /// Some other error (outside of the OAuth2 specification)
  DBAuthUnknown,
};

#pragma mark - Instance variables

/// Represents the `DBOAuthResult` object's current tag state.
@property (nonatomic, readonly) DBOAuthResultTag tag;

/// The access token that is retrieved in the event of a successful OAuth authorization.
/// @note Ensure the `isSuccess` method returns true before accessing, otherwise a runtime exception will be raised.
@property (nonatomic, readonly) DBAccessToken *accessToken;

/// The type of OAuth error that is returned in the event of an unsuccessful OAuth authorization.
/// @note Ensure the `isError` method returns true before accessing, otherwise a runtime exception will be raised.
@property (nonatomic, readonly) DBOAuthErrorType errorType;

/// The error description string associated with the `DBAuthErrorType` that is returned in the event of an unsuccessful
/// OAuth authorization.
/// @note Ensure the `isError` method returns true before accessing, otherwise a runtime exception will be raised.
@property (nonatomic, readonly, copy) NSString *errorDescription;

#pragma mark - Constructors

///
/// Initializes union class with tag state of "success".
///
/// @param accessToken The `DBAccessToken` (`account_id` / `team_id` and OAuth token pair) retrieved from the
/// authorization flow.
///
/// @return An initialized `DBOAuthResult` instance.
///
- (instancetype)initWithSuccess:(DBAccessToken *)accessToken;

///
/// Initializes union class with tag state of "error".
///
/// @param errorType The string identifier of the OAuth error type (lookup performed in errorTypeLookup dict).
/// @param errorDescription A short description of the error that occured during the authorization flow.
///
/// @return An initialized `DBOAuthResult` instance.
///
- (instancetype)initWithError:(NSString *)errorType errorDescription:(NSString *)errorDescription;

///
/// Initializes union class with tag state of "cancel".
///
/// @return An initialized `DBOAuthResult` instance.
///
- (instancetype)initWithCancel;

#pragma mark - Tag state methods

///
/// Retrieves whether the union's current tag state has value "success".
///
/// @return Whether the union's current tag state has value "success".
///
- (BOOL)isSuccess;

///
/// Retrieves whether the union's current tag state has value "error".
///
/// @return Whether the union's current tag state has value "error".
///
- (BOOL)isError;

///
/// Retrieves whether the union's current tag state has value "cancel".
///
/// @return Whether the union's current tag state has value "cancel".
///
- (BOOL)isCancel;

#pragma mark - Tag name method

///
/// Retrieves string value of union's current tag state.
///
/// @return A human-readable string representing the union's current tag
/// state.
///
- (NSString *)tagName;

#pragma mark - Description method

///
/// Description method.
///
/// @return A human-readable representation of the current object.
///
- (NSString *)description;

@end

NS_ASSUME_NONNULL_END
