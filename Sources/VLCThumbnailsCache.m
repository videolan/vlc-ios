/*****************************************************************************
 * VLCThumbnailsCache.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
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
#import <CommonCrypto/CommonDigest.h>
#import "UIImage+Blur.h"
#import <WatchKit/WatchKit.h>
#import <CoreData/CoreData.h>
#import <MediaLibraryKit/MediaLibraryKit.h>
#import <MediaLibraryKit/UIImage+MLKit.h>
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

@interface VLCThumbnailsCache() {
    NSInteger MaxCacheSize;
    NSCache *_thumbnailCache;
    NSCache *_thumbnailCacheMetadata;
    NSInteger _currentDeviceIdiom;
}
@end

@implementation VLCThumbnailsCache

#define MAX_CACHE_SIZE_IPHONE 21  // three times the number of items shown on iPhone 5
#define MAX_CACHE_SIZE_IPAD   27  // three times the number of items shown on iPad
#define MAX_CACHE_SIZE_WATCH  15  // three times the number of items shown on 42mm Watch

- (instancetype)init
{
    self = [super init];
    if (self) {
// TODO: correct for watch
#if TARGET_OS_IOS
        _currentDeviceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
        MaxCacheSize = 0;

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
#else
        MaxCacheSize = MAX_CACHE_SIZE_WATCH;
#endif
        _thumbnailCache = [[NSCache alloc] init];
        _thumbnailCacheMetadata = [[NSCache alloc] init];
        [_thumbnailCache setCountLimit: MaxCacheSize];
        [_thumbnailCacheMetadata setCountLimit: MaxCacheSize];
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

+ (UIImage *)thumbnailForManagedObject:(NSManagedObject *)object
{
    return [self thumbnailForManagedObject:object refreshCache:NO];
}

+ (UIImage *)thumbnailForManagedObject:(NSManagedObject *)object
                          refreshCache:(BOOL)refreshCache
{
    UIImage *thumbnail;
    VLCThumbnailsCache *cache = [VLCThumbnailsCache sharedThumbnailCache];
    if ([object isKindOfClass:[MLShow class]]) {
        thumbnail = [cache thumbnailForShow:(MLShow *)object refreshCache:refreshCache];
    } else if ([object isKindOfClass:[MLShowEpisode class]]) {
        MLFile *anyFileFromEpisode = [(MLShowEpisode *)object files].anyObject;
        thumbnail = [cache thumbnailForMediaFile:anyFileFromEpisode refreshCache:refreshCache];
    } else if ([object isKindOfClass:[MLLabel class]]) {
        thumbnail = [cache thumbnailForLabel:(MLLabel *)object refreshCache:refreshCache];
    } else if ([object isKindOfClass:[MLAlbum class]]) {
        thumbnail = [cache thumbnailForAlbum:(MLAlbum *)object refreshCache:refreshCache];
    } else if ([object isKindOfClass:[MLAlbumTrack class]]) {
        thumbnail = [cache thumbnailForAlbumTrack:(MLAlbumTrack *)object refreshCache:refreshCache];
    } else {
        thumbnail = [cache thumbnailForMediaFile:(MLFile *)object refreshCache:refreshCache];
    }
    return thumbnail;
}

+ (UIImage *)thumbnailForManagedObject:(NSManagedObject *)object refreshCache:(BOOL)refreshCache toFitRect:(CGRect)rect scale:(CGFloat)scale shouldReplaceCache:(BOOL)replaceCache;
{
    UIImage *rawThumbnail = [self thumbnailForManagedObject:object refreshCache:refreshCache];
    CGSize rawSize = rawThumbnail.size;
    CGFloat rawScale = rawThumbnail.scale;

    /* scaling is potentially expensive, so we should avoid re-doing it for the same size over and over again */ 
    if (rawSize.width*rawScale <= rect.size.width*scale && rawSize.height*rawScale <= rect.size.height*scale)
        return rawThumbnail;

    UIImage *scaledImage = [UIImage scaleImage:rawThumbnail toFitRect:rect scale:scale];

    if (replaceCache)
        [[VLCThumbnailsCache sharedThumbnailCache] _setThumbnail:scaledImage forObjectId:object.objectID];

    return scaledImage;
}

- (void)_setThumbnail:(UIImage *)image forObjectId:(NSManagedObjectID *)objID
{
    if (image)
        [_thumbnailCache setObject:image forKey:objID];
}

- (UIImage *)thumbnailForMediaFile:(MLFile *)mediaFile refreshCache:(BOOL)refreshCache
{
    if (mediaFile == nil || mediaFile.objectID == nil)
        return nil;

    NSManagedObjectID *objID = mediaFile.objectID;
    UIImage *displayedImage;

    if (!refreshCache) {
        displayedImage = [_thumbnailCache objectForKey:objID];
        if (displayedImage)
            return displayedImage;
    }

    if (!displayedImage) {
        __block UIImage *computedImage = nil;
        void (^getThumbnailBlock)(void) = ^(){
            computedImage = mediaFile.computedThumbnail;
        };
        if ([NSThread isMainThread])
            getThumbnailBlock();
        else
            dispatch_sync(dispatch_get_main_queue(), getThumbnailBlock);
        displayedImage = computedImage;
    }

    if (!displayedImage) {
        if ([mediaFile isKindOfType:@"audio"]) {
            displayedImage = [UIImage imageNamed:@"no-artwork"];
        } else if ([mediaFile isKindOfType:@"movie"] ||
                   [mediaFile isKindOfType:@"tvShowEpisode"] ||
                   [mediaFile isKindOfType:@"clip"]) {
            displayedImage = [UIImage imageNamed:@"tvShow"];
        }
    }

    if (displayedImage)
        [_thumbnailCache setObject:displayedImage forKey:objID];

    return displayedImage;
}

- (UIImage *)thumbnailForShow:(MLShow *)mediaShow refreshCache:(BOOL)refreshCache
{
    NSManagedObjectID *objID = mediaShow.objectID;
    UIImage *displayedImage;
    BOOL forceRefresh = NO;

    NSUInteger count = [mediaShow.episodes count];
    NSNumber *previousCount = [_thumbnailCacheMetadata objectForKey:objID];

    if (previousCount.unsignedIntegerValue != count)
        forceRefresh = YES;

    if (refreshCache)
        forceRefresh = YES;

    if (!forceRefresh) {
        displayedImage = [_thumbnailCache objectForKey:objID];
        if (displayedImage)
            return displayedImage;
    }

    NSUInteger fileNumber = count > 3 ? 3 : count;
    NSArray *episodes = [mediaShow.episodes allObjects];
    NSMutableArray *files = [[NSMutableArray alloc] init];
    for (NSUInteger x = 0; x < count; x++) {
        /* this is a multi-threaded app, so the episode object might be there already,
         * but without an assigned file, so we need to check for its existance (#13128) */
        if ([episodes[x] files].anyObject != nil)
            [files addObject:[episodes[x] files].anyObject];
    }

    displayedImage = [self clusterThumbFromFiles:files andNumber:fileNumber blur:NO];
    if (displayedImage) {
        [_thumbnailCache setObject:displayedImage forKey:objID];
        [_thumbnailCacheMetadata setObject:@(count) forKey:objID];
    }

    return displayedImage;
}

- (UIImage *)thumbnailForLabel:(MLLabel *)mediaLabel refreshCache:(BOOL)refreshCache
{
    NSManagedObjectID *objID = mediaLabel.objectID;
    UIImage *displayedImage;
    BOOL forceRefresh = NO;

    NSUInteger count = [mediaLabel.files count];
    NSNumber *previousCount = [_thumbnailCacheMetadata objectForKey:objID];

    if (previousCount.unsignedIntegerValue != count)
        forceRefresh = YES;

    if (refreshCache)
        forceRefresh = YES;

    if (!forceRefresh) {
        displayedImage = [_thumbnailCache objectForKey:objID];
        if (displayedImage)
            return displayedImage;
    }

    NSUInteger fileNumber = count > 3 ? 3 : count;
    NSArray *files = [mediaLabel.files allObjects];

    displayedImage = [self clusterThumbFromFiles:files andNumber:fileNumber blur:YES];
    if (displayedImage) {
        [_thumbnailCache setObject:displayedImage forKey:objID];
        [_thumbnailCacheMetadata setObject:@(count) forKey:objID];
    }

    return displayedImage;
}

- (UIImage *)thumbnailForAlbum:(MLAlbum *)album refreshCache:(BOOL)refreshCache
{
    __block MLAlbumTrack *track = nil;
    void (^getFileBlock)(void) = ^(){
        track = [album tracks].anyObject;
    };
    if ([NSThread isMainThread])
        getFileBlock();
    else
        dispatch_sync(dispatch_get_main_queue(), getFileBlock);

    return [self thumbnailForAlbumTrack:track refreshCache:refreshCache];
}

- (UIImage *)thumbnailForAlbumTrack:(MLAlbumTrack *)albumTrack refreshCache:(BOOL)refreshCache
{
    __block MLFile *anyFileFromAnyTrack = nil;
    void (^getFileBlock)(void) = ^(){
        anyFileFromAnyTrack = [albumTrack anyFileFromTrack];
    };
    if ([NSThread isMainThread])
        getFileBlock();
    else
        dispatch_sync(dispatch_get_main_queue(), getFileBlock);
    return [self thumbnailForMediaFile:anyFileFromAnyTrack refreshCache:refreshCache];
}

- (UIImage *)clusterThumbFromFiles:(NSArray *)files andNumber:(NSUInteger)fileNumber blur:(BOOL)blurImage
{
    UIImage *clusterThumb;
    CGSize imageSize = CGSizeZero;
    // TODO: correct for watch
#ifndef TARGET_OS_WATCH
    if (_currentDeviceIdiom == UIUserInterfaceIdiomPad) {
        if ([UIScreen mainScreen].scale==2.0)
            imageSize = CGSizeMake(682., 384.);
        else
            imageSize = CGSizeMake(341., 192.);
    } else if (_currentDeviceIdiom == UIUserInterfaceIdiomPhone) {
        if ([UIScreen mainScreen].scale==2.0)
            imageSize = CGSizeMake(480., 270.);
        else
            imageSize = CGSizeMake(720., 405.);
    } else
#endif
    {
        if (WKInterfaceDevice.currentDevice != nil) {
            CGRect screenRect = WKInterfaceDevice.currentDevice.screenBounds;
            imageSize = CGSizeMake(screenRect.size.width * WKInterfaceDevice.currentDevice.screenScale, 120.);
        }
    }

    UIGraphicsBeginImageContext(imageSize);
    NSUInteger iter = files.count < fileNumber ? files.count : fileNumber;
    for (NSUInteger i = 0; i < iter; i++) {
        MLFile *file =  [files objectAtIndex:i];
        clusterThumb = [self thumbnailForMediaFile:file refreshCache:NO];
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGFloat imagePartWidth = (imageSize.width / iter);
        //the rect in which the image should be drawn
        CGRect clippingRect = CGRectMake(imagePartWidth * i, 0, imagePartWidth, imageSize.height);
        CGContextSaveGState(context);
        CGContextClipToRect(context, clippingRect);
        //take the center of the clippingRect and calculate the offset from the original center
        CGFloat centerOffset = (imagePartWidth * i + imagePartWidth / 2) - imageSize.width / 2;
        //shift the rect to draw the middle of the image in the clippingrect
        CGRect drawingRect = CGRectMake(centerOffset, 0, imageSize.width, imageSize.height);
        if (clusterThumb != nil)
            [clusterThumb drawInRect:drawingRect];
        //get rid of the old clippingRect
        CGContextRestoreGState(context);
    }
    clusterThumb = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if (!blurImage)
        return clusterThumb;
// TODO: When we move to watch os 4.0 we can include the blurcategory and remove the if else block
#ifndef TARGET_OS_WATCH
    return [UIImage applyBlurOnImage:clusterThumb withRadius:0.1];
#else
    return clusterThumb;
#endif
}

@end
