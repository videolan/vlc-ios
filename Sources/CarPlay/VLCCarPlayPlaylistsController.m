/*****************************************************************************
 * VLCCarPlayPlaylistsController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCarPlayPlaylistsController.h"
#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@implementation VLCCarPlayPlaylistsController

- (CPListTemplate *)playlists
{
    CPListSection *listSection = [[CPListSection alloc] initWithItems:[self listOfPlaylists]];
    return [self tabTemplateWithTitle:NSLocalizedString(@"PLAYLISTS", nil)
                               symbol:@"music.note.list"
                             sections:@[listSection]];
}

- (NSArray *)listOfPlaylists
{
    NSArray *playlists = [[VLCAppCoordinator sharedInstance].mediaLibraryService playlistsWithSortingCriteria:VLCMLSortingCriteriaDefault
                                                                                                         desc:NO];

    NSUInteger count = MIN(playlists.count, [VLCCarPlayBrowserController maximumItemCount]);
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    UIImage *placeholder = [VLCCarPlayBrowserController placeholderForSymbol:@"music.note.list"];

    for (NSUInteger x = 0; x < count; x++) {
        VLCMLPlaylist *playlist = playlists[x];
        UIImage *artworkImage = playlist.thumbnailImage ?: placeholder;

        NSString *detailText = [NSString localizedStringWithFormat:NSLocalizedString(@"TRACKS_DURATION", nil),
                                playlist.nbMedia, [VLCTime timeWithNumber:@(playlist.duration)].stringValue];

        CPListItem *listItem = [[CPListItem alloc] initWithText:playlist.name
                                                     detailText:detailText
                                                          image:artworkImage];

        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            NSArray<VLCMLMedia *> *media = playlist.media;
            if (media.count > 1) {
                [self pushListWithTitle:playlist.name
                                  items:[self trackItems:media showArtist:YES placeholderSymbol:@"music.note"]];
            } else {
                [[VLCPlaybackService sharedInstance] playCollection:media];
            }

            completionBlock();
        };
        [itemList addObject:listItem];
    }

    return itemList;
}

@end

#pragma clang diagnostic pop
