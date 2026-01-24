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

@interface VLCThumbnailsCache() {
    NSInteger MaxCacheSize;
    NSCache *_thumbnailCache;
    NSInteger _currentDeviceIdiom;
}
@end

@implementation VLCThumbnailsCache

#define MAX_CACHE_SIZE_IPHONE 24  // three times the number of items shown on iPhone 11 Pro
#define MAX_CACHE_SIZE_IPAD   45  // three times the number of items shown on regular sized iPad
#define MAX_CACHE_SIZE_WATCH  15  // three times the number of items shown on 42mm Watch

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

            default:
                MaxCacheSize = MAX_CACHE_SIZE_WATCH;
                break;
        }
#endif
        _thumbnailCache = [[NSCache alloc] init];
        [_thumbnailCache setCountLimit: MaxCacheSize];
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
    VLCThumbnailsCache *sharedCache = [VLCThumbnailsCache sharedThumbnailCache];
    return [sharedCache _thumbnailForURL:url];
}

+ (void)invalidateThumbnailForURL:(nullable NSURL *)url
{
    if (!url) {
        return;
    }
    VLCThumbnailsCache *sharedCache = [VLCThumbnailsCache sharedThumbnailCache];
    [sharedCache _invalidateThumbnailForURL:url];
}

+ (UIImage *)minimizedThumbnailForURL:(NSURL *)url
{
    VLCThumbnailsCache *sharedCache = [VLCThumbnailsCache sharedThumbnailCache];
    UIImage *thumbnail = [sharedCache _thumbnailForURL:url];
    return [sharedCache minimisedThumbnail:thumbnail];
}

- (void)_setThumbnail:(UIImage *)image forURL:(NSURL *)url
{
    if (image)
        [_thumbnailCache setObject:image forKey:url];
}

- (UIImage *)_thumbnailForURL:(NSURL *)url
{
    if (url == nil || url.path == nil)
        return nil;

    UIImage *theImage = [_thumbnailCache objectForKey:url];
    if (theImage) {
        return theImage;
    }

    theImage = [UIImage imageWithContentsOfFile:url.path];
    [self _setThumbnail:theImage forURL:url];

    return theImage;
}

- (void)_invalidateThumbnailForURL:(NSURL *)url
{
    [_thumbnailCache removeObjectForKey:url];
}

- (UIImage *)minimisedThumbnail:(UIImage *)thumbnail
{
    CGSize thumbnailSize = thumbnail.size;
    if (thumbnailSize.width <= 0 || thumbnailSize.height <= 0) {
        return thumbnail;
    }

    // those are the minimal dimensions suggested by Apple
    CGFloat scale = MIN(180 / thumbnailSize.width, 270 / thumbnailSize.height);
    if (scale >= 1.0) {
        return thumbnail;
    }

    CGSize targetSize = CGSizeMake(floor(thumbnailSize.width * scale), floor(thumbnailSize.height * scale));

    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 1.0);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) {
        UIGraphicsEndImageContext();
        return thumbnail;
    }

    CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);

    [thumbnail drawInRect:(CGRect){ .origin = CGPointZero, .size = targetSize }];

    UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return resized ?: thumbnail;
}

@end
