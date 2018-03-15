//
//  UIImage+BoxAdditions.h
//  BoxSDK
//
//  Created on 6/3/13.
//  Copyright (c) 2013 Box. All rights reserved.
//
//  NOTE: this file is a mirror of BoxCocoaSDK/Categories/NSImage+BoxAdditions.h. Changes made here should be reflected there.
//

#import <UIKit/UIKit.h>

/**
 * The BoxAdditions category on UIImage provides a method for loading
 * images from the BoxSDK resources bundle.
 */
@interface UIImage (BoxAdditions)

/**
 * Retrieves assets embedded in the ressource bundle.
 *
 * @param string Image name.
 */
+ (UIImage *)imageFromBoxSDKResourcesBundleWithName:(NSString *)string;

/**
 * Returns an image with the appropriate scale factor given the device.
 *
 * @return An image with the appropriate scale.
 */
- (UIImage *)imageWith2XScaleIfRetina;


@end