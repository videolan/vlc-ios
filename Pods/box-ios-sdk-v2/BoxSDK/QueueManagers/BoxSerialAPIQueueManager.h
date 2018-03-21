//
//  BoxSerialAPIQueueManager.h
//  BoxSDK
//
//  Created on 2/28/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIQueueManager.h"

/**
 * BoxSerialAPIQueueManager is an implementation of the abstract class BoxAPIQueueManager.
 * This queue manager allows only one concurrent operation at a time. This means that at any
 * given time, only one API call will be in progress.
 *
 * This class is intended to be used in conjunction with a BoxSerialOAuth2Session. Both classes
 * assume one concurrent BoxAPIOperation. This assumption enables the locking strategy with regard
 * to OAuth2 token refresh to be simplified. Whenever any BoxAPIOAuth2ToJSONOperation is enqueued,
 * it is added as a dependency to all currently enqueued operations as well as operations enqueued
 * before the OAuth2 operation completes.
 */
@interface BoxSerialAPIQueueManager : BoxAPIQueueManager

/** @name NSOperationQueues */

/**
 * The NSOperationQueue on which all BoxAPIOperations are enqueued. This queue is configured
 * with `maxConcurrentOperationCount = 1`.
 */
@property (nonatomic, readwrite, strong) NSOperationQueue *globalQueue;

/** @name Designated initializer */

/**
 * In addition to calling super, this method sets `globalQueue.maxConcurrentOperationCount` to `1`
 * @param OAuth2Session This object is needed for locking
 */
- (id)initWithOAuth2Session:(BoxOAuth2Session *)OAuth2Session;

/** @name Enqueue Operations */

/**
 * Enqueues operation on globalQueue to be executed. This method calls [BoxAPIQueueManager enqueueOperation:].
 *
 * This method synchronizes on OAuth2Session.
 *
 * @param operation The BoxAPIOperation to be enqueued for execution
 */
- (BOOL)enqueueOperation:(BoxAPIOperation *)operation;

@end
