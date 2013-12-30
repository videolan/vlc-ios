/*****************************************************************************
 * VLCPlaylistCollectionViewCell.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Tamas Timar <ttimar.vlc # gmail.com>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import "VLCLinearProgressIndicator.h"

@interface VLCPlaylistCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet VLCLinearProgressIndicator *progressView;
@property (nonatomic, strong) IBOutlet UIView *mediaIsUnreadView;
@property (nonatomic, strong) IBOutlet UIImageView *isSelectedView;

@property (nonatomic, retain) MLFile *mediaObject;

@property (nonatomic, weak) UICollectionView *collectionView;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (void)selectionUpdate;

@end
