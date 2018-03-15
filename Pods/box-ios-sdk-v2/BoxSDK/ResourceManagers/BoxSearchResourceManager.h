//
//  BoxSearchResourceManager.h
//  BoxSDK
//
//  Created on 8/5/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIResourceManager.h"

@class BoxSearchRequestBuilder;

/**
 * BoxSearchResourceManager allows you to search a user's account via the Box API. This class is
 * a concrete subclass of BoxAPIResourceManager. This class allows you to search a Box account
 * for content by filename and file contents.
 *
 * This class enables the following operations:
 *
 * - [Search a user's account](http://developers.box.com/docs/#search-searching-a-users-account)
 *
 */
@interface BoxSearchResourceManager : BoxAPIResourceManager

/** @name API calls */

/**
 * Create and enqueue a BoxAPIJSONOperation to perform a search across the currently
 * authenticated user's account.
 *
 * See the Box documentation for [searching a user's account](http://developers.box.com/docs/#search-searching-a-users-account)
 *
 * @param builder A BoxSearchRequestBuilder instance that contains query parameters and body data for the request.
 *   **Note**: Since this is a `GET` request, the builder's body will be ignored.
 * @param successBlock A callback that is triggered if the API call completes successfully.
 * @param failureBlock A callback that is triggered if the API call fails to complete successfully, This may include
 *   A connection failure, or an API related error. Refer to `BoxSDKErrors.h` for error codes.
 *
 * @return A BoxAPIJSONOperation configured to make the requested API call. This operation is already enqueued on
 *   [self.queueManager]([BoxAPIResourceManager queueManager]).
 */
- (BoxAPIJSONOperation *)searchWithBuilder:(BoxSearchRequestBuilder *)builder successBlock:(BoxCollectionBlock)successBlock failureBlock:(BoxAPIJSONFailureBlock)failureBlock;

@end
