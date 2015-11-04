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

@interface VLCOpenNetworkStreamTVViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (readwrite, nonatomic, weak) IBOutlet UITextField *playURLField;
@property (readwrite, nonatomic, weak) IBOutlet UITableView *previouslyPlayedStreamsTableView;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *toggleHTTPServerButton;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *httpServerLabel;

- (IBAction)URLEnteredInField:(id)sender;
- (IBAction)toggleHTTPServer:(id)sender;

@end
