//
//  NSString+BoxURLHelper.h
//  BoxSDK
//
//  Created on 2/25/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Provides URL encoding extensions to `NSString`.
 */
@interface NSString (BoxURLHelper)

/**
 * Initialize an `NSString` that may be optionally UTRL encoded.
 *
 * @param string String to use to initialie returned value.
 * @param encoded Whether or not to URL encode string.
 *
 * @return A string that may or may not be URL encoded.
 */
+ (NSString *)box_stringWithString:(NSString *)string URLEncoded:(BOOL)encoded;

@end
