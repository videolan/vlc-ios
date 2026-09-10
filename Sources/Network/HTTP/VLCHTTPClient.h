/*****************************************************************************
 * VLCHTTPClient.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const VLCHTTPClientErrorDomain;
extern NSString *const VLCHTTPClientResponseBodyErrorKey;

typedef void (^VLCHTTPClientSuccessBlock)(NSDictionary *jsonResponse);
typedef void (^VLCHTTPClientFailureBlock)(NSError *error);

@interface VLCHTTPClient : NSObject

- (instancetype)initWithBaseURL:(NSURL *)baseURL NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) NSURL *baseURL;
@property (readwrite, copy) NSString *userAgent;

- (NSURLSessionDataTask *)performRequestWithMethod:(NSString *)method
                                              path:(NSString *)path
                                        parameters:(nullable NSDictionary *)parameters
                                           headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                                           success:(nullable VLCHTTPClientSuccessBlock)success
                                           failure:(nullable VLCHTTPClientFailureBlock)failure;

- (NSURLSessionDataTask *)GET:(NSString *)path
                   parameters:(nullable NSDictionary *)parameters
                      headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                      success:(nullable VLCHTTPClientSuccessBlock)success
                      failure:(nullable VLCHTTPClientFailureBlock)failure;

- (NSURLSessionDataTask *)POST:(NSString *)path
                    parameters:(nullable NSDictionary *)parameters
                       headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                       success:(nullable VLCHTTPClientSuccessBlock)success
                       failure:(nullable VLCHTTPClientFailureBlock)failure;

- (NSURLSessionDataTask *)DELETE:(NSString *)path
                      parameters:(nullable NSDictionary *)parameters
                         headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                         success:(nullable VLCHTTPClientSuccessBlock)success
                         failure:(nullable VLCHTTPClientFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
