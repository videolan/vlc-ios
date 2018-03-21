//
//  GRKArrayDiff+UICollectionView.m
//
//  Created by Michael Kessler on April 28, 2016.
//  Copyright (c) 2016-2018 Levi Brown <mailto:levigroker@gmail.com> This work is
//  licensed under the Creative Commons Attribution 4.0 International License. To
//  view a copy of this license, visit https://creativecommons.org/licenses/by/4.0/
//
//  The above attribution and this license must accompany any version of the source
//  code, binary distributable, or derivatives.
//

#import "GRKArrayDiff+UICollectionView.h"

@implementation GRKArrayDiff (UICollectionView)

#if TARGET_OS_IPHONE

#pragma mark - UICollectionView

- (void)updateCollectionView:(UICollectionView *)collectionView section:(NSInteger)section completion:(void(^)(void))completion {
    [collectionView performBatchUpdates:^{
        //Deletes
        NSArray *deletions = [self indexPathsForDiffType:GRKArrayDiffTypeDeletions withSection:section];
        if (deletions.count > 0) {
            [collectionView deleteItemsAtIndexPaths:deletions];
        }
        
        //Insertions
        NSArray *insertions = [self indexPathsForDiffType:GRKArrayDiffTypeInsertions withSection:section];
        if (insertions.count > 0) {
            [collectionView insertItemsAtIndexPaths:insertions];
        }

        for (GRKArrayDiffInfo *diffInfo in self.moves) {
            NSIndexPath *previousIndexPath = [diffInfo indexPathForIndexType:GRKArrayDiffInfoIndexTypePrevious withSection:section];
            NSIndexPath *currentIndexPath = [diffInfo indexPathForIndexType:GRKArrayDiffInfoIndexTypeCurrent withSection:section];
            
            [collectionView moveItemAtIndexPath:previousIndexPath toIndexPath:currentIndexPath];
        }

        NSArray *modifications = [self indexPathsForDiffType:GRKArrayDiffTypeModifications withSection:section];
        if (modifications.count > 0) {
            [collectionView reloadItemsAtIndexPaths:modifications];
        }
        
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

#endif //TARGET_OS_IPHONE

@end
