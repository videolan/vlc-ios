/*****************************************************************************
 * VLCOpenNetworkStreamViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@interface VLCOpenNetworkStreamViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *urlField;
@property (weak, nonatomic) IBOutlet UIView *urlBorder;
@property (strong, nonatomic) IBOutlet UIButton *openButton;
@property (strong, nonatomic) IBOutlet UIButton *privateToggleButton;
@property (strong, nonatomic) IBOutlet UIButton *scanSubToggleButton;
@property (strong, nonatomic) IBOutlet UILabel *privateModeLabel;
@property (strong, nonatomic) IBOutlet UILabel *scanSubModeLabel;
@property (strong, nonatomic) IBOutlet UITableView *historyTableView;
@property (strong, nonatomic) IBOutlet UILabel *whatToOpenHelpLabel;

@property (nonatomic, readonly, copy) NSString *detailText;
@property (nonatomic, readonly) UIImage *cellImage;

- (IBAction)openButtonAction:(id)sender;
- (IBAction)toggleButtonAction:(UIButton *)sender;

@end
