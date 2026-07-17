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
#import "UIImage+PaddedImage.h"
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

    CGSize placeholderSize = CGSizeMake(80.0, 80.0);
    if (@available(iOS 14.0, *)) {
        placeholderSize = [CPListItem maximumImageSize];
    }
    NSString *placeholderSymbol = @"square.stack";
    if (@available(iOS 16.0, *)) {
        placeholderSymbol = @"music.note.square.stack";
    }
    UIImage *placeholder = [UIImage paddedImageForSymbol:placeholderSymbol ofSize:placeholderSize];

    for (NSUInteger index = 0; index < count; index++) {
        VLCMLAlbum *album = albums[index];
        UIImage *albumCover = [VLCThumbnailsCache thumbnailForURL:album.artworkMRL];
        if (!albumCover) {
            albumCover = placeholder;
        }

        NSString *detailText = [NSString localizedStringWithFormat:NSLocalizedString(@"TRACKS_DURATION", nil),
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

    CGSize placeholderSize = CGSizeMake(80.0, 80.0);
    if (@available(iOS 14.0, *)) {
        placeholderSize = [CPListItem maximumImageSize];
    }
    UIImage *placeholder = [UIImage paddedImageForSymbol:@"music.note" ofSize:placeholderSize];

    for (NSUInteger i = 0; i < count; i++) {
        VLCMLMedia *iter = tracks[i];
        UIImage *artwork = [VLCThumbnailsCache thumbnailForURL:iter.thumbnail];
        if (!artwork) {
            artwork = placeholder;
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
