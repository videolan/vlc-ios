//
//  BoxSDKErrors.h
//  BoxSDK
//
//  Created on 4/22/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

// The domain for error responses from API calls
extern NSString *const BoxSDKErrorDomain;

// A key for the userInfo dictionary to look up the underlying JSON error response from the API
extern NSString *const BoxJSONErrorResponseKey;

// The BoxSDK framework may also return other NSError objects from other dmains, such as
// * JSON parsing
// * NSURLError domain
// * NSStream errors that may arise during uploading and downloading


// BoxSDKAPIError codes result from an error response being returned by an API call.
typedef enum {
    // 202 Accepted: operation could not be completed at this time and is in progress
    BoxSDKAPIErrorAccepted = 202,
    // 4xx errors
    BoxSDKAPIErrorBadRequest = 400,
    BoxSDKAPIErrorUnauthorized = 401,
    BoxSDKAPIErrorForbidden = 403,
    BoxSDKAPIErrorNotFound = 404,
    BoxSDKAPIErrorMethodNotAllowed = 405,
    BoxSDKAPIErrorConflict = 409,
    BoxSDKAPIErrorPreconditionFailed = 412,
    BoxSDKAPIErrorRequestEntityTooLarge = 413,
    BoxSDKAPIErrorPreconditionRequired = 428,
    BoxSDKAPIErrorTooManyRequests = 429, // rate limit exceeded
    // 5xx errors
    BoxSDKAPIErrorInternalServerError = 500,
    BoxSDKAPIErrorInsufficientStorage = 507,
    // catchall error code
    BoxSDKAPIErrorUnknownStatusCode = 999
} BoxSDKAPIError;

typedef enum {
    BoxSDKJSONErrorDecodeFailed = 10000,
    BoxSDKJSONErrorEncodeFailed = 10001,
    BoxSDKJSONErrorUnexpectedType = 10002
} BoxSDKJSONError;

typedef enum {
    BoxSDKOAuth2ErrorAccessTokenExpired = 20000, // access token is expired. The failed request was reenqueued
    BoxSDKOAuth2ErrorAccessTokenExpiredOperationCannotBeReenqueued = 20001, // access token is expired and the operation cannot be reenqueued because it cannot be copied
    BoxSDKOAuth2ErrorAccessTokenExpiredOperationReachedMaxReenqueueLimit = 20002 // access token is expired and the operation cannot be reenqueued because it already has been reenqueued before
} BoxSDKOAuth2Error;

typedef enum {
    BoxSDKStreamErrorWriteFailed = 30000,
    BoxSDKStreamErrorReadFailed = 30001
} BoxSDKStreamError;
