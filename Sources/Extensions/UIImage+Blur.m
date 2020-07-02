/* This file is adapted from DKLiveBlur - https://github.com/kronik/DKLiveBlur
 *
 * Copyright (C) 2013 by Dmitry Klimkin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE. */

#import <Accelerate/Accelerate.h>

@implementation UIImage (Blur)

+ (UIImage *)applyBlurOnImage:(UIImage *)imageToBlur withRadius:(CGFloat)blurRadius {
    if (!imageToBlur)
        return nil;

    if ((blurRadius < 0.0f) || (blurRadius > 1.0f)) {
        blurRadius = 0.5f;
    }

    int boxSize = (int)(blurRadius * 100);
    boxSize -= (boxSize % 2) + 1;

    CGImageRef rawImage = imageToBlur.CGImage;

    vImage_Buffer inBuffer, outBuffer;
    vImage_Error error;
    void *pixelBuffer;

    CGDataProviderRef inProvider = CGImageGetDataProvider(rawImage);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);

    inBuffer.width = CGImageGetWidth(rawImage);
    inBuffer.height = CGImageGetHeight(rawImage);
    inBuffer.rowBytes = CGImageGetBytesPerRow(rawImage);
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);

    pixelBuffer = malloc(CGImageGetBytesPerRow(rawImage) * CGImageGetHeight(rawImage));

    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(rawImage);
    outBuffer.height = CGImageGetHeight(rawImage);
    outBuffer.rowBytes = CGImageGetBytesPerRow(rawImage);

    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL,
                                       0, 0, boxSize, boxSize, NULL,
                                       kvImageEdgeExtend);
    if (error)
        APLog(@"blur error: convolution failed");

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

        CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
                                                 outBuffer.width,
                                                 outBuffer.height,
                                                 8,
                                                 outBuffer.rowBytes,
                                                 colorSpace,
                                                 CGImageGetBitmapInfo(imageToBlur.CGImage));

        CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
        UIImage *returnImage = [UIImage imageWithCGImage:imageRef];

        //clean up
        CGContextRelease(ctx);
        CGColorSpaceRelease(colorSpace);

        free(pixelBuffer);
        CFRelease(inBitmapData);
        CGImageRelease(imageRef);
        
        return returnImage;
}

@end
