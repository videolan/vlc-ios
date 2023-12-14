/*****************************************************************************
 * VLCCarPlayPlaylistsController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022-2023 VideoLAN. All rights reserved.
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

NSString *VLCCarPlayPlaylist = @"VLCCarPlayPlaylist";
NSString *VLCCarPlayPlaylistIndex = @"VLCCarPlayPlaylistIndex";

@implementation VLCCarPlayPlaylistsController

- (CPListTemplate *)playlists
{
    CPListSection *listSection = [[CPListSection alloc] initWithItems:[self listOfPlaylists]];
    CPListTemplate *template = [[CPListTemplate alloc] initWithTitle:NSLocalizedString(@"PLAYLISTS", nil)
                                                                            sections:@[listSection]];
    template.tabTitle = NSLocalizedString(@"PLAYLISTS", nil);
    template.tabImage = [UIImage imageNamed:@"cp-Playlist"];
    return template;
}

- (NSArray *)listOfItemsForPlaylist:(VLCMLPlaylist *)playlist
{
    NSArray *media = playlist.media;
    NSUInteger count = media.count;
    NSMutableArray *itemList = [NSMutableArray arrayWithCapacity:media.count];
    for (NSUInteger i = 0; i < count; i++) {
        VLCMLMedia *iter = media[i];
        UIImage *artwork = [iter thumbnailImage];
        NSString *detailText = [VLCTime timeWithNumber:@(iter.duration)].stringValue;

        CPListItem *listItem = [[CPListItem alloc] initWithText:iter.title
                                                     detailText:detailText
                                                          image:artwork];
        listItem.userInfo = @{ VLCCarPlayPlaylist : playlist,
                               VLCCarPlayPlaylistIndex: @(i) };
        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            NSDictionary *userInfo = item.userInfo;
            VLCMLPlaylist *playlist = userInfo[VLCCarPlayPlaylist];
            NSNumber *index = userInfo[VLCCarPlayPlaylistIndex];
            VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];
            [playbackService playMediaAtIndex:index.intValue fromCollection:playlist.media];
            completionBlock();
            if (@available(iOS 14.0, *)) {
                [self.interfaceController popToRootTemplateAnimated:YES completion:nil];
            } else {
                [self.interfaceController popToRootTemplateAnimated:YES];
            }
        };

        [itemList addObject:listItem];
    }
    return itemList;
}

- (NSArray *)listOfPlaylists
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
            VLCMLPlaylist *playlist = item.userInfo;

            if (playlist.nbMedia > 1) {
                CPListSection *subitemsSection = [[CPListSection alloc] initWithItems:[self listOfItemsForPlaylist:playlist]];
                CPListTemplate *subitemsTemplate = [[CPListTemplate alloc] initWithTitle:playlist.name
                                                                                sections:@[subitemsSection]];
                [self.interfaceController pushTemplate:subitemsTemplate animated:YES];
            } else {
                VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];
                [playbackService playCollection:[playlist media]];
            }

            completionBlock();
        };
        [itemList addObject:listItem];
    }

    return itemList;
}

@end

#pragma clang diagnostic pop
