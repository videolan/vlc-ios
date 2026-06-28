/*****************************************************************************
 * UIImage+AverageColor.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "UIImage+AverageColor.h"
#import "VLC-Swift.h"

@implementation UIImage(AverageColor)

- (UIColor *)averageColor
{
    CGImageRef imageRef = [self CGImage];
    if (!imageRef) {
        return PresentationTheme.current.colors.background;
    }

    // Render the source image into a small bitmap of a known layout (RGBA8,
    // premultiplied, no row padding) so we never depend on the format of the
    // thumbnail handed to us by the media library.
    const size_t side = 40;
    const size_t bytesPerPixel = 4;
    const size_t bytesPerRow = side * bytesPerPixel;
    UInt8 pixels[side * bytesPerRow];
    memset(pixels, 0, sizeof(pixels));

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, side, side, 8, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    if (!context) {
        return PresentationTheme.current.colors.background;
    }

    CGContextSetInterpolationQuality(context, kCGInterpolationLow);
    CGContextDrawImage(context, CGRectMake(0, 0, side, side), imageRef);
    CGContextRelease(context);

    NSUInteger totalRed = 0;
    NSUInteger totalGreen = 0;
    NSUInteger totalBlue = 0;

    for (size_t y = 0; y < side; y++) {
        for (size_t x = 0; x < side; x++) {
            const UInt8 *pixel = &pixels[y * bytesPerRow + x * bytesPerPixel];
            totalRed += pixel[0];
            totalGreen += pixel[1];
            totalBlue += pixel[2];
        }
    }

    const NSUInteger pixelCount = side * side;
    CGFloat avgRed = (CGFloat)totalRed / pixelCount / 255.0;
    CGFloat avgGreen = (CGFloat)totalGreen / pixelCount / 255.0;
    CGFloat avgBlue = (CGFloat)totalBlue / pixelCount / 255.0;

    return [UIColor colorWithRed:avgRed green:avgGreen blue:avgBlue alpha:1.0];
}

@end
