//
//  BoxSerialAPIQueueManager.m
//  BoxSDK
//
//  Created on 2/28/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxSerialAPIQueueManager.h"

#import "BoxAPIOperation.h"
#import "BoxAPIOAuth2ToJSONOperation.h"
#import "BoxLog.h"
#import "BoxOAuth2Session.h"

@implementation BoxSerialAPIQueueManager

@synthesize globalQueue = _globalQueue;

- (id)init
{
    self = [self initWithOAuth2Session:nil];
    return self;
}

- (id)initWithOAuth2Session:(BoxOAuth2Session *)OAuth2Session
{
    self = [super initWithOAuth2Session:OAuth2Session];
    if (self != nil)
    {
        _globalQueue = [[NSOperationQueue alloc] init];
        _globalQueue.name = @"BoxSerialAPIQueueManager global queue";
        _globalQueue.maxConcurrentOperationCount = 1;
    }

    return self;
}

- (BOOL)enqueueOperation:(BoxAPIOperation *)operation
{
    // lock on the OAuth2Session, which is the shared resource
    @synchronized(self.OAuth2Session)
    {
        [super enqueueOperation:operation];

        // ensure that OAuth2 operations occur before all other operations
        if ([operation isKindOfClass:[BoxAPIOAuth2ToJSONOperation class]])
        {
            // hold a refernce to the pending OAuth2 operation so it can be added
            // as a dependency to all APIOperations enqueued before it finishes
            [self.enqueuedOAuth2Operations addObject:operation];

            for (NSOperation *enqueuedOperation in self.globalQueue.operations)
            {
                // All API Operations should be dependent on OAuth2 operations EXCEPT other
                // OAuth2 operations. For example, if a client requests 5 subsequent token refreshes,
                // All authenticated operations should depend on these requests resolving, but these
                // requests do not depend on each other
                if (![enqueuedOperation isKindOfClass:[BoxAPIOAuth2ToJSONOperation class]])
                {
                    [self addDependency:operation toOperation:enqueuedOperation];
                }
            }
        }
        else
        {
            // If there are any incomplete OAuth2 operations, add them as dependencies for
            // this newly enqueued operation. OAuth2 operations have the potential to change
            // the access token, which Authenticated operations need in order to complete
            // successfully.
            for (NSOperation *pendingOAuth2Operation in self.enqueuedOAuth2Operations)
            {
                [self addDependency:pendingOAuth2Operation toOperation:operation];

            }
        }

        [self.globalQueue addOperation:operation];
        BOXLog(@"enqueued %@", operation);
        
        return YES;
    }
}

@end
