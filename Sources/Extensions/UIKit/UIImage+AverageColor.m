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

@implementation UIImage(AverageColor)

CGImageRef resizeCGImage(CGImageRef image) {
    CGSize targetSize = CGSizeMake(4096., 4096.);
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, CGRectMake(0, 0, targetSize.width, targetSize.height), image);
    CGImageRef resizedImage = CGBitmapContextCreateImage(context);
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (UIColor *)averageColor
{
    UIImage *image = self;

    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);

    if (width > 4096 || height > 4096) {
        CGImageRef resizedImage = resizeCGImage(imageRef);
        CFRelease(imageRef);
        imageRef = resizedImage;
    }

    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    CFDataRef imageData = CGDataProviderCopyData(dataProvider);
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
    CFRelease(imageRef);

    // Calculate the average color
    if (pixelCount > 0) {
        CGFloat avgRed = (CGFloat)totalRed / pixelCount / 255.0;
        CGFloat avgGreen = (CGFloat)totalGreen / pixelCount / 255.0;
        CGFloat avgBlue = (CGFloat)totalBlue / pixelCount / 255.0;

        return [UIColor colorWithRed:avgRed green:avgGreen blue:avgBlue alpha:1.0];
    }

    return nil;
}

@end
