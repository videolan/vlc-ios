/*****************************************************************************
 * VLCCarPlayFoldersController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCarPlayFoldersController.h"
#import "VLCCarPlayListLimit.h"
#import "UIImage+PaddedImage.h"
#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

NSString *VLCCarPlayFolderMedia = @"VLCCarPlayFolderMedia";
NSString *VLCCarPlayFolderMediaIndex = @"VLCCarPlayFolderMediaIndex";

@implementation VLCCarPlayFoldersController

- (CPListTemplate *)folderList
{
    VLCMLFolder *rootFolder = [[VLCAppCoordinator sharedInstance].mediaLibraryService baseFolder];
    CPListSection *listSection = [[CPListSection alloc] initWithItems:[self listOfItemsForFolder:rootFolder]];
    CPListTemplate *template = [[CPListTemplate alloc] initWithTitle:NSLocalizedString(@"FOLDERS", nil)
                                                            sections:@[listSection]];
    template.tabTitle = NSLocalizedString(@"FOLDERS", nil);
    template.tabImage = [UIImage systemImageNamed:@"folder"];
    return template;
}

- (NSArray *)listOfItemsForFolder:(VLCMLFolder *)folder
{
    if (folder == nil) {
        return @[];
    }

    NSUInteger maximumItemCount = VLCCarPlayMaximumItemCountLimit();
    NSMutableArray *itemList = [NSMutableArray array];

    CGSize iconSize = CGSizeMake(80.0, 80.0);
    if (@available(iOS 14.0, *)) {
        iconSize = [CPListItem maximumImageSize];
    }
    UIImage *folderIcon = [UIImage paddedImageForSymbol:@"folder" ofSize:iconSize];

    NSArray<VLCMLFolder *> *subfolders = [folder subfoldersWithSortingCriteria:VLCMLSortingCriteriaDefault desc:NO];
    for (VLCMLFolder *subfolder in subfolders) {
        if (itemList.count >= maximumItemCount) {
            break;
        }

        NSString *detailText = @"";
        if (subfolder.duration > 0) {
            detailText = [NSString stringWithFormat:NSLocalizedString(@"TRACKS_DURATION", nil),
                          subfolder.nbAudio, [VLCTime timeWithNumber:@(subfolder.duration)].stringValue];
        }
        CPListItem *listItem = [[CPListItem alloc] initWithText:subfolder.mrl.lastPathComponent
                                                     detailText:detailText
                                                          image:folderIcon];
        listItem.userInfo = subfolder;
        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            VLCMLFolder *subfolder = item.userInfo;
            CPListSection *subitemsSection = [[CPListSection alloc] initWithItems:[self listOfItemsForFolder:subfolder]];
            CPListTemplate *subitemsTemplate = [[CPListTemplate alloc] initWithTitle:subfolder.mrl.lastPathComponent
                                                                            sections:@[subitemsSection]];
            [self.interfaceController pushTemplate:subitemsTemplate animated:YES];
            completionBlock();
        };
        [itemList addObject:listItem];
    }

    UIImage *mediaPlaceholder = [UIImage paddedImageForSymbol:@"doc" ofSize:iconSize];

    NSArray<VLCMLMedia *> *media = [folder mediaOfType:VLCMLMediaTypeAudio
                                       sortingCriteria:VLCMLSortingCriteriaDefault
                                                  desc:NO];
    for (NSUInteger i = 0; i < media.count; i++) {
        if (itemList.count >= maximumItemCount) {
            break;
        }

        VLCMLMedia *iter = media[i];
        UIImage *artwork = [VLCThumbnailsCache thumbnailForURL:iter.thumbnail];
        if (!artwork) {
            artwork = mediaPlaceholder;
        }
        NSString *detailText = [VLCTime timeWithNumber:@(iter.duration)].stringValue;
        NSString *artistName = iter.artist.name;
        if (artistName.length > 0) {
            detailText = [artistName stringByAppendingFormat:@" · %@", detailText];
        }
        CPListItem *listItem = [[CPListItem alloc] initWithText:iter.title
                                                     detailText:detailText
                                                          image:artwork];
        listItem.userInfo = @{ VLCCarPlayFolderMedia : media,
                               VLCCarPlayFolderMediaIndex : @(i) };
        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            NSDictionary *userInfo = item.userInfo;
            NSArray *media = userInfo[VLCCarPlayFolderMedia];
            NSNumber *index = userInfo[VLCCarPlayFolderMediaIndex];
            VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];
            [playbackService playMediaAtIndex:index.intValue fromCollection:media];
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
