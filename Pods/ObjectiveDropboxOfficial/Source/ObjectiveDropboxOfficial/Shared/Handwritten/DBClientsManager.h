///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBHandlerTypes.h"

@class DBUserClient;
@class DBTeamClient;
@class DBTransportDefaultConfig;
@class DBOAuthResult;

NS_ASSUME_NONNULL_BEGIN

///
/// Dropbox Clients Manager.
///
/// This is a convenience class for typical integration cases.
///
/// To use this class, see details in the tutorial at:
/// https://github.com/dropbox/dropbox-sdk-obj-c/blob/master/README.md.
///
@interface DBClientsManager : NSObject

///
/// Accessor method for the current Dropbox API consumer app key.
///
/// @return The app key of the current Dropbox API app.
///
+ (nullable NSString *)appKey;

///
/// Accessor method for the authorized `DBUserClient` shared instance.
///
/// @return The authorized `DBUserClient` shared instance.
///
+ (nullable DBUserClient *)authorizedClient;

///
/// Multi-Dropbox account use case. Returns all current Dropbox user clients.
///
/// @return Mapping of `tokenUid` (account ID) to authorized `DBUserClient` instance.
///
+ (NSDictionary<NSString *, DBUserClient *> *)authorizedClients;

///
/// Accessor method for the authorized `DBTeamClient` shared instance.
///
/// @return The the authorized `DBTeamClient` shared instance.
///
+ (nullable DBTeamClient *)authorizedTeamClient;

///
/// Multi-Dropbox account use case. Returns all current Dropbox team clients.
///
/// @return Mapping of `tokenUid` (account ID) to authorized `DBTeamClient` instance.
///
+ (NSDictionary<NSString *, DBTeamClient *> *)authorizedTeamClients;

///
/// Multi-Dropbox account use case. Creates and stores a new shared authorized user client instance with the access
/// token retrieved from storage via the supplied `tokenUid` key.
///
/// @param tokenUid The uid of the stored access token to use to reauthorize. This uid is returned after a successful
/// progression through the OAuth flow (via `handleRedirectURL:`) in the `DBAccessToken` field of the `DBOAuthResult`
/// object.
///
/// @returns Whether a valid token exists in storage for the supplied `tokenUid`.
///
+ (BOOL)authorizeClientFromKeychain:(nullable NSString *)tokenUid;

///
/// Multi-Dropbox account use case. Creates and stores a new shared authorized team client instance with the access
/// token retrieved from storage via the supplied `tokenUid` key.
///
/// @param tokenUid The uid of the stored access token to use to reauthorize. This uid is returned after a successful
/// progression through the OAuth flow (via `handleRedirectURLTeam:`) in the `DBAccessToken` field of the
/// `DBOAuthResult` object.
///
/// @returns Whether a valid token exists in storage for the supplied `tokenUid`.
///
+ (BOOL)authorizeTeamClientFromKeychain:(nullable NSString *)tokenUid;

///
/// Handles launching the SDK with a redirect url from an external source to authorize a user API client.
///
/// Used after OAuth authentication has completed. A `DBUserClient` instance is initialized and the response access
/// token is saved in the `DBKeychain` class.
///
/// @param url The auth redirect url which relaunches the SDK.
///
/// @return The `DBOAuthResult` result from the authorization attempt.
///
+ (nullable DBOAuthResult *)handleRedirectURL:(NSURL *)url;

///
/// Handles launching the SDK with a redirect url from an external source to authorize a team API client.
///
/// Used after OAuth authentication has completed. A `DBTeamClient` instance is initialized and the response access
/// token is saved in the `DBKeychain` class.
///
/// @param url The auth redirect url which relaunches the SDK.
///
/// @return The `DBOAuthResult` result from the authorization attempt.
///
+ (nullable DBOAuthResult *)handleRedirectURLTeam:(NSURL *)url;

///
/// Multi-Dropbox account use case. Sets to `nil` the active user / team shared authorized client, clears the stored
/// access token associated with the supplied `tokenUid`, and removes the assocaited client from the shared clients
/// list.
///
/// @param tokenUid The uid of the token to clear.
///
+ (void)unlinkAndResetClient:(NSString *)tokenUid;

///
/// Sets to `nil` the active user / team shared authorized client and clears all stored access tokens in `DBKeychain`.
///
+ (void)unlinkAndResetClients;

///
/// Checks if performing an API v1 OAuth 1 token migration is necessary, and if so, performs it.
///
/// This method should successfully migrate all stored access tokens in the official Dropbox Core and Sync SDKs from
/// April 2012 until present, for both iOS and OS X. The method executes its network requests off the main thread.
///
/// Token migration is treated as an atomic operation. Either all tokens that are possible to migrate are migrated at
/// once, or none of them are. If all token conversion requests complete successfully, then the `shouldRetry` argument
/// in `responseBlock` will be `NO`. If some token conversion requests succeed and some fail, and if the failures are
/// for any reason other than network connectivity issues (e.g. token has been invalidated), then the migration will
/// continue normally, and those tokens that were unsuccessfully migrated will be skipped, and `shouldRetry` will be
/// `NO`. If any of the failures were because of network connectivity issues, none of the tokens will be migrated, and
/// `shouldRetry` will be `YES`.
///
/// @param responseBlock The custom handler for determining whether to retry the migration.
/// @param queue The operation queue on which to execute the supplied response block (defaults to main queue, if `nil`).
/// @param appKey The consumer app key associated with the app that is integrating with the Dropbox API. Here, app key
/// is used for querying endpoints that have "app auth" authentication type.
/// @param appSecret The consumer app secret associated with the app that is integrating with the Dropbox API. Here, app
/// key is used for querying endpoints that have "app auth" authentication type.
///
/// @return Whether a token migration will be performed.
///
+ (BOOL)checkAndPerformV1TokenMigration:(DBTokenMigrationResponseBlock)responseBlock
                                  queue:(nullable NSOperationQueue *)queue
                                 appKey:(NSString *)appKey
                              appSecret:(NSString *)appSecret;

@end

NS_ASSUME_NONNULL_END
