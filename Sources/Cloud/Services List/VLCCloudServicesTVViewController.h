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

@interface VLCCloudServicesTVViewController : UIViewController

@property (readwrite, nonatomic, weak) IBOutlet UIButton *boxButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *gDriveButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *dropboxButton;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *helpLabel;

- (IBAction)dropbox:(id)sender;
- (IBAction)box:(id)sender;
- (IBAction)gdrive:(id)sender;

@end
