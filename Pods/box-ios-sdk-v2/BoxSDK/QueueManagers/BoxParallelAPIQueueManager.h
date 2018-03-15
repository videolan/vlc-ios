//
//  BoxParallelAPIQueueManager.h
//  BoxSDK
//
//  Created on 5/11/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIQueueManager.h"

/**
 * BoxParallelAPIQueueManager is an implementation of the abstract class BoxAPIQueueManager.
 * This queue manager allows many concurrent operations at a time. This means that at any
 * given time, only many API calls may be in progress.
 *
 * BoxParallelAPIQueueManager is intended to be used in conjunction with a BoxParallelOAuth2Session.
 * Both classes assume many concurrent [BoxAPIOperations]([BoxAPIOperation])s. To ensure that the
 * tokens will not get thrashed by concurrent refreshes of the same token, BoxParallelOAuth2Session
 * stores a set of all access tokens that have triggered a token refresh. All BoxAPIOperation instances
 * hold a copy of the token they were signed with and pass that to the OAuth2 session when attempting a
 * refresh. This prevents multiple refresh attempts from the same set of tokens.
 *
 * BoxParallelAPIQueueManager allows 10 concurrent download operations, 10 concurrent upload operations
 * and 1 concurrent operation for all other API calls.
 */
@interface BoxParallelAPIQueueManager : BoxAPIQueueManager

/** @name NSOperationQueues */

/**
 * The NSOperationQueue on which all BoxAPIOperations other than uploads
 * and downloads are enqueued. This queue is configured
 * with `maxConcurrentOperationCount = 1`.
 */
@property (nonatomic, readwrite, strong) NSOperationQueue *globalQueue;

/**
 * The NSOperationQueue on which all BoxAPIDataOperations 
 * are enqueued. This queue is configured
 * with `maxConcurrentOperationCount = 10`.
 */
@property (nonatomic, readwrite, strong) NSOperationQueue *downloadsQueue;

/**
 * The NSOperationQueue on which all BoxAPIMultipartToJSONOperations
 * are enqueued. This queue is configured
 * with `maxConcurrentOperationCount = 10`.
 */
@property (nonatomic, readwrite, strong) NSOperationQueue *uploadsQueue;

/** @name Designated initializer */

/**
 * In addition to calling super, this method sets `globalQueue.maxConcurrentOperationCount` to `1`
 * @param OAuth2Session This object is needed for locking
 */
- (id)initWithOAuth2Session:(BoxOAuth2Session *)OAuth2Session;

/** @name Enqueue Operations */

/**
 * Enqueues operation to be executed. This method calls [BoxAPIQueueManager enqueueOperation:].
 *
 * This method synchronizes on OAuth2Session.
 *
 * @param operation The BoxAPIOperation to be enqueued for execution
 */
- (BOOL)enqueueOperation:(BoxAPIOperation *)operation;


@end
