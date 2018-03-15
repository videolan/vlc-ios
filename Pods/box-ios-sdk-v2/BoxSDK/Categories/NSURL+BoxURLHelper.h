//
//  NSURL+BoxURLHelper.h
//  BoxSDK
//
//  Created on 2/25/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Provides query string parsing extensions to `NSURL`.
 */
@interface NSURL (BoxURLHelper)

/**
 * Returns the key value pairs in the URL's query string.
 * @return The key value pairs in the URL's query string.
 */
- (NSDictionary *)box_queryDictionary;

@end
