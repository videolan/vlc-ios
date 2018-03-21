//
//  UIImage.m
//  MediaLibraryKit
//
//  Created by Felix Paul Kühne on 29/05/15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import "UIImage+MLKit.h"
#import "TargetConditionals.h"

#if TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#endif
@implementation UIImage (MLKit)

+ (CGSize)preferredThumbnailSizeForDevice
{
#if TARGET_OS_IOS
    CGFloat thumbnailWidth, thumbnailHeight;
    /* optimize thumbnails for the device */
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        thumbnailWidth = 272.;
        thumbnailHeight = 204.;
    } else {
        thumbnailWidth = 240.;
        thumbnailHeight = 135.;
    }
    return CGSizeMake(thumbnailWidth, thumbnailHeight);
#elif TARGET_OS_WATCH
    return [WKInterfaceDevice currentDevice].screenBounds.size;
#endif
    return CGSizeZero;
}

+ (UIImage *)scaleImage:(UIImage *)image toFitRect:(CGRect)rect {
    CGFloat scale = 0.0;
#if TARGET_OS_IOS
    scale = [UIScreen mainScreen].scale;
#elif TARGET_OS_WATCH
    scale = [WKInterfaceDevice currentDevice].screenScale;
#endif
    return [self scaleImage:image toFitRect:rect scale:scale];
}

static inline CGRect MakeRectWithAspectRatioInsideRect(CGSize size, CGRect rect) {
    CGFloat aspectWidth = rect.size.width/size.width;
    CGFloat aspectHeight = rect.size.height/size.height;
    CGFloat aspectRatio = MIN(aspectWidth, aspectHeight);

    rect.size.width = ceill(size.width * aspectRatio);
    rect.size.height = ceill(size.height * aspectRatio);

    return rect;
}


+ (UIImage *)scaleImage:(UIImage *)image toFitRect:(CGRect)rect scale:(CGFloat)scale
{
    CGRect destinationRect = MakeRectWithAspectRatioInsideRect(image.size, rect);


    destinationRect = CGRectIntegral(CGRectMake(destinationRect.origin.x, destinationRect.origin.y, destinationRect.size.width*scale, destinationRect.size.height*scale));

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
    CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
    UIImage *scaledImage = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    CGContextRelease(contextRef);
    return scaledImage;
}

@end
