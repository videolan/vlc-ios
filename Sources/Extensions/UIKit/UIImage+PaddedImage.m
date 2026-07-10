/*****************************************************************************
 * UIImage+paddedImage.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "UIImage+PaddedImage.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@implementation UIImage (paddedImage)

+ (UIImage *)paddedImageForSymbol:(NSString *)symbol ofSize:(CGSize)size
{
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:size.height * 0.55];
    UIImage *symbolImage = [UIImage systemImageNamed:symbol withConfiguration:configuration];

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    UIImage *paddedImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        CGSize symbolSize = symbolImage.size;
        CGRect drawRect = CGRectMake((size.width - symbolSize.width) / 2.0,
                                     (size.height - symbolSize.height) / 2.0,
                                     symbolSize.width, symbolSize.height);
        [symbolImage drawInRect:drawRect];
    }];

    return [paddedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@end

#pragma clang diagnostic pop
