//
//  BoxAPIJSONOperation.h
//  BoxSDK
//
//  Created on 2/26/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BoxAPIAuthenticatedOperation.h"

/**
 * BoxAPIJSONOperation is a concrete BoxAPIAuthenticatedOperation subclass. This operation
 * receives JSON responses from the Box API. It is also capable of sending JSON-encoded
 * request bodies.
 *
 * This class assumes the data it receives in response to an API call is JSON. Failure to
 * decode responses as valid JSON will result in an error.
 *
 * Notes on Copying
 * ================
 * Not all classes that inherit from BoxAPIJSONOperation can be copied. BoxAPIMultipartToJSONOperation
 * is one such class (it cannot be copied because it has NSStream properties).
 */
@interface BoxAPIJSONOperation : BoxAPIAuthenticatedOperation <NSCopying>

// All callbacks are executed on the same queue as the BoxAPIOperation they are associated with.
// If you wish to interact with the UI in a callback block, dispatch to the main queue in the
// callback block

/** @name Callbacks */

/**
 * Called when the API call completes successfully with a 2xx status code.
 *
 * **Note**: All callbacks are executed on the same queue as the BoxAPIOperation they are associated with.
 * If you wish to interact with the UI in a callback block, dispatch to the main queue in the
 * callback block.
 */
@property (nonatomic, readwrite, strong) BoxAPIJSONSuccessBlock success;

/**
 * Called when the API call returns an error with a non-2xx status code.
 *
 * **Note**: All callbacks are executed on the same queue as the BoxAPIOperation they are associated with.
 * If you wish to interact with the UI in a callback block, dispatch to the main queue in the
 * callback block.
 */
@property (nonatomic, readwrite, strong) BoxAPIJSONFailureBlock failure;

/**
 * Call success or failure depending on whether or not an error has occurred during the request.
 * @see success
 * @see failure
 */
- (void)performCompletionCallback;

/** @name JSON */

/**
 * The decoded JSON dictionary returned by the API. All Box API calls that return JSON
 * return JSON object literals (i.e.: `{}`). JSON object literals decode as NSDictionaries.
 *
 * @see processResponseData:
 */
@property (nonatomic, readwrite, strong) NSDictionary *responseJSON;

/**
 * Encode the body dictionary as JSON.
 *
 * This method generates an error if bodyDictionary cannot be JSON encoded.
 * The error code for this case is BoxSDKJSONErrorEncodeFailed.
 *
 * @param bodyDictionary Key value pairs to JSON encode.
 *
 * @return An NSData containing the bytes of encoded JSON.
 */
- (NSData *)encodeBody:(NSDictionary *)bodyDictionary;

/**
 * Attempt to decode data received from the API into a NSDictionary.
 *
 * All Box API calls that return JSON return object literals (i.e.: `{}`). This method
 * generates an error if data cannot be JSON decoded or if data does not decode
 * to an NSDictionary. The error codes for these cases are:
 *
 * - BoxSDKJSONErrorDecodeFailed
 * - BoxSDKJSONErrorUnexpectedType
 *
 * @param data The response data received from the API call.
 */
- (void)processResponseData:(NSData *)data;

@end
