/*****************************************************************************
 * VLCThumbnailsCache.h
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

@interface VLCThumbnailsCache : NSObject

+ (UIImage *)thumbnailForManagedObject:(NSManagedObject *)object;

+ (UIImage *)thumbnailForManagedObject:(NSManagedObject *)object refreshCache:(BOOL)refreshCache;

+ (UIImage *)thumbnailForManagedObject:(NSManagedObject *)object refreshCache:(BOOL)refreshCache toFitRect:(CGRect)rect scale:(CGFloat)scale shouldReplaceCache:(BOOL)replaceCache;

@end
