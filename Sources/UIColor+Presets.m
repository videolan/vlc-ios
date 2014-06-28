/*****************************************************************************
 * UIColor+Presets.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "UIColor+Presets.h"

@implementation UIColor (Presets)

+ (UIColor *)VLCDarkBackgroundColor
{
    return [UIColor colorWithWhite:.122 alpha:1.];
}

+ (UIColor *)VLCLightTextColor
{
    return [UIColor colorWithWhite:.72 alpha:1.];
}

+ (UIColor *)VLCDarkTextShadowColor
{
    return [UIColor colorWithWhite:0. alpha:.25f];
}

+ (UIColor *)VLCOrangeTintColor
{
    return [UIColor colorWithRed:1.0f green:(132.0f/255.0f) blue:0.0f alpha:1.f];
}

@end
