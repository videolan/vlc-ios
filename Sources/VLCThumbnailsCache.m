/*****************************************************************************
 * VLCThumbnailsCache.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Gleb Pinigin <gpinigin # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCThumbnailsCache.h"

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

+ (UIImage *)thumbnailForMediaFile:(MLFile *)mediaFile
{
    if (mediaFile == nil || mediaFile.objectID == nil)
        return nil;

    NSManagedObjectID *objID = mediaFile.objectID;
    UIImage *displayedImage = [_thumbnailCache objectForKey:objID];

    if (displayedImage)
        return displayedImage;

    displayedImage = mediaFile.computedThumbnail;
    if (displayedImage)
        [_thumbnailCache setObject:displayedImage forKey:objID];

    return displayedImage;
}

@end
