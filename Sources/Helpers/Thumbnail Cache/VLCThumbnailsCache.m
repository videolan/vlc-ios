/*****************************************************************************
 * VLCThumbnailsCache.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Gleb Pinigin <gpinigin # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Carola Nitz <caro # videolan.org>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCThumbnailsCache.h"

#import <ImageIO/ImageIO.h>

@interface VLCThumbnailsCache() {
    NSInteger MaxCacheSize;
    NSCache *_thumbnailCache;
    NSInteger _currentDeviceIdiom;
    NSMutableSet<NSNumber *> *_knownMaxPixelSizes;
    NSLock *_knownMaxPixelSizesLock;
}
@end

@implementation VLCThumbnailsCache

#define MAX_CACHE_SIZE_IPHONE (16 * 1024 * 1024)
#define MAX_CACHE_SIZE_IPAD   (24 * 1024 * 1024)
#define MAX_CACHE_SIZE_WATCH  (8 * 1024 * 1024)
#define MAX_CACHE_SIZE_tvOS   (64 * 1024 * 1024)
#define DEFAULT_MAX_PIXEL_SIZE 1024.f

- (instancetype)init
{
    self = [super init];
    if (self) {
        MaxCacheSize = 0;
#if TARGET_OS_WATCH
        // On watchOS, we don't have a `UIDevice`, so we set a fixed cache size
        MaxCacheSize = MAX_CACHE_SIZE_WATCH;
#else
        _currentDeviceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
        switch (_currentDeviceIdiom) {
            case UIUserInterfaceIdiomPad:
                MaxCacheSize = MAX_CACHE_SIZE_IPAD;
                break;
            case UIUserInterfaceIdiomPhone:
                MaxCacheSize = MAX_CACHE_SIZE_IPHONE;
                break;
            case UIUserInterfaceIdiomTV:
                MaxCacheSize = MAX_CACHE_SIZE_tvOS;
                break;
            default:
                MaxCacheSize = MAX_CACHE_SIZE_WATCH;
                break;
        }
#endif
        _thumbnailCache = [[NSCache alloc] init];
        [_thumbnailCache setTotalCostLimit: MaxCacheSize];
        _knownMaxPixelSizes = [NSMutableSet set];
        _knownMaxPixelSizesLock = [[NSLock alloc] init];
    }
    return self;
}

+ (instancetype)sharedThumbnailCache
{
    static dispatch_once_t onceToken;
    static VLCThumbnailsCache *sharedThumbnailCache;
    dispatch_once(&onceToken, ^{
        sharedThumbnailCache = [[VLCThumbnailsCache alloc] init];
    });

    return sharedThumbnailCache;
}

+ (UIImage *)thumbnailForURL:(NSURL *)url
{
    return [VLCThumbnailsCache thumbnailForURL:url maxPixelSize:DEFAULT_MAX_PIXEL_SIZE];
}

+ (UIImage *)thumbnailForURL:(NSURL *)url maxPixelSize:(CGFloat)maxPixelSize
{
    VLCThumbnailsCache *sharedCache = [VLCThumbnailsCache sharedThumbnailCache];
    return [sharedCache _thumbnailForURL:url maxPixelSize:maxPixelSize];
}

+ (void)invalidateThumbnailForURL:(nullable NSURL *)url
{
    if (!url) {
        return;
    }
    VLCThumbnailsCache *sharedCache = [VLCThumbnailsCache sharedThumbnailCache];
    [sharedCache _invalidateThumbnailForURL:url];
}

- (NSString *)cacheKeyForURL:(NSURL *)url maxPixelSize:(CGFloat)maxPixelSize
{
    return [NSString stringWithFormat:@"%@|%.0f", url.path, maxPixelSize];
}

- (UIImage *)_thumbnailForURL:(NSURL *)url maxPixelSize:(CGFloat)maxPixelSize
{
    if (url == nil || !url.isFileURL)
        return nil;

    NSString *path = url.path;
    if (path.length == 0)
        return nil;

    NSString *key = [self cacheKeyForURL:url maxPixelSize:maxPixelSize];
    UIImage *theImage = [_thumbnailCache objectForKey:key];
    if (theImage) {
        return theImage;
    }

    theImage = [self downsampledImageAtPath:path maxPixelSize:maxPixelSize];
    if (!theImage) {
        return nil;
    }

    [_knownMaxPixelSizesLock lock];
    [_knownMaxPixelSizes addObject:@(maxPixelSize)];
    [_knownMaxPixelSizesLock unlock];

    [_thumbnailCache setObject:theImage forKey:key cost:[self costForImage:theImage]];

    return theImage;
}

- (UIImage *)downsampledImageAtPath:(NSString *)path maxPixelSize:(CGFloat)maxPixelSize
{
    NSURL *url = [NSURL fileURLWithPath:path];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (source == NULL) {
        APLog(@"Failed to read thumbnail at path '%@'", path);
        return nil;
    }

    NSDictionary *options = @{
        (__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
        (__bridge NSString *)kCGImageSourceCreateThumbnailWithTransform: @YES,
        (__bridge NSString *)kCGImageSourceShouldCacheImmediately: @YES,
        (__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize: @(maxPixelSize)
    };

    CGImageRef cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    CFRelease(source);

    if (cgImage == NULL) {
        APLog(@"Failed to decode thumbnail at path '%@'", path);
        return nil;
    }

    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);

    return image;
}

- (NSUInteger)costForImage:(UIImage *)image
{
    CGImageRef cgImage = image.CGImage;
    if (cgImage == NULL) {
        return 0;
    }
    return CGImageGetBytesPerRow(cgImage) * CGImageGetHeight(cgImage);
}

- (void)_invalidateThumbnailForURL:(NSURL *)url
{
    [_knownMaxPixelSizesLock lock];
    NSArray<NSNumber *> *maxPixelSizes = _knownMaxPixelSizes.allObjects;
    [_knownMaxPixelSizesLock unlock];

    for (NSNumber *maxPixelSize in maxPixelSizes) {
        [_thumbnailCache removeObjectForKey:[self cacheKeyForURL:url
                                                    maxPixelSize:maxPixelSize.doubleValue]];
    }
}

@end
