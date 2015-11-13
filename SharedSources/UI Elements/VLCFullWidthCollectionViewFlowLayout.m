/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFullWidthCollectionViewFlowLayout.h"

@implementation VLCFullWidthCollectionViewFlowLayout
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}
- (void)prepareLayout
{
    CGSize itemSize = self.itemSize;
    itemSize.width = CGRectGetWidth(self.collectionView.bounds)-self.sectionInset.left-self.sectionInset.right;
    self.itemSize = itemSize;
    [super prepareLayout];
}

@end
