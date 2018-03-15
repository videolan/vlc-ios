//
//  BoxUsersResourceManager.h
//  BoxSDK
//
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIResourceManager.h"

#import "BoxAPIJSONOperation.h"
#import "BoxUser.h"
#import "BoxCollection.h"

extern NSString *const BoxAPIUserIDMe;

typedef void (^BoxUserBlock)(BoxUser *user);

@class BoxUsersRequestBuilder;

/**
 * BoxUsersResourceManager allows you to access and manipulate users via the Box API. This class is
 * a concrete subclass of BoxAPIResourceManager. This class allows you to manipulate [BoxUsers]([BoxUser])
 * referred to by their `modelID`, which is an `NSString`.
 *
 * This class enables the following operations:
 * (Besides most operations on the user himself, /users/me, all these operations requires the user to be
 *  an enterprise administrator)
 *
 * - [Get a user's information](http://developers.box.com/docs/#users-get-the-current-users-information)
 * - [Get All Users in an Enterprise](http://developers.box.com/docs/#users-get-all-the-users-in-an-enterprise)
 * - [Create an Enterprise User](http://developers.box.com/docs/#users-create-an-enterprise-user)
 * - [Update a User’s Information](http://developers.box.com/docs/#users-update-a-users-information)
 * - [Delete an Enterprise User](http://developers.box.com/docs/#users-delete-an-enterprise-user)
 *
 * Callbacks and typedefs
 * ======================
 * This class defines the `BoxUserBlock` type for successful API calls that return a BoxUser object:
 *
 * <pre><code>typedef void (^BoxUserBlock)(BoxUser *user);</code></pre>
 *
 * Constants
 * =========
 * This class exposes one additional constant:
 *
 * - `BoxAPIUserIDMe`, for referring to the current user.
 */
@interface BoxUsersResourceManager : BoxAPIResourceManager

/** @name API calls */

/**
 * Create and enqueue a BoxAPIJSONOperation to fetch the current user's information.
 *
 * See the Box documentation for [getting a user's information](http://developers.box.com/docs/#users-get-the-current-users-information)
 *
 * Using `BoxAPIUserIDMe` as userId allows viewing information about the current user.
 *
 * @param userID The `modelID` of a BoxUser you wish to fetch information for.
 * @param builder A BoxUsersRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `GET` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)userInfoWithID:(NSString *)userID requestBuilder:(BoxUsersRequestBuilder *)builder success:(BoxUserBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to fetch all users in the current enterprise.
 *
 * See the Box documentation for [getting all users' informations in an enterprise](http://developers.box.com/docs/#users-get-all-the-users-in-an-enterprise)
 *
 * @param builder A BoxUsersRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `GET` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)userInfos:(BoxUsersRequestBuilder *)builder success:(BoxCollectionBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to create a new user.
 *
 * See the Box documentation for [Create an Enterprise User](http://developers.box.com/docs/#users-create-an-enterprise-user).
 *
 * @param builder A BoxUsersRequestBuilder instance that contains query parameters and body data for the request.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)createUserWithRequestBuilder:(BoxUsersRequestBuilder *)builder success:(BoxUserBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to edit a user's information.
 *
 * See the Box documentation for [editing a user's information](http://developers.box.com/docs/#users-update-a-users-information).
 *
 * @param userID The `modelID` of a BoxUser you wish to fetch information for.
 * @param builder A BoxUsersRequestBuilder instance that contains query parameters and body data for the request.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)editUserWithID:(NSString *)userID requestBuilder:(BoxUsersRequestBuilder *)builder success:(BoxUserBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to delete an enterprise user.
 *
 * See the Box documentation for [deleting a user](http://developers.box.com/docs/#users-delete-an-enterprise-user).
 *
 * @param userID The `modelID` of a BoxUser you wish to fetch information for.
 * @param builder A BoxUsersRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `DELETE` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)deleteUserWithID:(NSString *)userID requestBuilder:(BoxUsersRequestBuilder *)builder success:(BoxSuccessfulDeleteBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

@end
