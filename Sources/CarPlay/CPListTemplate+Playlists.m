/*****************************************************************************
 * CPListTemplate+Playlists.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "CPListTemplate+Playlists.h"
#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@implementation CPListTemplate (Playlists)

+ (CPListTemplate *)playlists
{
    CPListSection *listSection = [[CPListSection alloc] initWithItems:[self listOfPlaylists]];
    CPListTemplate *template = [[CPListTemplate alloc] initWithTitle:NSLocalizedString(@"PLAYLISTS", nil)
                                                                            sections:@[listSection]];
    template.tabTitle = NSLocalizedString(@"PLAYLISTS", nil);
    template.tabImage = [UIImage imageNamed:@"cp-Playlist"];
    return template;
}

+ (NSArray *)listOfPlaylists
{
    NSArray *playlists = [[VLCAppCoordinator sharedInstance].mediaLibraryService playlistsWithSortingCriteria:VLCMLSortingCriteriaDefault
                                                                                                         desc:NO];

    NSUInteger count = playlists.count;
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    for (NSUInteger x = 0; x < count; x++) {
        CPListItem *listItem;

        VLCMLPlaylist *iter = playlists[x];
        UIImage *artworkImage = iter.thumbnailImage;
        if (!artworkImage) {
            artworkImage = [UIImage imageNamed:@"cp-Playlist"];
        }

        NSString *detailText = [NSString stringWithFormat:NSLocalizedString(@"TRACKS_DURATION", nil),
                                iter.nbMedia, [VLCTime timeWithNumber:@(iter.duration)].stringValue];

        listItem = [[CPListItem alloc] initWithText:iter.name
                                         detailText:detailText
                                              image:artworkImage];

        listItem.userInfo = iter;
        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];
            VLCMLPlaylist *playlist = item.userInfo;
            [playbackService playCollection:[playlist media]];
            completionBlock();
        };
        [itemList addObject:listItem];
    }

    return itemList;
}

@end

#pragma clang diagnostic pop
