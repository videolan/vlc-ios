//
//  BoxSerialOAuth2Session.h
//  BoxSDK
//
//  Created on 2/20/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxOAuth2Session.h"

/**
 * BoxSerialOAuth2Session is an implementation of the abstract class BoxOAuth2Session.
 * This OAuth2 session assumes there is only one concurrent operation at a time. This means
 * that at any given time, only one API call will be in progress.
 *
 * This class is intended to be used in conjunction with a BoxSerialAPIQueueManager. Both classes
 * assume one concurrent BoxAPIOperation. This assumption enables the locking strategy with regard
 * to OAuth2 token refresh to be simplified. Whenever this class enqueues a BoxAPIOAuth2ToJSONOperation,
 * the queue adds it as a dependency to all currently enqueued operations as well as operations enqueued
 * before the OAuth2 operation completes.
 */
@interface BoxSerialOAuth2Session : BoxOAuth2Session

@end
