/*****************************************************************************
 * UIDevice+VLC.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, VLCSpeedCategory) {
    VLCSpeedCategoryNotSet = 0,
    VLCSpeedCategoryOneDevices, // < iOS 9 and not supported anymore
    VLCSpeedCategoryTwoDevices, // iPhone 4S, iPad 2 and 3, iPod 4 and 5
    VLCSpeedCategoryThreeDevices, // iPhone 5 + 5S, iPad 4, iPad Air, iPad mini 2G
    VLCSpeedCategoryFourDevices, // iPhone 6 + 6S, 2014+2015 iPads and newer
};

@interface UIDevice (VLC)

@property (readonly) VLCSpeedCategory vlcSpeedCategory;
@property (readonly) NSNumber *VLCFreeDiskSpace;
@property (readonly) BOOL VLCHasExternalDisplay;

@end
