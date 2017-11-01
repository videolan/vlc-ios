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

#import <UIKit/UIKit.h>
#import "VLCPlaybackInfoPanelTVViewController.h"

@interface VLCPlaybackInfoSubtitlesFetcherViewController : VLCPlaybackInfoPanelTVViewController

@property (readwrite, weak, nonatomic) IBOutlet UIVisualEffectView *visualEffectView;
@property (readwrite, weak, nonatomic) IBOutlet UITableView *tableView;
@property (readwrite, weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
