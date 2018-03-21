/*****************************************************************************
 * MDFMusicAlbum.h
 *****************************************************************************
 * Copyright (C) 2015 Felix Paul Kühne
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import <Foundation/Foundation.h>

@interface MDFMusicAlbum : NSObject

/**
 * the name of the album [STRING]
 */
@property (readwrite, nonatomic, nullable) NSString *name;

/**
 * the release date of the album [DATE]
 */
@property (readwrite, nonatomic, nullable) NSDate *releaseDate;

/**
 * album artwork URL string
 * \note base URL included
 */
@property (readwrite, nonatomic, nullable) NSString *artworkImage;

/**
 * medium sized image URL string(s) with a width < 1000px
 * \note base URL included
 */
@property (readwrite, nonatomic, nullable) NSArray<NSString *> *mediumSizedArtistImages;

/**
 * medium sized image URL string(s) with a width < 1000px and a height > width
 * \note base URL included
 */
@property (readwrite, nonatomic, nullable) NSArray<NSString *> *mediumSizedPortraitArtistImages;

/**
 * medium sized image URL string(s) with a width < 1000px and a height < width
 * \note base URL included
 */
@property (readwrite, nonatomic, nullable) NSArray<NSString *> *mediumSizedLandscapeArtistImages;

/**
 * large image URL string(s) with a width > 1000px
 * \note base URL included
 */
@property (readwrite, nonatomic, nullable) NSArray<NSString *> *largeSizedArtistImages;

/**
 * large image URL string(s) with a width > 1000px and a height > width
 * \note base URL included
 */
@property (readwrite, nonatomic, nullable) NSArray<NSString *> *largeSizedPortraitArtistImages;

/**
 * large image URL string(s) with a width > 1000px and a height < width
 * \note base URL included
 */
@property (readwrite, nonatomic, nullable) NSArray<NSString *> *largeSizedLandscapeArtistImages;

/**
 * the Hatchet id of the album [NSInteger]
 */
@property (readwrite, nonatomic) NSInteger hatchetAlbumID;

/**
 * the Hatchet id of the album artist [NSInteger]
 */
@property (readwrite, nonatomic) NSInteger hatchetArtistID;


@end
