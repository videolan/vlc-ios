//
//  BoxCommentsResourceManager.h
//  BoxSDK
//
//  Created on 11/21/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIResourceManager.h"

#import "BoxAPIJSONOperation.h"
#import "BoxComment.h"

@class BoxCommentsRequestBuilder;

typedef void (^BoxCommentBlock)(BoxComment *comment);

/**
 * BoxCommentsResourceManager allows you to access and manipulate comments via the Box API. This class is
 * a concrete subclass of BoxAPIResourceManager. This class allows you to manipulate [BoxComment]s
 * referred to by their `modelID`, which is an `NSString`.
 *
 * This class enables the following operations:
 *
 * - [Get Information About a Comment](http://developers.box.com/docs/#comments-get-information-about-a-comment )
 * - [Add a Comment to an Item](http://developers.box.com/docs/#comments-add-a-comment-to-an-item )
 * - [Change a Comment’s Message](http://developers.box.com/docs/#comments-change-a-comments-message )
 * - [Delete a Comment](http://developers.box.com/docs/#comments-delete-a-comment )
 *
 * Callbacks and typedefs
 * ======================
 * This class defines the `BoxCommentBlock` type for successful API calls that return a BoxComment object:
 *
 * <pre><code>typedef void (^BoxCommentBlock)(BoxComment *comment);</code></pre>
 */
@interface BoxCommentsResourceManager : BoxAPIResourceManager

/** @name API calls */

/**
 * Create and enqueue a BoxAPIJSONOperation to fetch the current comment's information.
 *
 * See the Box documentation for [Get Information About a Comment](http://developers.box.com/docs/#comments-get-information-about-a-comment )
 *
 * @param commentID The `modelID` of a BoxComment you wish to fetch information for.
 * @param builder A BoxCommentsRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `GET` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)commentInfoWithID:(NSString *)commentID requestBuilder:(BoxCommentsRequestBuilder *)builder success:(BoxCommentBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to create a new comment.
 *
 * See the Box documentation for [Add a Comment to an Item](http://developers.box.com/docs/#comments-add-a-comment-to-an-item ).
 *
 * @param builder A BoxCommentsRequestBuilder instance that contains query parameters and body data for the request.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)createCommentWithRequestBuilder:(BoxCommentsRequestBuilder *)builder success:(BoxCommentBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to edit a comment's information.
 *
 * See the Box documentation for [Change a Comment’s Message](http://developers.box.com/docs/#comments-change-a-comments-message ).
 *
 * @param commentID The `modelID` of a BoxComment you wish to fetch information for.
 * @param builder A BoxCommentsRequestBuilder instance that contains query parameters and body data for the request.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)editCommentWithID:(NSString *)commentID requestBuilder:(BoxCommentsRequestBuilder *)builder success:(BoxCommentBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;

/**
 * Create and enqueue a BoxAPIJSONOperation to delete an enterprise comment.
 *
 * See the Box documentation for [Delete a Comment](http://developers.box.com/docs/#comments-delete-a-comment ).
 *
 * @param commentID The `modelID` of a BoxComment you wish to fetch information for.
 * @param builder A BoxCommentsRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `DELETE` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)deleteCommentWithID:(NSString *)commentID requestBuilder:(BoxCommentsRequestBuilder *)builder success:(BoxSuccessfulDeleteBlock)successBlock failure:(BoxAPIJSONFailureBlock)failureBlock;
@end
