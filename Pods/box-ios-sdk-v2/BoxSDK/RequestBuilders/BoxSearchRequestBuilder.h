//
//  BoxSearchRequestBuilder.h
//  BoxSDK
//
//  Created on 11/21/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIRequestBuilder.h"

extern NSString *const BoxAPISearchQueryParameter;

/**
 * BoxSearchRequestBuilder allows callers to build the on-the-wire representation
 * for searching a user's Box account.
 *
 * Constants
 * =========
 * - `BoxAPISearchQueryParameter` The name of the search query string parameter.
 */
@interface BoxSearchRequestBuilder : BoxAPIRequestBuilder

/**
 * The query to search for via the API. Sets the value in the query string parameters.
 */
@property (nonatomic, readwrite, strong) NSString *query;

/**
 * Create a builder with the specified search query
 *
 * @param query Search query
 * @param queryStringParameters Additional query string parameters such as limit and offset
 * @return A request builder configured with search and query params.
 */
- (id)initWithSearch:(NSString *)query queryStringParameters:(NSDictionary *)queryStringParameters;

@end
