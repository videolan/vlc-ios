//
//  BoxAPIAuthenticatedOperation.h
//  BoxSDK
//
//  Created on 2/27/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIOperation.h"

// @TODO: Fill in Error Conditions header

/**
 * BoxAPIAuthenticatedOperation is an abstract base class for all API operations that
 * require authentication with Box. Because this class is abstract, you should not instantiate
 * it directly. Instead, use one of its subclasses:
 *
 * - BoxAPIJSONOperation
 * - BoxAPIMultipartToJSONOperation
 * - BoxAPIDataOperation
 *
 * This class encapsulates logic for handling expired access tokens. If an access token is found
 * to be expired, instances will request an attempt to refresh the OAuth2 tokens and will attempt
 * to reenqueue the failed operation.
 *
 * Error Conditions
 * ================
 * ...
 *
 * @warning Only members of the class BoxAPIJSONOperation may be reenqueued. Neither
 * BoxAPIMultipartToJSONOperation nor BoxAPIDataOperation instances may be reenqueued because they
 * contain properties that cannot be copied (subclasses of NSStream).
 */
@interface BoxAPIAuthenticatedOperation : BoxAPIOperation

/** @name OAuth2 expiration and refresh */

/**
 * The number of times an operation has been reenqueued. This class
 * will only attempt to reenqueue failed operations once before failing
 * permanenetly.
 *
 * @see handleExpiredOAuth2Token
 * @see connection:didReceiveResponse:
 */
@property (nonatomic, readwrite, assign) NSUInteger timesReenqueued;

/**
 * Checks for the presense of a WWW-Authenticate header with the error reason
 * `error="invalid_token"` which indicates that the token is invalid and potentially expired.
 *
 * @return A BOOL indicating if the token is expired.
 */
- (BOOL)isOAuth2TokenExpired;

/**
 * Have [self.OAuth2Session]([BoxAPIOperation OAuth2Session]) issue a BoxAPIOAuth2ToJSONOperation
 * to refresh the access token.
 */
- (void)handleExpiredOAuth2Token;

/** @name Request signing */

/**
 * Modify [self.APIRequest]([BoxAPIOperation APIRequest]) to contain authentication information
 * in the form of an Authorization header with a Bearer token.
 *
 * This is delayed as long as possible to ensure that the OAuth2
 * session is not stale by the time this operation makes it through
 * whatever queue it is in.
 *
 * @see [BoxOAuth2Session addAuthorizationParametersToRequest:]
 */
- (void)prepareAPIRequest;


@end
