//
//  BoxAPIOAuth2ToJSONOperation.h
//  BoxSDK
//
//  Created on 2/27/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIOperation.h"

// This notification is sent when a BoxAPIOAuth2ToJSONOperation completes with either success or failure
extern NSString *const BoxOAuth2OperationDidCompleteNotification;

/**
 * BoxAPIOAuth2ToJSONOperation is a concrete subclass of BoxAPIOperation. This operation makes unauthenticated
 * requests to the Box OAuth2 server to retrieve access and refresh tokens. This operation is used for the
 * [authorization code grant](http://tools.ietf.org/html/rfc6749#section-4.1) and
 * [refreshing an acess token](http://tools.ietf.org/html/rfc6749#section-6).
 *
 * NSNotifications
 * ===============
 * Upon success and failure, this operation will broadcast an `NSNotification` on the default notification
 * center of type `BoxOAuth2OperationDidCompleteNotification`. This notification is used by BoxAPIQueueManager to assist
 * in locking during token refresh requests. You may listen to this notification in addition to the other
 * notifications in BoxOAuth2Session to manager a user's logged in state in your app.
 */
@interface BoxAPIOAuth2ToJSONOperation : BoxAPIOperation

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

/**
 * The JSON decoded response from the API call.
 */
@property (nonatomic, readwrite, strong) NSDictionary *responseJSON;

/** @name Overridden methods */

/**
 * Encode bodyDictionary as www-form-urlencoded data.
 *
 * @param bodyDictionary The NSDictionary to encode.
 *
 * @return An NSData containing the bytes of the encoded representation.
 */
- (NSData *)encodeBody:(NSDictionary *)bodyDictionary;

/**
 * OAuth2 requests are unauthenticated; they carry the client id and client secret. This method performs no
 * action but is overridden to prevent `BOXAbstract` from causing runtime assertion failures.
 */
- (void)prepareAPIRequest;

/**
 * JSON decode the result of the API call.
 *
 * This method can cause [self.error]([BoxAPIOperation error]) to be set if data fails to JSON decode or if data is
 * valid JSON but does not decode to an NSDictionary, which is the expected behavior of
 * the Box OAuth2 API.
 *
 * @param data The data received from the API call.
 */
- (void)processResponseData:(NSData *)data;

@end
