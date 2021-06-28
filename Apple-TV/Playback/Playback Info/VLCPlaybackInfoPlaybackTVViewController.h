/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *        Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackInfoPanelTVViewController.h"

@interface VLCPlaybackInfoPlaybackTVViewController : VLCPlaybackInfoPanelTVViewController
@property (nonatomic, weak) IBOutlet UISegmentedControl *rateControl;
@property (nonatomic, weak) IBOutlet UILabel *rateLabel;
@property (nonatomic, weak) IBOutlet UISegmentedControl *repeatControl;
@property (nonatomic, weak) IBOutlet UILabel *repeatLabel;
@property (nonatomic, weak) IBOutlet UISegmentedControl *shuffleControl;
@property (nonatomic, weak) IBOutlet UILabel *shuffleLabel;

- (IBAction)rateControlChanged:(UISegmentedControl *)sender;
- (IBAction)repeatControlChanged:(UISegmentedControl *)sender;
- (IBAction)shuffleControlChanged:(UISegmentedControl *)sender;
@end
