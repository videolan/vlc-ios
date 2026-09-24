/*****************************************************************************
 * VLCQRCodeGenerator.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCQRCodeGenerator.h"

#import <CoreImage/CoreImage.h>
#import <CoreImage/CIFilterBuiltins.h>

@implementation VLCQRCodeGenerator

+ (UIImage *)QRCodeImageForString:(NSString *)string
{
    CIFilter<CIQRCodeGenerator> *generator = [CIFilter QRCodeGenerator];
    generator.message = [string dataUsingEncoding:NSUTF8StringEncoding];

    CIFilter<CIColorInvert> *invert = [CIFilter colorInvertFilter];
    invert.inputImage = generator.outputImage;
    CIFilter<CIMaskToAlpha> *mask = [CIFilter maskToAlphaFilter];
    mask.inputImage = invert.outputImage;

    CIImage *code = mask.outputImage;
    if (!code) {
        return nil;
    }

    CGImageRef cgImage = [[CIContext context] createCGImage:code fromRect:code.extent];
    UIImage *image = [[UIImage imageWithCGImage:cgImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    CGImageRelease(cgImage);

    return image;
}

@end
