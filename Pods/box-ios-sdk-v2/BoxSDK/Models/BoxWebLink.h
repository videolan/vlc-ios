//
//  BoxWebLink.h
//  BoxSDK
//
//  Created on 4/22/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxItem.h"

/**
 * BoxWebLink represents web links (bookmarks) on Box.
 */
@interface BoxWebLink : BoxItem

/**
 * The URL referred to by this web link.
 */
- (NSURL *)URL;

@end
