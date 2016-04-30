/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "GRKArrayDiff+UICollectionView.h"

@implementation GRKArrayDiff (UICollectionView)
- (void)performBatchUpdatesWithCollectionView:(UICollectionView *)collectionView section:(NSUInteger)section dataSourceUpdate:(void (^)(void))update completion:(void (^ __nullable)(BOOL finished))completion
{
    [collectionView performBatchUpdates:^{
        NSArray<NSIndexPath *> *deletions = [self indexPathsForDiffType:GRKArrayDiffTypeDeletions withSection:section];
        if (deletions.count) {
            deletions = [deletions sortedArrayUsingSelector:@selector(compare:)];
            [collectionView deleteItemsAtIndexPaths:deletions];
        }
        NSArray<NSIndexPath *> *insertions = [self indexPathsForDiffType:GRKArrayDiffTypeInsertions withSection:section];
        if (insertions.count) {
            insertions = [insertions sortedArrayUsingSelector:@selector(compare:)];
            [collectionView insertItemsAtIndexPaths:insertions];
        }
        for (GRKArrayDiffInfo *moveInfo in self.moves) {
            NSIndexPath *previousIndexPath = [moveInfo indexPathForIndexType:GRKArrayDiffInfoIndexTypePrevious withSection:section];
            NSIndexPath *currentIndexPath = [moveInfo indexPathForIndexType:GRKArrayDiffInfoIndexTypeCurrent withSection:section];
            [collectionView moveItemAtIndexPath:previousIndexPath toIndexPath:currentIndexPath];
        }

        NSArray<NSIndexPath *> *modifications = [self indexPathsForDiffType:GRKArrayDiffTypeModifications withSection:section];
        if (modifications.count) {
            [collectionView reloadItemsAtIndexPaths:modifications];
        }

        // perform data source update within batchUpdateBlock
        if (update) {
            update();
        }

    } completion:completion];
}
@end
