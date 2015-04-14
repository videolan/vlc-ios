/*****************************************************************************
 * UIImage+Scaling.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import "UIImage+Scaling.h"
#import <AVFoundation/AVFoundation.h>

@implementation UIImage (Scaling)

+ (UIImage *)scaleImage:(UIImage *)image toFitRect:(CGRect)rect
{
    CGRect destinationRect = AVMakeRectWithAspectRatioInsideRect(image.size, rect);

    CGImageRef cgImage = image.CGImage;
    size_t bitsPerComponent = CGImageGetBitsPerComponent(cgImage);
    size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
    CGColorSpaceRef colorSpaceRef = CGImageGetColorSpace(cgImage);
    CGBitmapInfo bitmapInfoRef = CGImageGetBitmapInfo(cgImage);

    CGContextRef contextRef = CGBitmapContextCreate(NULL,
                                                    destinationRect.size.width,
                                                    destinationRect.size.height,
                                                    bitsPerComponent,
                                                    bytesPerRow,
                                                    colorSpaceRef,
                                                    bitmapInfoRef);

    CGContextSetInterpolationQuality(contextRef, kCGInterpolationLow);

    CGContextDrawImage(contextRef, (CGRect){CGPointZero, destinationRect.size}, cgImage);

    return [UIImage imageWithCGImage:CGBitmapContextCreateImage(contextRef)];
}

@end
