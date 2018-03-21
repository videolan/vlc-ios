/*****************************************************************************
 * MDFOSOFetcher.h
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
#import "MDFSubtitleItem.h"

@class MDFOSOFetcher;

@protocol MDFOSOFetcherDataRecipient <NSObject>

- (void)MDFOSOFetcher:(MDFOSOFetcher * _Nonnull)aFetcher readyToSearch:(BOOL)bValue;

@optional
- (void)MDFOSOFetcher:(MDFOSOFetcher * _Nonnull)aFetcher didFindSubtitles:(NSArray <MDFSubtitleItem *> * _Nonnull)subtitles forSearchRequest:(NSString * _Nonnull)searchRequest;
- (void)MDFOSOFetcher:(MDFOSOFetcher * _Nonnull)aFetcher didFailToFindSubtitlesForSearchRequest:(NSString * _Nonnull)searchRequest;

- (void)MDFOSOFetcher:(MDFOSOFetcher * _Nonnull)aFetcher subtitleDownloadSucceededForItem:(MDFSubtitleItem * _Nonnull)subtitleItem atPath:(NSString * _Nonnull)pathToFile;
- (void)MDFOSOFetcher:(MDFOSOFetcher * _Nonnull)aFetcher didFailToDownloadForItem:(MDFSubtitleItem * _Nonnull)subtitleItem;

@end


@interface MDFOSOFetcher : NSObject

/**
 * the object receiving the responses to requests send to instances of the fetcher
 * \param any NSObject implementing the MDFOSOFetcherDataRecipient protocol
 * \return the current receiver
 * \note should be set before doing any requests
 */
@property (weak, nonatomic) id<MDFOSOFetcherDataRecipient> dataRecipient;

- (void)prepareForFetching;

/**
 * the user-agent key to use for the fetches
 * \param the user-agent key to set [STRING]
 * \return the current user-agent key [STRING]
 * \note user-agent key must be set before doing any requests
 */
@property (retain, nonatomic, nonnull) NSString *userAgentKey;

/**
 * search for the list of languages potentially available on the website
 */
@property (readonly, nonatomic, copy) NSArray *availableLanguages;

/**
 * the language ID (ISO-639-3) to use for the fetches
 * \param the language ID to set [STRING]
 * \return the current language ID [STRING]
 * \note if none is set, the default value "eng" will be used
 */
@property (retain, nonnull, nonatomic) NSString *subtitleLanguageId;

/**
 * the query string to search for
 */
- (void)searchForSubtitlesWithQuery:(NSString * _Nonnull)query;

- (void)downloadSubtitleItem:(MDFSubtitleItem * _Nonnull)item toPath:(NSString * _Nonnull)path;

@end
