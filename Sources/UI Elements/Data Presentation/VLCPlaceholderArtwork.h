/*****************************************************************************
 * VLCPlaceholderArtwork.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCPlaceholderArtwork : NSObject

+ (NSString *)initialsForName:(nullable NSString *)name;
+ (UIColor *)backgroundColorForName:(nullable NSString *)name;
+ (UIColor *)foregroundColorForName:(nullable NSString *)name;

+ (UIImage *)placeholderImageForName:(nullable NSString *)name
                                size:(CGSize)size
                        cornerRadius:(CGFloat)cornerRadius
                            fontSize:(CGFloat)fontSize;

@end

NS_ASSUME_NONNULL_END
