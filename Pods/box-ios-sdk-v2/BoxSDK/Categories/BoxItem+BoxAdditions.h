//
//  BoxItem+BoxAdditions.h
//  BoxSDK
//
//  Created on 6/4/13.
//  Copyright (c) 2013 Box. All rights reserved.
//
//  NOTE: this file is a mirror of BoxCocoaSDK/Categories/BoxItem+BoxCocoaAdditions.h. Changes made here should be reflected there.
//

#import "BoxItem.h"
#import <UIKit/UIKit.h>

/**
 * BoxAdditions exposes the ability to grab icons for the files. These icons are pulled out of the resource bundle
 * that you can include in your project. This category is used by the folder picker to display default icons for each file type.
 */
@interface BoxItem (BoxAdditions)

/**
 * The icon representing the type of the item
 */
- (UIImage *)icon;


@end
