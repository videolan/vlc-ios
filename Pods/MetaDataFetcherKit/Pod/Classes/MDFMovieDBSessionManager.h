/*****************************************************************************
 * MDFMovieDBSessionManager.h
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
#import "AFNetworking.h"

@interface MDFMovieDBSessionManager : AFHTTPSessionManager

+ (_Nonnull instancetype)sharedInstance;

/**
 * the API key to use for the fetches
 * \param the API key to set [STRING]
 * \return the current API key [STRING]
 * \note API key must be set before doing any requests
 */
@property (retain, nonatomic, nonnull) NSString *apiKey;

/**
 * Indicates whether the manager successfully fetched the properties
 * \return property availibility [BOOLEAN]
 */
@property (readonly, nonatomic) BOOL hasFetchedProperties;

/**
 * the base URL for images, http [STRING]
 */
@property (readonly, nonatomic, nullable) NSString *imageBaseURL;
/**
 * the base URL for images, https [STRING]
 */
@property (readonly, nonatomic, nullable) NSString *secureImageBaseURL;

/**
 * available images sizes for backdrops, ordered small to large [Array]
 */
@property (readonly, nonatomic, nullable) NSArray *backdropSizes;
/**
 * available images sizes for logos, ordered small to large [Array]
 */
@property (readonly, nonatomic, nullable) NSArray *logoSizes;
/**
 * available images sizes for posters, ordered small to large [Array]
 */
@property (readonly, nonatomic, nullable) NSArray *posterSizes;
/**
 * available images sizes for stills, ordered small to large [Array]
 */
@property (readonly, nonatomic, nullable) NSArray *stillSizes;
/**
 * available images sizes for profiles, ordered small to large [Array]
 */
@property (readonly, nonatomic, nullable) NSArray *profileSizes;

/**
 * needs to be called once per object life time to fetch
 * the properties for image sizes */
- (void)fetchProperties;

@end
