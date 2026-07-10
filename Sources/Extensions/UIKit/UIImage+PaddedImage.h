/*****************************************************************************
 * UIImage+paddedImage.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (paddedImage)

+ (nullable UIImage *)paddedImageForSymbol:(NSString *)symbol ofSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
