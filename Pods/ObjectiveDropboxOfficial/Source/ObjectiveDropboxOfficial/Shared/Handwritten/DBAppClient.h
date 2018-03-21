///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBAppBaseClient.h"

@class DBTransportDefaultConfig;

NS_ASSUME_NONNULL_BEGIN

///
/// Dropbox API Client for all endpoints with auth type "app".
///
/// This is the SDK user's primary interface with the Dropbox API. Routes can be accessed via each "namespace" object in
/// the instance fields of its parent, `DBAppBaseClient`. To see a full list of the API endpoints available,
/// please visit: https://www.dropbox.com/developers/documentation/http/documentation.
///
@interface DBAppClient : DBAppBaseClient

///
/// Convenience constructor.
///
/// Uses standard network configuration parameters.
///
/// @param appKey The consumer app key associated with the app that is integrating with the Dropbox API. Here, app key
/// is used for querying endpoints that have "app auth" authentication type.
/// @param appSecret The consumer app secret associated with the app that is integrating with the Dropbox API. Here, app
/// key is used for querying endpoints that have "app auth" authentication type.
///
/// @return An initialized instance.
///
- (instancetype)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret;

///
/// Full constructor.
///
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// `DBTransportDefaultConfig` offers a number of different constructors to customize networking settings.
///
/// @return An initialized instance.
///
- (instancetype)initWithTransportConfig:(nullable DBTransportDefaultConfig *)transportConfig;

@end

NS_ASSUME_NONNULL_END
