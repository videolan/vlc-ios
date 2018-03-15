//
//  BoxAPIQueueManager.m
//  BoxSDK
//
//  Created on 2/28/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIQueueManager.h"

#import "BoxAPIOperation.h"
#import "BoxAPIOAuth2ToJSONOperation.h"
#import "BoxLog.h"

/**
 * This internal extension provides a notification callback for completed
 * [BoxAPIOAuth2ToJSONOperations](BoxAPIOAuth2ToJSONOperation).
 */
@interface BoxAPIQueueManager ()

/** @name BoxAPIQueueManager() methods */

/**
 * This method listens for notifications of type `BoxOAuth2OperationDidComplete` received from
 * [BoxAPIOAuth2ToJSONOperations](BoxAPIOAuth2ToJSONOperation) that indicate these
 * operations have completed.
 *
 * Upon receiving this notification, the queue manager removes the BoxAPIOAuth2ToJSONOperation from
 * the set enqueuedOAuth2Operations, which means that future BoxAPIOperation instances will not
 * be dependent upon this BoxAPIOAuth2ToJSONOperation.
 *
 * @warning This method is defined in a private category in BoxAPIQueueManager.m
 *
 * @param notification the notification broadcast by a BoxAPIOAuth2ToJSONOperation when it completes
 */
- (void)OAuth2OperationDidComplete:(NSNotification *)notification;

@end

@implementation BoxAPIQueueManager

@synthesize OAuth2Session = _OAuth2Session;
@synthesize enqueuedOAuth2Operations = _enqueuedOAuth2Operations;

- (id)initWithOAuth2Session:(BoxOAuth2Session *)OAuth2Session
{
    self = [super init];
    if (self != nil)
    {
        _OAuth2Session = OAuth2Session;
        _enqueuedOAuth2Operations = [NSMutableSet set];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)enqueueOperation:(BoxAPIOperation *)operation
{
    if ([operation isKindOfClass:[BoxAPIOAuth2ToJSONOperation class]])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OAuth2OperationDidComplete:) name:BoxOAuth2OperationDidCompleteNotification object:operation];
    }

    return YES;
}

- (void)OAuth2OperationDidComplete:(NSNotification *)notification
{
    @synchronized(self.OAuth2Session)
    {
        BoxAPIOAuth2ToJSONOperation *operation = (BoxAPIOAuth2ToJSONOperation *)notification.object;
        BOXLog(@"%@ completed. Removing from set of OAuth2 dependencies", operation);
        [self.enqueuedOAuth2Operations removeObject:operation];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:BoxOAuth2OperationDidCompleteNotification object:operation];
    }
}

- (BOOL)addDependency:(NSOperation *)dependency toOperation:(NSOperation *)operation
{
    BOOL dependencyAdded = NO;

    // acquire the global API Operation lock before adding dependencies to
    // ensure operation cannot be started before adding dependency.
    [[BoxAPIOperation APIOperationGlobalLock] lock];

    // operation may have started before acquiring the lock. Now that we have the lock,
    // no other operations can start. Only add the dependency if operation has not
    // started executing.
    if (!operation.isExecuting)
    {
        [operation addDependency:dependency];
        dependencyAdded = YES;
    }

    [[BoxAPIOperation APIOperationGlobalLock] unlock];

    return dependencyAdded;
}

@end
