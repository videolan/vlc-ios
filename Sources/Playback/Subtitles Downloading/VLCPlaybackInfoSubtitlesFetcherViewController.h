/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2020 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCPlaybackInfoSubtitlesFetcherViewController : UIViewController

@property (readwrite, weak, nonatomic) IBOutlet UITableView *tableView;

#if TARGET_OS_TV
@property (readwrite, weak, nonatomic) IBOutlet UIVisualEffectView *visualEffectView;
@property (readwrite, weak, nonatomic) IBOutlet UILabel *titleLabel;
#endif

@end
