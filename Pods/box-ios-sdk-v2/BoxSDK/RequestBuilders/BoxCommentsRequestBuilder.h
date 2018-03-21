//
//  BoxCommentsRequestBuilder.h
//  BoxSDK
//
//  Created on 11/21/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIRequestBuilder.h"

@class BoxModelBuilder;

/**
 * BoxCommentsRequestBuilder is an request builder for comment operations.
 *
 * This class allows constructing of the HTTP body for `POST` and 'PUT` requests as well
 * as setting query string parameters on the request.
 */
@interface BoxCommentsRequestBuilder : BoxAPIRequestBuilder

/**
 * A BoxModelBuilder for setting and/or unsetting item that this comment is for.
 */
@property (nonatomic, readwrite, strong) BoxModelBuilder *item;

/**
 * The message that this comment represents
 */
@property (nonatomic, readwrite, strong) NSString *message;

@end
