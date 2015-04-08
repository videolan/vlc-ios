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
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLC for iOS-Prefix.pch"
#import "VLCThumbnailsCache.h"
#import <CommonCrypto/CommonDigest.h>
#import "UIImage+Blur.h"
#import <WatchKit/WatchKit.h>

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

- (NSString *)_md5FromString:(NSString *)string
{
    const char *ptr = [string UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(ptr, (unsigned int)strlen(ptr), md5Buffer);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];

    return [NSString stringWithString:output];
}

+ (UIImage *)thumbnailForMediaItemWithTitle:(NSString *)title Artist:(NSString*)artist andAlbumName:(NSString*)albumname
{
    return [UIImage imageWithContentsOfFile:[[VLCThumbnailsCache sharedThumbnailCache] artworkPathForMediaItemWithTitle:title Artist:artist andAlbumName:albumname]];
}

- (NSString *)artworkPathForMediaItemWithTitle:(NSString *)title Artist:(NSString*)artist andAlbumName:(NSString*)albumname
{
    NSString *artworkURL;
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDir = searchPaths[0];
    cacheDir = [cacheDir stringByAppendingFormat:@"/%@", [[NSBundle mainBundle] bundleIdentifier]];

    if (artist.length == 0 || albumname.length == 0) {
        /* Use generated hash to find art */
        artworkURL = [cacheDir stringByAppendingFormat:@"/art/arturl/%@/art.jpg", [self _md5FromString:title]];
    } else {
        /* Otherwise, it was cached by artist and album */
        artworkURL = [cacheDir stringByAppendingFormat:@"/art/artistalbum/%@/%@/art.jpg", artist, albumname];
    }

    return artworkURL;
}

- (NSString *)_getArtworkPathFromMedia:(MLFile *)file
{
    NSString *artist, *album, *title;

    if (file.isAlbumTrack) {
        artist = file.albumTrack.artist;
        album = file.albumTrack.album.name;
    }
    title = file.title;

    return [self artworkPathForMediaItemWithTitle:title Artist:artist andAlbumName:album];
}

+ (UIImage *)thumbnailForManagedObject:(NSManagedObject *)object
{
    UIImage *thumbnail;
    VLCThumbnailsCache *cache = [VLCThumbnailsCache sharedThumbnailCache];
    if ([object isKindOfClass:[MLShow class]]) {
        thumbnail = [cache thumbnailForShow:(MLShow *)object];
    } else if ([object isKindOfClass:[MLShowEpisode class]]) {
        MLFile *anyFileFromEpisode = [(MLShowEpisode *)object files].anyObject;
        thumbnail = [cache thumbnailForMediaFile:anyFileFromEpisode];
    } else if ([object isKindOfClass:[MLLabel class]]) {
        thumbnail = [cache thumbnailForLabel:(MLLabel *)object];
    } else if ([object isKindOfClass:[MLAlbum class]]) {
        MLFile *anyFileFromAnyTrack = [[(MLAlbum *)object tracks].anyObject files].anyObject;
        thumbnail = [cache thumbnailForMediaFile:anyFileFromAnyTrack];
    } else if ([object isKindOfClass:[MLAlbumTrack class]]) {
        MLFile *anyFileFromTrack = [(MLAlbumTrack *)object files].anyObject;
        thumbnail = [cache thumbnailForMediaFile:anyFileFromTrack];
    } else {
        thumbnail = [cache thumbnailForMediaFile:(MLFile *)object];
    }
    return thumbnail;
}

- (UIImage *)thumbnailForMediaFile:(MLFile *)mediaFile
{
    if (mediaFile == nil || mediaFile.objectID == nil)
        return nil;

    NSManagedObjectID *objID = mediaFile.objectID;
    UIImage *displayedImage = [_thumbnailCache objectForKey:objID];

    if (displayedImage)
        return displayedImage;

    if (mediaFile.isAlbumTrack || mediaFile.isShowEpisode)
        displayedImage = [UIImage imageWithContentsOfFile:[self _getArtworkPathFromMedia:mediaFile]];

    if (!displayedImage)
        displayedImage = mediaFile.computedThumbnail;

    if (displayedImage)
        [_thumbnailCache setObject:displayedImage forKey:objID];

    return displayedImage;
}

- (UIImage *)thumbnailForShow:(MLShow *)mediaShow
{
    NSManagedObjectID *objID = mediaShow.objectID;
    UIImage *displayedImage;
    BOOL forceRefresh = NO;

    NSUInteger count = [mediaShow.episodes count];
    NSNumber *previousCount = [_thumbnailCacheMetadata objectForKey:objID];

    if (previousCount.unsignedIntegerValue != count)
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

- (UIImage *)thumbnailForLabel:(MLLabel *)mediaLabel
{
    NSManagedObjectID *objID = mediaLabel.objectID;
    UIImage *displayedImage;
    BOOL forceRefresh = NO;

    NSUInteger count = [mediaLabel.files count];
    NSNumber *previousCount = [_thumbnailCacheMetadata objectForKey:objID];

    if (previousCount.unsignedIntegerValue != count)
        forceRefresh = YES;

    if (!forceRefresh) {
        displayedImage = [_thumbnailCache objectForKey:objID];
        if (displayedImage)
            return displayedImage;
    }

    NSUInteger fileNumber = count > 3 ? 3 : count;
    NSArray *files = [mediaLabel.files allObjects];
    BOOL blur = NO;
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        blur = YES;
    displayedImage = [self clusterThumbFromFiles:files andNumber:fileNumber blur:blur];
    if (displayedImage) {
        [_thumbnailCache setObject:displayedImage forKey:objID];
        [_thumbnailCacheMetadata setObject:@(count) forKey:objID];
    }

    return displayedImage;
}

- (UIImage *)clusterThumbFromFiles:(NSArray *)files andNumber:(NSUInteger)fileNumber blur:(BOOL)blurImage
{
    UIImage *clusterThumb;
    CGSize imageSize;
    if (_currentDeviceIdiom == UIUserInterfaceIdiomPad) {
        if ([UIScreen mainScreen].scale==2.0)
            imageSize = CGSizeMake(682., 384.);
        else
            imageSize = CGSizeMake(341., 192.);
    } else if (_currentDeviceIdiom == UIUserInterfaceIdiomPhone) {
        if (SYSTEM_RUNS_IOS7_OR_LATER) {
            if ([UIScreen mainScreen].scale==2.0)
                imageSize = CGSizeMake(480., 270.);
            else
                imageSize = CGSizeMake(720., 405.);
        } else {
            if ([UIScreen mainScreen].scale==2.0)
                imageSize = CGSizeMake(258., 145.);
            else
                imageSize = CGSizeMake(129., 73.);
        }
    } else {
        if (SYSTEM_RUNS_IOS82_OR_LATER) {
            if (WKInterfaceDevice.currentDevice != nil) {
                CGRect screenRect = WKInterfaceDevice.currentDevice.screenBounds;
                imageSize = CGSizeMake(screenRect.size.width * WKInterfaceDevice.currentDevice.screenScale, 120.);
            }
        }
    }

    UIGraphicsBeginImageContext(imageSize);
    NSUInteger iter = files.count < fileNumber ? files.count : fileNumber;
    for (NSUInteger i = 0; i < iter; i++) {
        MLFile *file =  [files objectAtIndex:i];
        clusterThumb = [self thumbnailForMediaFile:file];
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
        [clusterThumb drawInRect:drawingRect];
        //get rid of the old clippingRect
        CGContextRestoreGState(context);
    }
    clusterThumb = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if (!blurImage)
        return clusterThumb;

    return [UIImage applyBlurOnImage:clusterThumb withRadius:0.1];
}

@end
