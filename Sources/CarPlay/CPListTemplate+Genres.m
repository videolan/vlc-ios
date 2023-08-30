/*****************************************************************************
 * CPListTemplate+Albums.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "CPListTemplate+Genres.h"
#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@implementation CPListTemplate (Genres)

+ (CPListTemplate *)genreList
{
    CPListSection *listSection = [[CPListSection alloc] initWithItems:[self listOfGenres]];
    CPListTemplate *template = [[CPListTemplate alloc] initWithTitle:NSLocalizedString(@"GENRES", nil)
                                                                      sections:@[listSection]];
    template.tabTitle = NSLocalizedString(@"GENRES", nil);
    template.tabImage = [UIImage imageNamed:@"cp-Genre"];
    return template;
}

+ (NSArray *)listOfGenres
{
    NSArray *genres = [[VLCAppCoordinator sharedInstance].mediaLibraryService genresWithSortingCriteria:VLCMLSortingCriteriaDefault
                                                                                                   desc:NO];

    NSUInteger count = genres.count;
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    for (NSUInteger x = 0; x < count; x++) {
        CPListItem *listItem;

        VLCMLGenre *iter = genres[x];
        NSArray *artists = iter.artists;

        UIImage *genreImage;
        for (VLCMLArtist *artist in artists) {
            genreImage = [VLCThumbnailsCache thumbnailForURL:artist.artworkMRL];
            if (genreImage)
                break;
        }
        if (!genreImage) {
            genreImage = [UIImage imageNamed:@"cp-Genre"];
        }

        listItem = [[CPListItem alloc] initWithText:iter.name detailText:iter.numberOfTracksString image:genreImage];

        listItem.userInfo = iter;
        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];
            VLCMLGenre *genre = item.userInfo;
            [playbackService playCollection:[genre tracks]];
            completionBlock();
        };
        [itemList addObject:listItem];
    }

    return itemList;
}

@end

#pragma clang diagnostic pop
