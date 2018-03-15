/*****************************************************************************
 * MDFMovieDBFetcher.h
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

@class MDFMovieDBFetcher;
@class MDFMovie;
@class MDFTVShow;

@protocol MDFMovieDBFetcherDataRecipient <NSObject>

@optional
- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher * _Nonnull)aFetcher didFindMovie:(MDFMovie * _Nonnull)details forSearchRequest:(NSString * _Nonnull)searchRequest;
- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher * _Nonnull)aFetcher didFailToFindMovieForSearchRequest:(NSString * _Nonnull)searchRequest;

- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher * _Nonnull)aFetcher didFindTVShow:(MDFTVShow * _Nullable)details forSearchRequest:(NSString * _Nonnull)searchRequest;
- (void)MDFMovieDBFetcher:(MDFMovieDBFetcher * _Nonnull)aFetcher didFailToFindTVShowForSearchRequest:(NSString * _Nonnull)searchRequest;

@end

@interface MDFMovieDBFetcher : NSObject

/**
 * the object receiving the responses to requests send to instances of the fetcher
 * \param any NSObject implementing the MDFMovieDBFetcherDataRecipient protocol
 * \return the current receiver
 * \note should be set before doing any requests
 */
@property (weak, nonatomic) id<MDFMovieDBFetcherDataRecipient> dataRecipient;

/**
 * The fetcher can process input strings by removing stray characters, file extensions, etc.,
 * which can lead to improve search results.
 * \param turn on/off the feature [BOOLEAN]
 * \return current state of the feature [BOOLEAN]
 * \note OFF by default
 */
 @property (nonatomic, readwrite) BOOL shouldDecrapifyInputStrings;

/**
 * this method cancels all requests currently performed by the fetcher
 */
- (void)cancelAllRequests;

/**
 * a convenience method to simply search for a movie
 * \param a string to search for [STRING]
 * \note in case of multiple results, the most popular is returned
 */
- (void)searchForMovie:(NSString * _Nonnull)searchRequest;

/**
 * the full method to search for a movie
 * \param a string to search for [STRING]
 * \param the release year [STRING]
 * \param the language to search in [ISO 639-1 code as STRING]
 * \param include adult content in search results [BOOLEAN]
 * \note in case of multiple results, the most popular is returned
 */
- (void)searchForMovie:(NSString * _Nonnull)searchRequest
           releaseYear:(NSString * _Nullable)releaseYear
              language:(NSString * _Nullable)languageCode
          includeAdult:(BOOL)includeAdult;

/**
 * the full method to search for a TV show
 * \param a string to search for [STRING]
 */
- (void)searchForTVShow:(NSString * _Nonnull)searchRequest;

/**
 * the full method to search for a TV show
 * \param a string to search for [STRING]
 * \param the year the show was aired first [STRING]
 * \param the language to search in [ISO 639-1 code as STRING]
 */
- (void)searchForTVShow:(NSString * _Nonnull)searchRequest firstAirYear:(NSString * _Nullable)firstAirYear language:(NSString * _Nullable)languageCode;

@end
