//
//  BoxParallelOAuth2Session.h
//  BoxSDK
//
//  Created on 5/11/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxOAuth2Session.h"

/**
 * BoxParallelOAuth2Session is an implementation of the abstract class BoxOAuth2Session.
 * This OAuth2 session assumes there are many concurrent operations at a time. This means
 * that at any given time, only several API calls may be in progress.
 *
 * BoxParallelOAuth2Session is intended to be used in conjunction with a BoxParallelAPIQueueManager.
 * Both classes assume many concurrent [BoxAPIOperations]([BoxAPIOperation])s. To ensure that the
 * tokens will not get thrashed by concurrent refreshes of the same token, BoxParallelOAuth2Session
 * stores a set of all access tokens that have triggered a token refresh. All BoxAPIOperation instances
 * hold a copy of the token they were signed with and pass that to the OAuth2 session when attempting a
 * refresh. This prevents multiple refresh attempts from the same set of tokens.
 */
@interface BoxParallelOAuth2Session : BoxOAuth2Session

@end
