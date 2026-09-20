/*****************************************************************************
 * CPListTemplate+Genres.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022, 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "CPListTemplate+Genres.h"
#import "VLCCarPlayBrowserController.h"
#import "VLC-Swift.h"

@implementation CPListTemplate (Genres)

+ (CPListTemplate *)genreList
{
    CPListSection *listSection = [[CPListSection alloc] initWithItems:[self listOfGenres]];
    CPListTemplate *template = [[CPListTemplate alloc] initWithTitle:NSLocalizedString(@"GENRES", nil)
                                                                      sections:@[listSection]];
    template.tabTitle = NSLocalizedString(@"GENRES", nil);
    template.tabImage = [UIImage systemImageNamed:@"tag"];
    return template;
}

+ (NSArray *)listOfGenres
{
    NSArray *genres = [[VLCAppCoordinator sharedInstance].mediaLibraryService genresWithSortingCriteria:VLCMLSortingCriteriaDefault
                                                                                                   desc:NO];

    NSUInteger count = MIN(genres.count, [VLCCarPlayBrowserController maximumItemCount]);
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    UIImage *placeholder = [VLCCarPlayBrowserController placeholderForSymbol:@"tag"];

    for (NSUInteger x = 0; x < count; x++) {
        VLCMLGenre *genre = genres[x];
        NSArray<VLCMLArtist *> *artists = genre.artists;

        UIImage *genreImage;
        NSUInteger artistCount = MIN(artists.count, (NSUInteger)8);
        for (NSUInteger index = 0; index < artistCount; index++) {
            genreImage = [VLCThumbnailsCache thumbnailForURL:artists[index].artworkMRL];
            if (genreImage) {
                break;
            }
        }
        if (!genreImage) {
            genreImage = placeholder;
        }

        CPListItem *listItem = [[CPListItem alloc] initWithText:genre.name
                                                     detailText:genre.numberOfTracksString
                                                          image:genreImage];

        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            [[VLCPlaybackService sharedInstance] playCollection:[genre tracks]];
            completionBlock();
        };
        [itemList addObject:listItem];
    }

    return itemList;
}

@end
