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
        CGFloat scale = MIN(1.0, MIN(size.width * 0.8 / symbolSize.width, size.height * 0.8 / symbolSize.height));
        CGSize scaledSize = CGSizeMake(symbolSize.width * scale, symbolSize.height * scale);
        CGRect drawRect = CGRectMake((size.width - scaledSize.width) / 2.0,
                                     (size.height - scaledSize.height) / 2.0,
                                     scaledSize.width, scaledSize.height);
        [symbolImage drawInRect:drawRect];
    }];

    return [paddedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@end

#pragma clang diagnostic pop
