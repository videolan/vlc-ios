///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBTransportBaseClient.h"
#import "DBTransportClientProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class DBTransportDefaultConfig;

///
/// The networking client for the User and Business API.
///
/// Normally, one networking client should instantiated per access token and session / background session pair. By
/// default, all Upload-style and Download-style requests are made via a background session (except when uploading via
/// `NSInputStream` or `NSData`, or downloading to `NSData`, in which case, it is not possible) and all RPC-style
/// request are made using a foreground session.
///
/// Requests are made via one of the request methods below. The request is launched, and a `DBTask` object is returned,
/// from which response and progress handlers can be added directly. By default, these handlers are added / executed
/// using the main thread queue and executed in a thread-safe manner (unless a custom delegate queue is supplied via the
/// `DBTransportDefaultConfig` object). An internal `DBDelegate` object then retrieves the appropriate handler and
/// executes it.
///
/// While response handlers are not optional, they do not necessarily need to have been installed by the time the SDK
/// has received its server response. If this is the case, completion data will be saved, and the handler will be
/// executed with the completion data upon its installation. Downloaded content will be moved from a temporary location
/// to the final destination when the response handler code is executed.
///
/// Argument serialization and deserialization is performed with this class.
///
@interface DBTransportDefaultClient : DBTransportBaseClient <DBTransportClient>

/// A serial delegate queue used for executing blocks of code that touch state shared across threads (mainly the request
/// handlers storage).
@property (nonatomic, readonly) NSOperationQueue *delegateQueue;

/// If set to true when the `DBTransportDefaultClient` object is initialized, all network requests are made on
/// foreground sessions (by default, most upload/download operations are performed with a background session). This is
/// appropriate for use cases where file upload / download operations will be quick, and immediate response is
/// preferable. Otherwise, for background sessions, uploads/downloads will essentially never time out, if network
/// connection is lost after the request has begun.
@property (nonatomic, readonly) BOOL forceForegroundSession;

/// The foreground session used to make all foreground requests (RPC style requests, upload from `NSData` and
/// `NSInputStream`, and download to `NSData`).
@property (nonatomic, strong) NSURLSession *session;

/// By default, the background session used to make all background requests (Upload and Download style requests, except
/// for upload from `NSData` and `NSInputStream`, and download to `NSData`) unless `forceForegroundSession` is set to
/// true, in which case, it is simply the same session as the foreground session.
@property (nonatomic, strong) NSURLSession *secondarySession;

/// The foreground session on which longpoll requests are made. Has a much longer timeout period than other sessions.
@property (nonatomic, strong) NSURLSession *longpollSession;

#pragma mark - Constructors

///
/// Full constructor.
///
/// @param accessToken The Dropbox OAuth2 access token used to make requests.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// `DBTransportDefaultConfig` offers a number of different constructors to customize networking settings.
///
/// @return An initialized instance.
///
- (instancetype)initWithAccessToken:(nullable NSString *)accessToken
                           tokenUid:(nullable NSString *)tokenUid
                    transportConfig:(nullable DBTransportDefaultConfig *)transportConfig;

///
/// Creates a transport config with the same settings as the current transport client, to be used to instantiate an
/// additional network client, to perform user API actions on behalf of other team members, by a team app.
///
/// @param asMemberId The Dropbox `account_id` of the team member to perform actions on behalf of. e.g.
/// "dbid:12345678910..."
///
/// @return A transport config with the same settings as the current transport client, except with information to
/// perform actions on behalf of the team member specified by `asMemberId`.
///
- (DBTransportDefaultConfig *)duplicateTransportConfigWithAsMemberId:(NSString *)asMemberId;

@end

NS_ASSUME_NONNULL_END
