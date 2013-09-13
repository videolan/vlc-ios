//
//  VLCThumbnailsCache.m
//  VLC for iOS
//
//  Created by Gleb on 9/13/13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCThumbnailsCache.h"

static NSInteger MaxCacheSize;
static NSMutableArray *_thumbnailCacheIndex = nil;
static NSMutableDictionary *_thumbnailCache = nil;

@implementation VLCThumbnailsCache

#define MAX_CACHE_SIZE_IPHONE 21  // three times the number of items shown on iPhone 5
#define MAX_CACHE_SIZE_IPAD   27  // three times the number of items shown on iPad

+(void)initialize
{
    MaxCacheSize = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?
                                MAX_CACHE_SIZE_IPAD: MAX_CACHE_SIZE_IPHONE;

    // TODO Consider to use NSCache
    _thumbnailCache = [[NSMutableDictionary alloc] initWithCapacity:MaxCacheSize];
    _thumbnailCacheIndex = [[NSMutableArray alloc] initWithCapacity:MaxCacheSize];
}

+ (UIImage *)thumbnailForMediaFile:(MLFile *)mediaFile
{
    if (mediaFile == nil || mediaFile.objectID == nil)
        return nil;

    NSManagedObjectID *objID = mediaFile.objectID;
    UIImage *displayedImage = nil;
    if ([_thumbnailCacheIndex containsObject:objID]) {
        [_thumbnailCacheIndex removeObject:objID];
        [_thumbnailCacheIndex insertObject:objID atIndex:0];
        displayedImage = [_thumbnailCache objectForKey:objID];
        if (!displayedImage && mediaFile.computedThumbnail) {
            displayedImage = mediaFile.computedThumbnail;
            [_thumbnailCache setObject:displayedImage forKey:objID];
        }
    } else {
        if (_thumbnailCacheIndex.count >= MaxCacheSize) {
            [_thumbnailCache removeObjectForKey:[_thumbnailCacheIndex lastObject]];
            [_thumbnailCacheIndex removeLastObject];
        }
        displayedImage = mediaFile.computedThumbnail;

        if (displayedImage) {
            [_thumbnailCache setObject:displayedImage forKey:objID];
            [_thumbnailCacheIndex insertObject:objID atIndex:0];
        }
    }

    return displayedImage;
}

@end
