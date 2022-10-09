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
    VLCAppDelegate *appDelegate = (VLCAppDelegate *)[UIApplication sharedApplication].delegate;
    AppCoordinator *appCoordinator = appDelegate.appCoordinator;
    VLCServices *services = appCoordinator.services;

    MediaLibraryService *mlService = services.medialibraryService;
    NSArray *genres = [mlService genresWithSortingCriteria:VLCMLSortingCriteriaDefault desc:NO];

    NSUInteger count = genres.count;
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    for (NSUInteger x = 0; x < count; x++) {
        CPListImageRowItem *listItem;

        VLCMLGenre *iter = genres[x];
        NSArray *artists = iter.artists;
        NSMutableArray *artistImages = [NSMutableArray array];

        for (VLCMLArtist *artist in artists) {
            UIImage *artworkImage;
            NSData *data = [[NSData alloc] initWithContentsOfURL:artist.artworkMRL];
            if (data) {
                artworkImage = [[UIImage alloc] initWithData:data];
            }
            if (!artworkImage) {
                artworkImage = [UIImage imageNamed:@"cp-Artist"];
            }
            [artistImages addObject:artworkImage];
        }

        listItem = [[CPListImageRowItem alloc] initWithText:iter.name images:artistImages];

        listItem.userInfo = iter;
        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];
            VLCMLGenre *genre = item.userInfo;
            [playbackService playMediaAtIndex:0 fromCollection:[genre tracks]];
            completionBlock();
        };
        listItem.listImageRowHandler = ^(CPListImageRowItem * item, NSInteger index, dispatch_block_t completionBlock) {
            VLCMLGenre *genres = item.userInfo;
            NSArray *artists = genres.artists;
            NSUInteger artistCount = genres.artists.count;
            if (index < artistCount) {
                VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];
                [playbackService playMediaAtIndex:0 fromCollection:[artists[index] tracks]];
            }
            completionBlock();
        };
        [itemList addObject:listItem];
    }

    return itemList;
}

@end

#pragma clang diagnostic pop
