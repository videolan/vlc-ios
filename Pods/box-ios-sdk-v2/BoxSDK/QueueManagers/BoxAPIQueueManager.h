//
//  BoxAPIQueueManager.h
//  BoxSDK
//
//  Created on 2/28/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BoxAPIOperation, BoxOAuth2Session, BoxAPIOAuth2ToJSONOperation;

/**
 * BoxAPIQueueManager is an abstract class you can use to encapsulate the enqueueing and running
 * of BoxAPIOperation instances. Because this class is abstract, you should not instantiate it
 * directly. You can either use the provided BoxSerialAPIQueueManager or implement your
 * own subclass (see subclassing notes). This class does not enforce its abstractness, but it does
 * not place any operations enqueued via enqueueOperation: into an NSOperationQueue, which means
 * that [BoxAPIOperations](BoxAPIOperation) will not get executed.
 *
 * Subclassing Notes
 * =================
 * Subclasses of BoxAPIQueueManager should override enqueueOperation:. It is important to call
 * this method's super in subclasses because the implementation in BoxAPIQueueManager listens
 * for notifications from the OAuth2Session in order to help implement locking the queue for
 * BoxAPIOAuth2ToJSONOperation instances.
 *
 * Subclasses should ensure BoxAPIOAuth2ToJSONOperation instances are executed with the correct order
 * relative to other BoxAPIOperation instances. Subclasses should ensure that several refresh operations
 * are not executed at once; this has the potential to thrash the shared refresh token and cause a user
 * to become logged out.
 */
@interface BoxAPIQueueManager : NSObject

/**
 * OAuth2Session should be used by subclasses to ensure that multiple
 * refresh operations are not excecuted in parallel.
 *
 * This object is owned by the BoxSDK instance.
 */
@property (nonatomic, readwrite, weak) BoxOAuth2Session *OAuth2Session;

/**
 * The set of all currently enqueued or in flight BoxAPIOAuth2ToJSONOperation instances.
 * Subclasses should add these operations as dependencies of other, non-OAuth2 operations.
 *
 * This object is owned by the BoxSDK instance.
 */
@property (nonatomic, readwrite, strong) NSMutableSet *enqueuedOAuth2Operations;

/** @name Initializers */

/**
 * Designated initializer
 * @param OAuth2Session This object is needed for locking
 */
- (id)initWithOAuth2Session:(BoxOAuth2Session *)OAuth2Session;

/** @name Enqueue Operations */

/**
 * Set up this instance as an observer for notifications on operation if thew operation is a
 * BoxAPIOAuth2ToJSONOperation instance. Subclasses should enqueue operations received via this
 * method on an NSOperationQueue to be executed.
 *
 * This method synchronizes on OAuth2Session.
 *
 * @param operation The BoxAPIOperation to be enqueued for execution
 */
- (BOOL)enqueueOperation:(BoxAPIOperation *)operation;

/**
 * Add an operation as a dependency to another operation. This method should acquire
 * [BoxAPIOperation APIOperationGlobalLock] and ensure operation is not executing before
 * adding the dependency.
 *
 * @param dependency The operation to add as a dependency.
 * @param operation The operation to add the dependency to.
 *
 * @return YES if dependency was added, NO if the dependency was not added.
 */
- (BOOL)addDependency:(NSOperation *)dependency toOperation:(NSOperation *)operation;

@end
