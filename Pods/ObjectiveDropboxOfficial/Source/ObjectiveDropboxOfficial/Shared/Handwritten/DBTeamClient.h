///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBTeamBaseClient.h"

@class DBUserClient;
@class DBTransportDefaultConfig;

NS_ASSUME_NONNULL_BEGIN

///
/// Dropbox Business (Team) API Client for all endpoints with auth type "team".
///
/// This is the SDK user's primary interface with the Dropbox Business (Team) API. Routes can be accessed via each
/// "namespace" object in the instance fields of its parent, `DBUserBaseClient`. To see a full list of the Business
/// (Team) API endpoints available, please visit: https://www.dropbox.com/developers/documentation/http/teams.
///
@interface DBTeamClient : DBTeamBaseClient

/// Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects are each
/// associated with a particular Dropbox account.
@property (nonatomic, readonly, copy, nullable) NSString *tokenUid;

///
/// Convenience constructor.
///
/// Uses standard network configuration parameters.
///
/// @param accessToken The Dropbox OAuth 2.0 access token used to make requests.
///
/// @return An initialized instance.
///
- (instancetype)initWithAccessToken:(NSString *)accessToken;

///
/// Convenience constructor.
///
/// @param accessToken The Dropbox OAuth 2.0 access token used to make requests.
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// `DBTransportDefaultConfig` offers a number of different constructors to customize networking settings.
///
/// @return An initialized instance.
///
- (instancetype)initWithAccessToken:(NSString *)accessToken
                    transportConfig:(nullable DBTransportDefaultConfig *)transportConfig;

///
/// Full constructor.
///
/// @param accessToken The Dropbox OAuth 2.0 access token used to make requests.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// `DBTransportDefaultConfig` offers a number of different constructors to customize networking settings.
///
/// @return An initialized instance.
///
- (instancetype)initWithAccessToken:(NSString *)accessToken
                           tokenUid:(nullable NSString *)tokenUid
                    transportConfig:(nullable DBTransportDefaultConfig *)transportConfig;

///
/// Returns a `DBUserClient` instance that can be used to make API calls on behalf of the designated team member.
///
/// @note App must have "TeamMemberFileAccess" permissions to use this method.
///
/// @param memberId The Dropbox `account_id` of the team member to perform actions on behalf of. e.g.
/// "dbid:12345678910..."
///
/// @return An initialized User API client instance.
///
- (DBUserClient *)userClientWithMemberId:(NSString *)memberId;

///
/// Returns the current access token used to make API requests.
///
- (nullable NSString *)accessToken;

///
/// Returns whether the client is authorized.
///
/// @return Whether the client currently has a non-nil OAuth 2.0 access token.
///
- (BOOL)isAuthorized;

@end

NS_ASSUME_NONNULL_END
