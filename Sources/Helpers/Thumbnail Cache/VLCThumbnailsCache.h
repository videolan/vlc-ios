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
+ (nullable UIImage *)thumbnailForURL:(nullable NSURL *)url maxPixelSize:(CGFloat)maxPixelSize;
+ (void)invalidateThumbnailForURL:(nullable NSURL *)url;

+ (nullable UIImage *)cachedImageForURL:(nullable NSURL *)url;
+ (nullable UIImage *)cachedImageForURL:(nullable NSURL *)url maxPixelSize:(CGFloat)maxPixelSize;
+ (nullable UIImage *)imageFromData:(nullable NSData *)data forURL:(nullable NSURL *)url maxPixelSize:(CGFloat)maxPixelSize;

+ (nullable UIImage *)downsampledImageFromData:(nullable NSData *)data;
+ (nullable UIImage *)downsampledImageFromData:(nullable NSData *)data maxPixelSize:(CGFloat)maxPixelSize;

@end
