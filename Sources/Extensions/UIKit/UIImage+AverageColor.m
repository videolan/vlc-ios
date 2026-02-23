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

static CGImageRef resizeCGImage(CGImageRef image)
{
    CGSize targetSize = CGSizeMake(4096., 4096.);
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        UIGraphicsEndImageContext();
        return nil;
    }
    CGContextDrawImage(context, CGRectMake(0, 0, targetSize.width, targetSize.height), image);
    CGImageRef resizedImage = CGBitmapContextCreateImage(context);
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (UIColor *)averageColor
{
    CGImageRef imageRef = [self CGImage];
    if (!imageRef) {
        return PresentationTheme.current.colors.background;
    }
    CGImageRef resizedImageRef = nil;
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);

    if (width > 4096 || height > 4096) {
        resizedImageRef = resizeCGImage(imageRef);
        if (resizedImageRef) {
            imageRef = resizedImageRef;
            width = CGImageGetWidth(imageRef);
            height = CGImageGetHeight(imageRef);
        }
    }

    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    if (!colorSpace || CGColorSpaceGetModel(colorSpace) != kCGColorSpaceModelRGB) {
        if (resizedImageRef) {
            CGImageRelease(resizedImageRef);
        }
        return PresentationTheme.current.colors.background;
    }

    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    CFDataRef imageData = CGDataProviderCopyData(dataProvider);
    if (!imageData) {
        if (resizedImageRef) {
            CGImageRelease(resizedImageRef);
        }
        return PresentationTheme.current.colors.background;
    }
    const UInt8 *pixels = CFDataGetBytePtr(imageData);

    NSUInteger totalRed = 0;
    NSUInteger totalGreen = 0;
    NSUInteger totalBlue = 0;
    NSUInteger pixelCount = 0;

    // Iterate through the pixels
    for (NSUInteger x = 0; x < width; x++) {
        for (NSUInteger y = 0; y < height; y++) {
            NSUInteger pixelIndex = (width * y + x) * 4; // Each pixel has 4 bytes (RGBA)
            totalRed += pixels[pixelIndex];
            totalGreen += pixels[pixelIndex + 1];
            totalBlue += pixels[pixelIndex + 2];
            pixelCount++;
        }
    }

    CFRelease(imageData);
    if (resizedImageRef) {
        CGImageRelease(resizedImageRef);
    }

    // Calculate the average color
    if (pixelCount > 0) {
        CGFloat avgRed = (CGFloat)totalRed / pixelCount / 255.0;
        CGFloat avgGreen = (CGFloat)totalGreen / pixelCount / 255.0;
        CGFloat avgBlue = (CGFloat)totalBlue / pixelCount / 255.0;

        return [UIColor colorWithRed:avgRed green:avgGreen blue:avgBlue alpha:1.0];
    }

    return PresentationTheme.current.colors.background;
}

@end
