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

@property (nonatomic, strong, readonly, nonnull, class) UIColor *VLCDarkBackgroundColor;
@property (nonatomic, strong, readonly, nonnull, class) UIColor *VLCTransparentDarkBackgroundColor;
@property (nonatomic, strong, readonly, nonnull, class) UIColor *VLCLightTextColor;
@property (nonatomic, strong, readonly, nonnull, class) UIColor *VLCDarkFadedTextColor;
@property (nonatomic, strong, readonly, nonnull, class) UIColor *VLCDarkTextColor;
@property (nonatomic, strong, readonly, nonnull, class) UIColor *VLCDarkTextShadowColor;
@property (nonatomic, strong, readonly, nonnull, class) UIColor *VLCOrangeTintColor;
@property (nonatomic, strong, readonly, nonnull, class) UIColor *VLCMenuBackgroundColor;

@end
