/*****************************************************************************
 * VLCCarPlayArtistsController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCarPlayArtistsController.h"
#import "VLC-Swift.h"

@implementation VLCCarPlayArtistsController

- (CPListTemplate *)artistList
{
    CPListSection *listSection = [[CPListSection alloc] initWithItems:[self listOfArtists]];
    return [self tabTemplateWithTitle:NSLocalizedString(@"ARTISTS", nil)
                               symbol:@"person.3"
                             sections:@[listSection]];
}

- (NSArray *)listOfArtists
{
    NSArray *artists = [[VLCAppCoordinator sharedInstance].mediaLibraryService artistsWithSortingCriteria:VLCMLSortingCriteriaDefault
                                                                                                     desc:NO
                                                                                                  listAll:NO];

    NSUInteger count = MIN(artists.count, [VLCCarPlayBrowserController maximumItemCount]);
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    UIImage *placeholder = [VLCCarPlayBrowserController placeholderForSymbol:@"person.3"];

    for (NSUInteger x = 0; x < count; x++) {
        VLCMLArtist *artist = artists[x];
        NSArray<VLCMLAlbum *> *albums = artist.albums;

        UIImage *artistImage;
        NSUInteger albumCount = MIN(albums.count, (NSUInteger)8);
        for (NSUInteger index = 0; index < albumCount; index++) {
            artistImage = [VLCThumbnailsCache thumbnailForURL:albums[index].artworkMRL];
            if (artistImage) {
                break;
            }
        }
        if (!artistImage) {
            artistImage = placeholder;
        }

        CPListItem *listItem = [[CPListItem alloc] initWithText:artist.artistName
                                                     detailText:[artist.numberOfAlbumsString stringByAppendingFormat:@", %@", artist.numberOfTracksString]
                                                          image:artistImage];

        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            VLCMLAlbum *album = albums.firstObject;
            if (albums.count > 1) {
                [self pushListWithTitle:artist.name items:[self albumItems:albums]];
            } else if (album != nil) {
                [self pushListWithTitle:album.title items:[self trackItemsForAlbum:album]];
            } else {
                [[VLCPlaybackService sharedInstance] playCollection:[artist tracks]];
            }
            completionBlock();
        };

        [itemList addObject:listItem];
    }

    return itemList;
}

@end
