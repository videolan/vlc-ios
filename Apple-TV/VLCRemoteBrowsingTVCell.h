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
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;

@property (nonatomic) BOOL downloadArtwork;

@end
