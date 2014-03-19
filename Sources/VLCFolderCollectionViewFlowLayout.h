/*****************************************************************************
 * VLCFolderCollectionViewFlowLayout.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@interface VLCFolderCollectionViewFlowLayout : UICollectionViewFlowLayout <UIGestureRecognizerDelegate>

@property (assign, nonatomic) CGFloat scrollingSpeed;
@property (assign, nonatomic) UIEdgeInsets scrollingTriggerEdgeInsets;
@property (nonatomic, readonly) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, readonly) UIPanGestureRecognizer *panGestureRecognizer;

@end

@protocol VLCFolderCollectionViewDelegateFlowLayout <UICollectionViewDelegateFlowLayout>

- (void)collectionView:(UICollectionView *)collectionView requestToMoveItemAtIndexPath:(NSIndexPath *)currentPath intoFolderAtIndexPath:(NSIndexPath *)newIndexPath;
@end