/*****************************************************************************
 * MDFOSOFetcher.m
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

#import "MDFOSOFetcher.h"
#import "OROpenSubtitleDownloader.h"

@interface MDFOSOFetcher () <OROpenSubtitleDownloaderDelegate>
{
    NSMutableArray<NSURLSessionTask *> *_requests;
    OROpenSubtitleDownloader *_subtitleDownloader;
    BOOL _readyForFetching;
}
@end

@implementation MDFOSOFetcher

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
    if (!_userAgentKey) {
        if (self.dataRecipient) {
            if ([self.dataRecipient respondsToSelector:@selector(MDFOSOFetcher:readyToSearch:)]) {
                [self.dataRecipient MDFOSOFetcher:self readyToSearch:NO];
            }
        } else
            NSLog(@"%s: no user agent set", __PRETTY_FUNCTION__);
    }
    _subtitleDownloader = [[OROpenSubtitleDownloader alloc] initWithUserAgent:_userAgentKey];

    [self searchForAvailableLanguages];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%s: user-agent '%@', language ID '%@'", __PRETTY_FUNCTION__, _userAgentKey, _subtitleLanguageId];
}

- (void)searchForSubtitlesWithQuery:(NSString *)query
{
    [_subtitleDownloader setLanguageString:_subtitleLanguageId];
    [_subtitleDownloader searchForSubtitlesWithQuery:query :^(NSArray *subtitles, NSError *error){
        if (!subtitles || error) {
            if (self.dataRecipient) {
                if ([self.dataRecipient respondsToSelector:@selector(MDFOSOFetcher:didFailToFindSubtitlesForSearchRequest:)]) {
                    [self.dataRecipient MDFOSOFetcher:self didFailToFindSubtitlesForSearchRequest:query];
                }
            } else
                NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
        }

        NSUInteger count = subtitles.count;
        NSMutableArray *subtitlesToReturn = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger x = 0; x < count; x++) {
            OpenSubtitleSearchResult *result = subtitles[x];
            MDFSubtitleItem *item = [[MDFSubtitleItem alloc] init];
            item.name = result.subtitleName;
            item.format = result.subtitleFormat;
            item.language = result.subtitleLanguage;
            item.iso639Language = result.iso639Language;
            item.downloadAddress = result.subtitleDownloadAddress;
            item.rating = result.subtitleRating;
            [subtitlesToReturn addObject:item];
        }

        if (self.dataRecipient) {
            if ([self.dataRecipient respondsToSelector:@selector(MDFOSOFetcher:didFindSubtitles:forSearchRequest:)]) {
                [self.dataRecipient MDFOSOFetcher:self didFindSubtitles:[subtitlesToReturn copy] forSearchRequest:query];
            }
        } else
            NSLog(@"found %@", subtitlesToReturn);
     }];
}

- (void)searchForAvailableLanguages
{
    [_subtitleDownloader supportedLanguagesList:^(NSArray *langauges, NSError *aError){
        if (!langauges || aError) {
            NSLog(@"%s: no languages found or error %@", __PRETTY_FUNCTION__, aError);
        }

        NSUInteger count = langauges.count;
        NSMutableArray *languageItems = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger x = 0; x < count; x++) {
            OpenSubtitleLanguageResult *result = langauges[x];
            MDFSubtitleLanguage *item = [[MDFSubtitleLanguage alloc] init];
            item.ID = result.subLanguageID;
            item.iso639Language = result.iso639Language;
            item.localizedName = result.localizedLanguageName;
            [languageItems addObject:item];
        }

        _availableLanguages = [languageItems copy];

        [self openSubtitlerDidLogIn:nil];
    }];
}
- (void)openSubtitlerDidLogIn:(OROpenSubtitleDownloader *)downloader
{
    _readyForFetching = YES;

    if (self.dataRecipient) {
        if ([self.dataRecipient respondsToSelector:@selector(MDFOSOFetcher:readyToSearch:)]) {
            [self.dataRecipient MDFOSOFetcher:self readyToSearch:YES];
        }
    }
}

- (void)downloadSubtitleItem:(MDFSubtitleItem *)item toPath:(NSString *)path
{
    OpenSubtitleSearchResult *result = [[OpenSubtitleSearchResult alloc] init];
    result.subtitleDownloadAddress = item.downloadAddress;
    [_subtitleDownloader downloadSubtitlesForResult:result toPath:path :^(NSString *path, NSError *error) {
        if (self.dataRecipient) {
            if (error) {
                if ([self.dataRecipient respondsToSelector:@selector(MDFOSOFetcher:didFailToDownloadForItem:)]) {
                    [self.dataRecipient MDFOSOFetcher:self didFailToDownloadForItem:item];
                }
            } else {
                if ([self.dataRecipient respondsToSelector:@selector(MDFOSOFetcher:subtitleDownloadSucceededForItem:atPath:)]) {
                    [self.dataRecipient MDFOSOFetcher:self subtitleDownloadSucceededForItem:item atPath:path];
                }
            }
        } else
            NSLog(@"%s: path %@ error %@", __PRETTY_FUNCTION__, path, error);
    }];
}

@end
