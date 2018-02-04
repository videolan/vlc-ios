/*****************************************************************************
 * UIColor+Presets.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface UIColor (Presets)

+ (UIColor *)VLCDarkBackgroundColor;
+ (UIColor *)VLCTransparentDarkBackgroundColor;
+ (UIColor *)VLCLightTextColor;
+ (UIColor *)VLCDarkFadedTextColor;
+ (UIColor *)VLCDarkTextColor;
+ (UIColor *)VLCDarkTextShadowColor;
+ (UIColor *)VLCOrangeTintColor;
+ (UIColor *)VLCMenuBackgroundColor;

@end
