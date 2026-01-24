/*****************************************************************************
 * VLCThumbnailsCache.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Gleb Pinigin <gpinigin # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@interface VLCThumbnailsCache : NSObject

+ (nullable UIImage *)thumbnailForURL:(nullable NSURL *)url;
+ (nullable UIImage *)minimizedThumbnailForURL:(nullable NSURL *)url;
+ (void)invalidateThumbnailForURL:(nullable NSURL *)url;

@end
