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

#import <GRKArrayDiff/GRKArrayDiff.h>
NS_ASSUME_NONNULL_BEGIN
@interface GRKArrayDiff (UICollectionView)
- (void)performBatchUpdatesWithCollectionView:(UICollectionView *)collectionView section:(NSUInteger)section dataSourceUpdate:(void(^ __nullable)(void))update completion:(void (^ __nullable)(BOOL finished))completion;
@end
NS_ASSUME_NONNULL_END
