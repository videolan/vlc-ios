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

#import "UIColor+Presets.h"

@implementation UIColor (Presets)

+ (nonnull UIColor *)VLCDarkBackgroundColor
{
    return [UIColor colorWithWhite:.122 alpha:1.];
}

+ (nonnull UIColor *)VLCTransparentDarkBackgroundColor
{
    return [UIColor colorWithWhite:.122 alpha:0.75];
}

+ (nonnull UIColor *)VLCLightTextColor
{
    return [UIColor colorWithWhite:.72 alpha:1.];
}

+ (nonnull UIColor *)VLCDarkFadedTextColor {
    return [UIColor colorWithRed:0.33 green:0.33 blue:0.33 alpha:1.0];
}

+ (nonnull UIColor *)VLCDarkTextColor
{
    return [UIColor colorWithWhite:.28 alpha:1.];
}

+ (nonnull UIColor *)VLCDarkTextShadowColor
{
    return [UIColor colorWithWhite:0. alpha:.25f];
}

+ (nonnull UIColor *)VLCMenuBackgroundColor
{
    return [UIColor colorWithWhite:.17f alpha:1.];
}

+ (nonnull UIColor *)VLCOrangeTintColor
{
    return [UIColor colorWithRed:1.0f green:(132.0f/255.0f) blue:0.0f alpha:1.f];
}

@end
