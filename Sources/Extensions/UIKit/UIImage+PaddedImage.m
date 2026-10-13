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
#import "VLC-Swift.h"

@implementation UIImage (paddedImage)

+ (UIImage *)paddedImageForSymbol:(NSString *)symbol ofSize:(CGSize)size
{
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:size.height * 0.55];
    UIImage *symbolImage = [UIImage systemImageNamed:symbol withConfiguration:configuration];

    UITraitCollection *lightTraits = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    UITraitCollection *darkTraits = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];

    UIImageAsset *asset = [[UIImageAsset alloc] init];
    [asset registerImage:[self paddedImageForSymbolImage:symbolImage
                                                  ofSize:size
                                                   color:PresentationTheme.brightTheme.colors.cellTextColor]
     withTraitCollection:lightTraits];
    [asset registerImage:[self paddedImageForSymbolImage:symbolImage
                                                  ofSize:size
                                                   color:PresentationTheme.darkTheme.colors.cellTextColor]
     withTraitCollection:darkTraits];

    return [asset imageWithTraitCollection:lightTraits];
}

+ (UIImage *)paddedImageForSymbolImage:(UIImage *)symbolImage ofSize:(CGSize)size color:(UIColor *)color
{
    UIImage *tintedImage = [symbolImage imageWithTintColor:color renderingMode:UIImageRenderingModeAlwaysOriginal];

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        CGSize symbolSize = tintedImage.size;
        CGFloat scale = MIN(1.0, MIN(size.width * 0.8 / symbolSize.width, size.height * 0.8 / symbolSize.height));
        CGSize scaledSize = CGSizeMake(symbolSize.width * scale, symbolSize.height * scale);
        CGRect drawRect = CGRectMake((size.width - scaledSize.width) / 2.0,
                                     (size.height - scaledSize.height) / 2.0,
                                     scaledSize.width, scaledSize.height);
        [tintedImage drawInRect:drawRect];
    }];
}

@end
