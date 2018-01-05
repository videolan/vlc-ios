/*****************************************************************************
 * VLCPlaylistCollectionViewCell.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Tamas Timar <ttimar.vlc # gmail.com>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Carola Nitz <nitz.carola # gmail.com>
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
@property (nonatomic, strong) IBOutlet UIImageView *folderIconView;
@property (nonatomic, strong) IBOutlet UILabel *metaDataLabel;

@property (nonatomic, retain) NSManagedObject *mediaObject;

@property (nonatomic, weak) UICollectionView *collectionView;
@property (readonly) BOOL showsMetaData;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (void)selectionUpdate;
- (void)showMetadata:(BOOL)showMeta;
+ (NSString *)cellIdentifier;

@end
