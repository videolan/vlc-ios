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
#import "VLCDeletionCapableViewController.h"

@interface VLCOpenNetworkStreamTVViewController : VLCDeletionCapableViewController <UITableViewDataSource, UITableViewDelegate>

@property (readwrite, nonatomic, weak) IBOutlet UITextField *playURLField;
@property (readwrite, nonatomic, weak) IBOutlet UITableView *previouslyPlayedStreamsTableView;

@property (readwrite, nonatomic, weak) IBOutlet UILabel *nothingFoundLabel;
@property (readwrite, nonatomic, weak) IBOutlet UIView *nothingFoundView;
@property (readwrite, nonatomic, weak) IBOutlet UIImageView *nothingFoundConeImageView;

@property (readwrite, nonatomic, weak) IBOutlet UIButton *emptyListButton;

- (IBAction)URLEnteredInField:(id)sender;
- (IBAction)emptyListAction:(id)sender;

@end
