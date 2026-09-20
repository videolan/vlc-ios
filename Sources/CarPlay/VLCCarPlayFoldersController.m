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
#import "VLC-Swift.h"

@implementation VLCCarPlayFoldersController

- (CPListTemplate *)folderList
{
    VLCMLFolder *rootFolder = [[VLCAppCoordinator sharedInstance].mediaLibraryService baseFolder];
    CPListSection *listSection = [[CPListSection alloc] initWithItems:[self listOfItemsForFolder:rootFolder]];
    return [self tabTemplateWithTitle:NSLocalizedString(@"FOLDERS", nil)
                               symbol:@"folder"
                             sections:@[listSection]];
}

- (NSArray *)listOfItemsForFolder:(VLCMLFolder *)folder
{
    if (folder == nil) {
        return @[];
    }

    NSUInteger maximumItemCount = [VLCCarPlayBrowserController maximumItemCount];
    NSMutableArray *itemList = [NSMutableArray array];

    UIImage *folderIcon = [VLCCarPlayBrowserController placeholderForSymbol:@"folder"];

    NSArray<VLCMLFolder *> *subfolders = [folder subfoldersWithSortingCriteria:VLCMLSortingCriteriaDefault desc:NO];
    for (VLCMLFolder *subfolder in subfolders) {
        if (itemList.count >= maximumItemCount) {
            return itemList;
        }

        NSString *detailText = @"";
        if (subfolder.duration > 0) {
            detailText = [NSString localizedStringWithFormat:NSLocalizedString(@"TRACKS_DURATION", nil),
                          subfolder.nbAudio, [VLCTime timeWithNumber:@(subfolder.duration)].stringValue];
        }
        CPListItem *listItem = [[CPListItem alloc] initWithText:subfolder.name
                                                     detailText:detailText
                                                          image:folderIcon];
        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            [self pushListWithTitle:subfolder.name items:[self listOfItemsForFolder:subfolder]];
            completionBlock();
        };
        [itemList addObject:listItem];
    }

    NSUInteger remainingItemCount = maximumItemCount - itemList.count;
    if (remainingItemCount == 0) {
        return itemList;
    }

    NSArray<VLCMLMedia *> *media = [folder mediaOfType:VLCMLMediaTypeAudio
                                       sortingCriteria:VLCMLSortingCriteriaDefault
                                                  desc:NO];
    NSArray<CPListItem *> *mediaItems = [self trackItems:media showArtist:YES placeholderSymbol:@"doc"];
    if (mediaItems.count > remainingItemCount) {
        mediaItems = [mediaItems subarrayWithRange:NSMakeRange(0, remainingItemCount)];
    }
    [itemList addObjectsFromArray:mediaItems];

    return itemList;
}

@end
