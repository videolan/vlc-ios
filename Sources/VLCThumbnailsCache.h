/*****************************************************************************
 * VLCThumbnailsCache.h
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

#import <Foundation/Foundation.h>

@interface VLCThumbnailsCache : NSObject

+ (UIImage *)thumbnailForMediaFile:(MLFile *)mediaFile;

@end
