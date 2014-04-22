/*****************************************************************************
 * VLCOpenNetworkStreamViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@interface VLCOpenNetworkStreamViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *urlField;
@property (strong, nonatomic) IBOutlet UIButton *openButton;
@property (strong, nonatomic) IBOutlet UISwitch *privateToggleSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *ScanSubToggleSwitch;
@property (strong, nonatomic) IBOutlet UILabel *privateModeLabel;
@property (strong, nonatomic) IBOutlet UILabel *ScanSubModeLabel;
@property (strong, nonatomic) IBOutlet UITableView *historyTableView;
@property (strong, nonatomic) IBOutlet UILabel *whatToOpenHelpLabel;

- (IBAction)openButtonAction:(id)sender;

@end
