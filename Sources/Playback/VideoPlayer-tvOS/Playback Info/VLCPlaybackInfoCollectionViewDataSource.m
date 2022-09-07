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

#import "VLCPlaybackInfoCollectionViewDataSource.h"
#import "VLCPlaybackInfoTVCollectionSectionTitleView.h"

@implementation VLCPlaybackInfoCollectionViewDataSource

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackInfoTVCollectionSectionTitleView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[VLCPlaybackInfoTVCollectionSectionTitleView identifier] forIndexPath:indexPath];

    BOOL showTitle = [collectionView numberOfItemsInSection:indexPath.section] != 0;
    header.titleLabel.text = showTitle ? self.title : nil;
    return header;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView dequeueReusableCellWithReuseIdentifier:self.cellIdentifier forIndexPath:indexPath];
}

@end
