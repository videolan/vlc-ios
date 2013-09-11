//
//  VLCPlaylistCollectionViewCell.h
//  VLC for iOS
//
//  Created by Tamas Timar on 8/30/13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import <UIKit/UIKit.h>
#import "VLCLinearProgressIndicator.h"

@interface VLCPlaylistCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet VLCLinearProgressIndicator *progressView;
@property (nonatomic, strong) IBOutlet UIButton *removeMediaButton;
@property (nonatomic, strong) IBOutlet UIImageView *mediaIsUnreadView;
@property (nonatomic, strong) IBOutlet UILabel *seriesNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *artistNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *albumNameLabel;

@property (nonatomic, retain) MLFile *mediaObject;

@property (nonatomic, weak) UICollectionView *collectionView;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (IBAction)removeMedia:(id)sender;

@end
