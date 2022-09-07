/*****************************************************************************
* VLCOSOFetcher.m
* VLC for iOS
*****************************************************************************
* Copyright (c) 2015, 2020 VideoLAN. All rights reserved.
* $Id$
*
* Author: Felix Paul Kühne <fkuehne # videolan.org>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

#import "VLCOSOFetcher.h"
#import "VLCSubtitleItem.h"
#import "OROpenSubtitleDownloader.h"

NSString *VLCOSOFetcherUserAgentKey = @"VLSub 0.9";

@interface VLCOSOFetcher () <OROpenSubtitleDownloaderDelegate>
{
    NSMutableArray<NSURLSessionTask *> *_requests;
    OROpenSubtitleDownloader *_subtitleDownloader;
}
@end

@implementation VLCOSOFetcher

- (instancetype)init
{
    self = [super init];

    if (self) {
        _subtitleLanguageId = @"eng";
    }

    return self;
}

- (void)prepareForFetching
{
    _subtitleDownloader = [[OROpenSubtitleDownloader alloc] initWithUserAgent:VLCOSOFetcherUserAgentKey];
    [self searchForAvailableLanguages];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%s: language ID '%@'", __PRETTY_FUNCTION__, _subtitleLanguageId];
}

- (void)searchForSubtitlesWithQuery:(NSString *)query
{
    [_subtitleDownloader setLanguageString:_subtitleLanguageId];
    [_subtitleDownloader searchForSubtitlesWithQuery:query :^(NSArray *subtitles, NSError *error){
        if (!subtitles || error) {
            if (self.dataRecipient) {
                if ([self.dataRecipient respondsToSelector:@selector(VLCOSOFetcher:didFailToFindSubtitlesForSearchRequest:)]) {
                    [self.dataRecipient VLCOSOFetcher:self didFailToFindSubtitlesForSearchRequest:query];
                }
            } else
                APLog(@"%s: %@", __PRETTY_FUNCTION__, error);
        }

        NSUInteger count = subtitles.count;
        NSMutableArray *subtitlesToReturn = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger x = 0; x < count; x++) {
            OpenSubtitleSearchResult *result = subtitles[x];
            VLCSubtitleItem *item = [[VLCSubtitleItem alloc] init];
            item.name = result.subtitleName;
            item.format = result.subtitleFormat;
            item.language = result.subtitleLanguage;
            item.iso639Language = result.iso639Language;
            item.downloadAddress = result.subtitleDownloadAddress;
            item.rating = result.subtitleRating;
            [subtitlesToReturn addObject:item];
        }

        if (self.dataRecipient) {
            if ([self.dataRecipient respondsToSelector:@selector(VLCOSOFetcher:didFindSubtitles:forSearchRequest:)]) {
                [self.dataRecipient VLCOSOFetcher:self didFindSubtitles:[subtitlesToReturn copy] forSearchRequest:query];
            }
        } else
            APLog(@"found %@", subtitlesToReturn);
     }];
}

- (void)searchForAvailableLanguages
{
    [_subtitleDownloader supportedLanguagesList:^(NSArray *languages, NSError *aError){
        if (!languages || aError) {
            APLog(@"%s: no languages found or error %@", __PRETTY_FUNCTION__, aError);
        }

        NSUInteger count = languages.count;
        NSMutableArray *languageItems = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger x = 0; x < count; x++) {
            OpenSubtitleLanguageResult *result = languages[x];
            VLCSubtitleLanguage *item = [[VLCSubtitleLanguage alloc] init];
            item.ID = result.subLanguageID;
            item.iso639Language = result.iso639Language;
            item.localizedName = result.localizedLanguageName;
            [languageItems addObject:item];
        }

        self->_availableLanguages = [languageItems copy];

        [self openSubtitlerDidLogIn:nil];
    }];
}

- (void)openSubtitlerDidLogIn:(OROpenSubtitleDownloader *)downloader
{
    if (self.dataRecipient) {
        if ([self.dataRecipient respondsToSelector:@selector(VLCOSOFetcherReadyToSearch:)]) {
            [self.dataRecipient VLCOSOFetcherReadyToSearch:self];
        }
    }
}

- (void)downloadSubtitleItem:(VLCSubtitleItem *)item toPath:(NSString *)path
{
    OpenSubtitleSearchResult *result = [[OpenSubtitleSearchResult alloc] init];
    result.subtitleDownloadAddress = item.downloadAddress;
    [_subtitleDownloader downloadSubtitlesForResult:result toPath:path :^(NSString *path, NSError *error) {
        if (self.dataRecipient) {
            if (error) {
                if ([self.dataRecipient respondsToSelector:@selector(VLCOSOFetcher:didFailToDownloadForItem:)]) {
                    [self.dataRecipient VLCOSOFetcher:self didFailToDownloadForItem:item];
                }
            } else {
                if ([self.dataRecipient respondsToSelector:@selector(VLCOSOFetcher:subtitleDownloadSucceededForItem:atPath:)]) {
                    [self.dataRecipient VLCOSOFetcher:self subtitleDownloadSucceededForItem:item atPath:path];
                }
            }
        } else
            APLog(@"%s: path %@ error %@", __PRETTY_FUNCTION__, path, error);
    }];
}

@end
