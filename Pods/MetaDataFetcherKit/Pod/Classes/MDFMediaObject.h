/*****************************************************************************
 * MDFMediaObject.h
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

@interface MDFMediaObject : NSObject

/**
 * indicates whether the database assumes that the object is NSFW [BOOL]
 */
@property (readwrite, nonatomic) BOOL isAdultContent;
/**
 * the original language of the content [ISO 639-1 code as STRING]
 */
@property (readwrite, nonatomic, nullable) NSString *originalLanguage;
/**
 * the original title of the content [STRING]
 */
@property (readwrite, nonatomic, nullable) NSString *originalTitle;
/**
 * the title of the content, which maybe in the requested language [STRING]
 */
@property (readwrite, nonatomic, nullable) NSString *title;
/**
 * description of the content, which maybe in the requested language [STRING]
 */
@property (readwrite, nonatomic, nullable) NSString *contentDescription;
/**
 * the original release date of the content [STRING]
 */
@property (readwrite, nonatomic, nullable) NSDate *releaseDate;

/**
 * the path to the poster image [STRING]
 * \note you need to merge it with the image base URL provided by the MDFMovieDBSessionManager
 */
@property (readwrite, nonatomic, nullable) NSString *posterPath;
/**
 * the path to the backdrop image [STRING]
 * \note you need to merge it with the image base URL provided by the MDFMovieDBSessionManager
 */
@property (readwrite, nonatomic, nullable) NSString *backdropPath;

/**
 * An internal ID, which can be used to ask the MDFMovieDBFetcher for more details
 * about this content object [NSInteger]
 */
@property (readwrite, nonatomic) NSInteger movieDBID;

@end
