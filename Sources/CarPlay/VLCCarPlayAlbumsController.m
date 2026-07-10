/*****************************************************************************
 * VLCCarPlayAlbumsController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCarPlayAlbumsController.h"
#import "VLCCarPlayListLimit.h"
#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

static NSString *const VLCCarPlayAlbumsTracks = @"VLCCarPlayAlbumsTracks";
static NSString *const VLCCarPlayAlbumsTrackIndex = @"VLCCarPlayAlbumsTrackIndex";

@implementation VLCCarPlayAlbumsController

- (CPListTemplate *)albumList
{
    CPListSection *listSection = [[CPListSection alloc] initWithItems:[self listOfAlbums]];
    CPListTemplate *template = [[CPListTemplate alloc] initWithTitle:NSLocalizedString(@"ALBUMS", nil)
                                                            sections:@[listSection]];
    template.tabTitle = NSLocalizedString(@"ALBUMS", nil);
    template.tabImage = [UIImage systemImageNamed:@"square.stack"];
    return template;
}

- (NSArray *)listOfAlbums
{
    NSArray *albums = [[VLCAppCoordinator sharedInstance].mediaLibraryService albumsWithSortingCriteria:VLCMLSortingCriteriaAlpha
                                                                                                   desc:NO];
    NSUInteger maximumItemCount = VLCCarPlayMaximumItemCountLimit();
    NSUInteger count = MIN(albums.count, maximumItemCount);
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    for (NSUInteger index = 0; index < count; index++) {
        VLCMLAlbum *album = albums[index];
        UIImage *albumCover = [VLCThumbnailsCache thumbnailForURL:album.artworkMRL];
        if (!albumCover) {
            albumCover = [UIImage imageNamed:@"album-placeholder-dark"];
        }

        NSString *detailText = [NSString stringWithFormat:NSLocalizedString(@"TRACKS_DURATION", nil),
                          album.numberOfTracks, [VLCTime timeWithNumber:@(album.duration)].stringValue];

        CPListItem *listItem = [[CPListItem alloc] initWithText:album.title
                                                     detailText:detailText
                                                          image:albumCover];
        listItem.userInfo = album;
        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            VLCMLAlbum *album = item.userInfo;
            if (album.numberOfTracks > 1) {
                CPListSection *subitemsSection = [[CPListSection alloc] initWithItems:[self listOfTracksForAlbum:album]];
                CPListTemplate *subitemsTemplate = [[CPListTemplate alloc] initWithTitle:album.title
                                                                                sections:@[subitemsSection]];
                [self.interfaceController pushTemplate:subitemsTemplate animated:YES];
            } else {
                VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];
                [playbackService playCollection:[album tracks]];
            }
            completionBlock();
        };

        [itemList addObject:listItem];
    }

    return itemList;
}

- (NSArray *)listOfTracksForAlbum:(VLCMLAlbum *)album
{
    NSArray *tracks = [album tracksWithSortingCriteria:VLCMLSortingCriteriaDefault desc:NO];
    BOOL isCollection = album.artists.count > 1;
    NSUInteger maximumItemCount = VLCCarPlayMaximumItemCountLimit();
    NSUInteger count = MIN(tracks.count, maximumItemCount);
    NSMutableArray *itemList = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        VLCMLMedia *iter = tracks[i];
        UIImage *artwork = [VLCThumbnailsCache thumbnailForURL:iter.thumbnail];
        if (!artwork) {
            artwork = [UIImage imageNamed:@"album-placeholder-dark"];
        }
        NSString *detailText = [VLCTime timeWithNumber:@(iter.duration)].stringValue;
        if (isCollection) {
            NSString *artistName = iter.artist.name;
            if (artistName.length > 0) {
                detailText = [artistName stringByAppendingFormat:@" · %@", detailText];
            }
        }
        CPListItem *listItem = [[CPListItem alloc] initWithText:iter.title
                                                     detailText:detailText
                                                          image:artwork];
        listItem.userInfo = @{ VLCCarPlayAlbumsTracks : tracks,
                               VLCCarPlayAlbumsTrackIndex : @(i) };
        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            NSDictionary *userInfo = item.userInfo;
            NSArray *tracks = userInfo[VLCCarPlayAlbumsTracks];
            NSNumber *index = userInfo[VLCCarPlayAlbumsTrackIndex];
            VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];
            [playbackService playMediaAtIndex:index.intValue fromCollection:tracks];
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

@end

#pragma clang diagnostic pop
