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

#import <UIKit/UIKit.h>
#import "VLCServerBrowsingController.h"
#import "VLCNetworkImageView.h"

extern NSString *const VLCRemoteBrowsingTVCellIdentifier;

@interface VLCRemoteBrowsingTVCell : UICollectionViewCell <VLCRemoteBrowsingCell>

@property (nonatomic, weak) IBOutlet VLCNetworkImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *checkBoxImageView;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *favorite;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *medianew;

@property (nonatomic) BOOL selectedPreviously;
@property (nonatomic) BOOL downloadArtwork;

@end
