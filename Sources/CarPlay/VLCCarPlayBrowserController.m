/*****************************************************************************
 * VLCCarPlayBrowserController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022-2026 VideoLAN. All rights reserved.
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCarPlayBrowserController.h"
#import "CPInterfaceController+VLCTemplateStack.h"
#import "UIImage+PaddedImage.h"
#import "VLC-Swift.h"

@implementation VLCCarPlayBrowserController

+ (NSUInteger)maximumItemCount
{
    return CPListTemplate.maximumItemCount;
}

+ (CGSize)listItemIconSize
{
    return [CPListItem maximumImageSize];
}

+ (UIImage *)placeholderForSymbol:(NSString *)symbol
{
    return [UIImage paddedImageForSymbol:symbol ofSize:[self listItemIconSize]];
}

- (CPListTemplate *)tabTemplateWithTitle:(NSString *)title
                                  symbol:(NSString *)symbol
                                sections:(NSArray<CPListSection *> *)sections
{
    CPListTemplate *template = [[CPListTemplate alloc] initWithTitle:title sections:sections];
    template.tabTitle = title;
    template.tabImage = [UIImage systemImageNamed:symbol];
    return template;
}

- (void)pushListWithTitle:(NSString *)title items:(NSArray<CPListItem *> *)items
{
    CPListSection *section = [[CPListSection alloc] initWithItems:items];
    CPListTemplate *template = [[CPListTemplate alloc] initWithTitle:title sections:@[section]];
    [self.interfaceController pushTemplateWithinDepthLimit:template animated:YES];
}

- (NSArray<CPListItem *> *)albumItems:(NSArray<VLCMLAlbum *> *)albums
{
    NSUInteger count = MIN(albums.count, [VLCCarPlayBrowserController maximumItemCount]);
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    NSString *placeholderSymbol = @"square.stack";
    if (@available(iOS 16.0, *)) {
        placeholderSymbol = @"music.note.square.stack";
    }
    UIImage *placeholder = [VLCCarPlayBrowserController placeholderForSymbol:placeholderSymbol];

    for (NSUInteger index = 0; index < count; index++) {
        VLCMLAlbum *album = albums[index];
        UIImage *albumCover = [VLCThumbnailsCache thumbnailForURL:album.artworkMRL] ?: placeholder;

        NSString *detailText = [NSString localizedStringWithFormat:NSLocalizedString(@"TRACKS_DURATION", nil),
                                album.numberOfTracks, [VLCTime timeWithNumber:@(album.duration)].stringValue];

        CPListItem *listItem = [[CPListItem alloc] initWithText:album.title
                                                     detailText:detailText
                                                          image:albumCover];
        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            if (album.numberOfTracks > 1) {
                [self pushListWithTitle:album.title items:[self trackItemsForAlbum:album]];
            } else {
                [[VLCPlaybackService sharedInstance] playCollection:[album tracks]];
            }
            completionBlock();
        };

        [itemList addObject:listItem];
    }

    return itemList;
}

- (NSArray<CPListItem *> *)trackItemsForAlbum:(VLCMLAlbum *)album
{
    NSArray<VLCMLMedia *> *tracks = [album tracksWithSortingCriteria:VLCMLSortingCriteriaDefault desc:NO];
    return [self trackItems:tracks
                 showArtist:album.artists.count > 1
          placeholderSymbol:@"music.note"];
}

- (NSArray<CPListItem *> *)trackItems:(NSArray<VLCMLMedia *> *)tracks
                           showArtist:(BOOL)showArtist
                    placeholderSymbol:(NSString *)symbol
{
    NSUInteger count = MIN(tracks.count, [VLCCarPlayBrowserController maximumItemCount]);
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    UIImage *placeholder = [VLCCarPlayBrowserController placeholderForSymbol:symbol];

    for (NSUInteger index = 0; index < count; index++) {
        VLCMLMedia *track = tracks[index];
        UIImage *artwork = [VLCThumbnailsCache thumbnailForURL:track.thumbnail] ?: placeholder;

        NSString *detailText = [VLCTime timeWithNumber:@(track.duration)].stringValue;
        if (showArtist) {
            NSString *artistName = track.artist.name;
            if (artistName.length > 0) {
                detailText = [artistName stringByAppendingFormat:@" · %@", detailText];
            }
        }

        CPListItem *listItem = [[CPListItem alloc] initWithText:track.title
                                                     detailText:detailText
                                                          image:artwork];
        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            [[VLCPlaybackService sharedInstance] playMediaAtIndex:(int)index fromCollection:tracks];
            completionBlock();
            [self.interfaceController returnToRootTemplateAnimated:YES];
        };

        [itemList addObject:listItem];
    }

    return itemList;
}

@end
