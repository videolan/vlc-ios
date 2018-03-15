/*****************************************************************************
 * MDFArtist.h
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

@interface MDFArtist : NSObject

/**
 * the name of the artist [STRING]
 */
@property (readwrite, nonatomic, nullable) NSString *name;

/**
 * a biography abstract of the artist, usually 3 to 4 short paragraphs [STRING];
 */
@property (readwrite, nonatomic, nullable) NSString *biography;

/**
 * medium sized image URL string(s) with a width < 1000px
 * \note base URL included
 */
@property (readwrite, nonatomic, nullable) NSArray<NSString *> *mediumSizedImages;

/**
 * medium sized image URL string(s) with a width < 1000px and a height > width
 * \note base URL included
 */
@property (readwrite, nonatomic, nullable) NSArray<NSString *> *mediumSizedPortraitImages;

/**
 * medium sized image URL string(s) with a width < 1000px and a height < width
 * \note base URL included
 */
@property (readwrite, nonatomic, nullable) NSArray<NSString *> *mediumSizedLandscapeImages;

/**
 * large image URL string(s) with a width > 1000px
 * \note base URL included
 */
@property (readwrite, nonatomic, nullable) NSArray<NSString *> *largeSizedImages;

/**
 * large image URL string(s) with a width > 1000px and a height > width
 * \note base URL included
 */
@property (readwrite, nonatomic, nullable) NSArray<NSString *> *largeSizedPortraitImages;

/**
 * large image URL string(s) with a width > 1000px and a height < width
 * \note base URL included
 */
@property (readwrite, nonatomic, nullable) NSArray<NSString *> *largeSizedLandscapeImages;

/**
 * the Hatchet id of the artist [NSInteger]
 */
@property (readwrite, nonatomic) NSInteger hatchetArtistID;

@end
