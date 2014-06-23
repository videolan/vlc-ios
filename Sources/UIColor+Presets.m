//
//  UIColor+Presets.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 23.06.14.
//  Copyright (c) 2014 VideoLAN. All rights reserved.
//

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

@end
