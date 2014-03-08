/*****************************************************************************
 * VLCThumbnailsCache.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Gleb Pinigin <gpinigin # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCThumbnailsCache.h"
#import <CommonCrypto/CommonDigest.h>

static NSInteger MaxCacheSize;
static NSCache *_thumbnailCache;

@implementation VLCThumbnailsCache

#define MAX_CACHE_SIZE_IPHONE 21  // three times the number of items shown on iPhone 5
#define MAX_CACHE_SIZE_IPAD   27  // three times the number of items shown on iPad

+(void)initialize
{
    MaxCacheSize = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?
                                MAX_CACHE_SIZE_IPAD: MAX_CACHE_SIZE_IPHONE;

    _thumbnailCache = [[NSCache alloc] init];
    [_thumbnailCache setCountLimit: MaxCacheSize];
}

+ (NSString *)_md5FromString:(NSString *)string
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
    return [UIImage imageWithContentsOfFile:[self artworkPathForMediaItemWithTitle:title Artist:artist andAlbumName:albumname]];
}

+ (NSString *)artworkPathForMediaItemWithTitle:(NSString *)title Artist:(NSString*)artist andAlbumName:(NSString*)albumname
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

+ (NSString *)_getArtworkPathFromMedia:(MLFile *)file
{
    NSString *artist, *album, *title;

    if (file.isAlbumTrack) {
        artist = file.albumTrack.artist;
        album = file.albumTrack.album.name;
    }
    title = file.title;

    return [self artworkPathForMediaItemWithTitle:title Artist:artist andAlbumName:album];
}

+ (UIImage *)thumbnailForMediaFile:(MLFile *)mediaFile
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

+ (UIImage *)thumbnailForShow:(MLShow *)mediaShow
{
    NSManagedObjectID *objID = mediaShow.objectID;
    UIImage *displayedImage = [_thumbnailCache objectForKey:objID];

    if (displayedImage)
        return displayedImage;

    NSUInteger count = [mediaShow.episodes count];
    NSUInteger fileNumber = count > 3 ? 3 : count;
    NSArray *episodes = [mediaShow.episodes allObjects];
    NSMutableArray *files = [[NSMutableArray alloc] init];
    for (NSUInteger x = 0; x < count; x++)
        [files addObject:[episodes[x] files].anyObject];

    displayedImage = [self clusterThumbFromFiles:files andNumber:fileNumber];
    if (displayedImage)
        [_thumbnailCache setObject:displayedImage forKey:objID];

    return displayedImage;
}

+ (UIImage *)thumbnailForLabel:(MLLabel *)mediaLabel
{
    NSManagedObjectID *objID = mediaLabel.objectID;
    UIImage *displayedImage = [_thumbnailCache objectForKey:objID];

    if (displayedImage)
        return displayedImage;

    NSUInteger count = [mediaLabel.files count];
    NSUInteger fileNumber = count > 3 ? 3 : count;
    NSArray *files = [mediaLabel.files allObjects];
    displayedImage = [self clusterThumbFromFiles:files andNumber:fileNumber];
    if (displayedImage)
        [_thumbnailCache setObject:displayedImage forKey:objID];

    return displayedImage;
}

+ (UIImage *)clusterThumbFromFiles:(NSArray *)files andNumber:(NSUInteger)fileNumber
{
    UIImage *clusterThumb;
    CGSize imageSize;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if ([UIScreen mainScreen].scale==2.0)
            imageSize = CGSizeMake(540., 405.);
        else
            imageSize = CGSizeMake(272, 204.);
    } else {
        if (SYSTEM_RUNS_IOS7_OR_LATER)
            imageSize = CGSizeMake(480., 270.);
        else {
            if ([UIScreen mainScreen].scale==2.0)
                imageSize = CGSizeMake(480., 270.);
            else
                imageSize = CGSizeMake(540., 405.);
        }
    }

    UIGraphicsBeginImageContext(imageSize);
    for (NSUInteger i = 0; i < fileNumber; i++) {
        MLFile *file =  [files objectAtIndex:i];
        clusterThumb = [VLCThumbnailsCache thumbnailForMediaFile:file];
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGFloat imagePartWidth = (imageSize.width / fileNumber);
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

    return clusterThumb;
}

@end
