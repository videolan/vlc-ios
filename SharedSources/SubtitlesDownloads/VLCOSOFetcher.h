/*****************************************************************************
* VLCOSOFetcher.h
* VLC for iOS
*****************************************************************************
* Copyright (c) 2015, 2020 VideoLAN. All rights reserved.
* $Id$
*
* Author: Felix Paul Kühne <fkuehne # videolan.org>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

@class VLCSubtitleItem;
@class VLCOSOFetcher;

@protocol VLCOSOFetcherDataRecipient <NSObject>

- (void)VLCOSOFetcherReadyToSearch:(VLCOSOFetcher * _Nonnull)aFetcher;

@optional
- (void)VLCOSOFetcher:(VLCOSOFetcher * _Nonnull)aFetcher didFindSubtitles:(NSArray <VLCSubtitleItem *> * _Nonnull)subtitles forSearchRequest:(NSString * _Nonnull)searchRequest;
- (void)VLCOSOFetcher:(VLCOSOFetcher * _Nonnull)aFetcher didFailToFindSubtitlesForSearchRequest:(NSString * _Nonnull)searchRequest;

- (void)VLCOSOFetcher:(VLCOSOFetcher * _Nonnull)aFetcher subtitleDownloadSucceededForItem:(VLCSubtitleItem * _Nonnull)subtitleItem atPath:(NSString * _Nonnull)pathToFile;
- (void)VLCOSOFetcher:(VLCOSOFetcher * _Nonnull)aFetcher didFailToDownloadForItem:(VLCSubtitleItem * _Nonnull)subtitleItem;

@end

@interface VLCOSOFetcher : NSObject

/**
 * the object receiving the responses to requests send to instances of the fetcher
 * param: any NSObject implementing the VLCOSOFetcherDataRecipient protocol
 * \return the current receiver
 * \note should be set before doing any requests
 */
@property (weak, nonatomic, nullable) id <VLCOSOFetcherDataRecipient> dataRecipient;

- (void)prepareForFetching;

/**
 * search for the list of languages potentially available on the website
 */
@property (readonly, nonatomic, copy, nullable) NSArray *availableLanguages;

/**
 * the language ID (ISO-639-3) to use for the fetches
 * param: the language ID to set [STRING]
 * \return the current language ID [STRING]
 * \note if none is set, the default value "eng" will be used
 */
@property (retain, nonnull, nonatomic) NSString *subtitleLanguageId;

/**
 * the query string to search for
 */
- (void)searchForSubtitlesWithQuery:(NSString * _Nonnull)query;

- (void)downloadSubtitleItem:(VLCSubtitleItem * _Nonnull)item toPath:(NSString * _Nonnull)path;

@end
