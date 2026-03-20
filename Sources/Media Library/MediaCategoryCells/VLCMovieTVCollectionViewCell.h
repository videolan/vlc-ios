/*****************************************************************************
 * VLCMovieTVCollectionViewCell.h
 * VLC for tvOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Authors: Felix Paul Kuehne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@class VLCMLMedia;

extern NSString * const VLCMovieTVCollectionViewCellIdentifier;

@interface VLCMovieTVCollectionViewCell : UICollectionViewCell

@property (nonatomic, readonly) UIImageView *thumbnailView;
@property (nonatomic, readonly) UIProgressView *progressView;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *descriptionLabel;
@property (nonatomic, readonly) UILabel *mediaIsNewIndicator;
@property (nonatomic, readonly) UIImageView *checkboxImageView;

@property (nonatomic) BOOL selectedPreviously;

+ (CGSize)cellSize;

- (void)configureWithMedia:(VLCMLMedia *)media;
- (void)toggleCheckbox;

@end
