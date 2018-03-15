//
//  BoxFilesRequestBuilder.h
//  BoxSDK
//
//  Created on 3/22/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxItemsRequestBuilder.h"

/**
 * BoxFilesRequestBuilder is an request builder for file operations.
 *
 * This class allows constructing of the HTTP body for `POST` and 'PUT` requests as well
 * as setting query string parameters on the request.
 */
@interface BoxFilesRequestBuilder : BoxItemsRequestBuilder

/**
 * Encode the subset of body parameters that are supported for file
 * uploads which utilize BoxAPIMultipartToJSONOperation.
 *
 * @return A dictionary representing the encoded multipart parameters.
 *
 * @see [BoxAPIRequestBuilder bodyParameters]
 */
- (NSDictionary *)multipartBodyParameters;

@end
