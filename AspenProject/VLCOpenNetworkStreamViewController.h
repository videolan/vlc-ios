//
//  VLCOpenNetworkStreamViewController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 16.06.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

@interface VLCOpenNetworkStreamViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField *urlField;
@property (strong, nonatomic) IBOutlet UIButton *openButton;
@property (strong, nonatomic) IBOutlet UISwitch *privateToggleSwitch;
@property (strong, nonatomic) IBOutlet UILabel *privateModeLabel;
@property (strong, nonatomic) IBOutlet UITableView *historyTableView;

- (IBAction)openButtonAction:(id)sender;

@end
