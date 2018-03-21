///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"
#import "DBTransportBaseClient.h"

@class DBRequestError;
@class DBRoute;

NS_ASSUME_NONNULL_BEGIN

/// Used by internal classes of `DBTransportBaseClient`
@interface DBTransportBaseClient (Internal)

- (NSDictionary *)headersWithRouteInfo:(NSDictionary<NSString *, NSString *> *)routeAttributes
                           accessToken:(NSString *)accessToken
                         serializedArg:(NSString *)serializedArg;

- (NSDictionary *)headersWithRouteInfo:(NSDictionary<NSString *, NSString *> *)routeAttributes
                           accessToken:(NSString *)accessToken
                         serializedArg:(NSString *)serializedArg
                       byteOffsetStart:(nullable NSNumber *)byteOffsetStart
                         byteOffsetEnd:(nullable NSNumber *)byteOffsetEnd;

+ (NSMutableURLRequest *)requestWithHeaders:(NSDictionary *)httpHeaders
                                        url:(NSURL *)url
                                    content:(nullable NSData *)content
                                     stream:(nullable NSInputStream *)stream;

+ (NSURL *)urlWithRoute:(DBRoute *)route;

+ (NSData *)serializeDataWithRoute:(DBRoute *)route routeArg:(id<DBSerializable>)arg;

+ (NSString *)serializeStringWithRoute:(DBRoute *)route routeArg:(id<DBSerializable>)arg;

+ (nullable DBRequestError *)dBRequestErrorWithErrorData:(nullable NSData *)errorData
                                             clientError:(nullable NSError *)clientError
                                              statusCode:(int)statusCode
                                             httpHeaders:(nullable NSDictionary *)httpHeaders;

+ (nullable id)routeErrorWithRoute:(nullable DBRoute *)route data:(nullable NSData *)data statusCode:(int)statusCode;

+ (nullable id)routeResultWithRoute:(nullable DBRoute *)route
                               data:(nullable NSData *)data
                 serializationError:(NSError *_Nullable *_Nullable)serializationError;

+ (BOOL)statusCodeIsRouteError:(int)statusCode;

+ (nullable NSString *)caseInsensitiveLookupWithKey:(nullable NSString *)lookupKey
                                         dictionary:(NSDictionary<id, id> *_Nullable)dictionary;

+ (NSString *)sdkVersion;

+ (NSString *)defaultUserAgent;

@end

NS_ASSUME_NONNULL_END
