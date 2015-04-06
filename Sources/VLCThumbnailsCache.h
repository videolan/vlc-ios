/*****************************************************************************
 * VLCThumbnailsCache.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
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

+ (UIImage *)thumbnailForMediaItemWithTitle:(NSString *)title Artist:(NSString*)artist andAlbumName:(NSString*)albumname;

@end
