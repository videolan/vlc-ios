/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackInfoPanelTVViewController.h"

@interface VLCPlaybackInfoMediaInfoTVViewController : VLCPlaybackInfoPanelTVViewController

@property (readwrite, nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *metaDataLabel;

@end
