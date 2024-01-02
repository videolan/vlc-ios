/*****************************************************************************
 * CPListTemplate+Artists.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022-2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCarPlayArtistsController.h"
#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@implementation VLCCarPlayArtistsController

- (CPListTemplate *)artistList
{

    CPListSection *listSection = [[CPListSection alloc] initWithItems:[self listOfArtists]];
    CPListTemplate *template = [[CPListTemplate alloc] initWithTitle:NSLocalizedString(@"ARTISTS", nil)
                                                            sections:@[listSection]];
    template.tabTitle = NSLocalizedString(@"ARTISTS", nil);
    template.tabImage = [UIImage imageNamed:@"cp-Artist"];
    return template;
}

- (NSArray *)listForAlbumsForArtist:(VLCMLArtist *)artist
{
    NSArray *albums = artist.albums;
    NSMutableArray *itemList = [NSMutableArray arrayWithCapacity:albums.count];
    for (VLCMLAlbum *album in albums) {
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
            VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];
            [playbackService playCollection:[album tracks]];
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

- (NSArray *)listOfArtists
{
    BOOL hideFeatArtists = [[NSUserDefaults standardUserDefaults] boolForKey:kVLCAudioLibraryHideFeatArtists];
    NSArray *artists = [[VLCAppCoordinator sharedInstance].mediaLibraryService artistsWithSortingCriteria:VLCMLSortingCriteriaDefault
                                                                                                     desc:NO
                                                                                                  listAll:!hideFeatArtists];

    NSUInteger count = artists.count;
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    for (NSUInteger x = 0; x < count; x++) {
        CPListItem *listItem;

        VLCMLArtist *iter = artists[x];
        NSArray *albums = iter.albums;
        UIImage *artistImage;

        for (VLCMLAlbum *album in albums) {
            artistImage = [VLCThumbnailsCache thumbnailForURL:album.artworkMRL];
            if (artistImage)
                break;
        }
        if (!artistImage) {
            artistImage = [UIImage imageNamed:@"cp-Artist"];
        }

        listItem = [[CPListItem alloc] initWithText:iter.artistName
                                         detailText:[iter.numberOfAlbumsString stringByAppendingFormat:@", %@", iter.numberOfTracksString]
                                              image:artistImage];

        listItem.userInfo = iter;
        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            VLCMLArtist *artist = item.userInfo;
            if (artist.albumsCount > 1) {
                CPListSection *subitemsSection = [[CPListSection alloc] initWithItems:[self listForAlbumsForArtist:artist]];
                CPListTemplate *subitemsTemplate = [[CPListTemplate alloc] initWithTitle:artist.name
                                                                                sections:@[subitemsSection]];
                [self.interfaceController pushTemplate:subitemsTemplate animated:YES];
            } else {
                VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];
                [playbackService playCollection:[artist tracks]];
            }
            completionBlock();
        };

        [itemList addObject:listItem];
    }

    return itemList;
}

@end

#pragma clang diagnostic pop
