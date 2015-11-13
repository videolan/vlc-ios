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

@interface VLCRemotePlaybackViewController : UIViewController

@property (readwrite, nonatomic, weak) IBOutlet UIButton *toggleHTTPServerButton;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *httpServerLabel;
@property (readwrite, nonatomic, weak) IBOutlet UITableView *cachedMediaTableView;

- (IBAction)toggleHTTPServer:(id)sender;

@end
