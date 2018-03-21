/*****************************************************************************
 * MDFHatchetFetcher.h
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

@class MDFHatchetFetcher;
@class MDFArtist;
@class MDFMusicAlbum;

@protocol MDFHatchetFetcherDataRecipient <NSObject>

@optional
- (void)MDFHatchetFetcher:(MDFHatchetFetcher * _Nonnull)aFetcher didFindArtist:(MDFArtist * _Nonnull)artist forSearchRequest:(NSString * _Nonnull)searchRequest;
- (void)MDFHatchetFetcher:(MDFHatchetFetcher * _Nonnull)aFetcher didFailToFindArtistForSearchRequest:(NSString * _Nonnull)searchRequest;

- (void)MDFHatchetFetcher:(MDFHatchetFetcher * _Nonnull)aFetcher didFindAlbum:(MDFMusicAlbum * _Nonnull)album byArtist:(MDFArtist * _Nullable)artist forSearchRequest:(NSString * _Nonnull)searchRequest;
- (void)MDFHatchetFetcher:(MDFHatchetFetcher * _Nonnull)aFetcher didFailToFindAlbum:(NSString * _Nonnull)albumName forArtistName:(NSString * _Nonnull)artistName;

@end

@interface MDFHatchetFetcher : NSObject

/**
 * the object receiving the responses to requests send to instances of the fetcher
 * \param any NSObject implementing the MDFMovieDBFetcherDataRecipient protocol
 * \return the current receiver
 * \note should be set before doing any requests
 */
@property (weak, nonatomic) id<MDFHatchetFetcherDataRecipient> dataRecipient;

/**
 * this method cancels all requests currently performed by the fetcher
 */
- (void)cancelAllRequests;

- (void)searchForArtist:(NSString * _Nonnull)artistName;

- (void)searchForAlbum:(NSString * _Nonnull)albumName ofArtist:(NSString * _Nonnull)artistName;

@end
