//
//  VLCDropboxTableViewController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 24.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCDropboxController.h"

@interface VLCDropboxTableViewController : UITableViewController <VLCDropboxController>

@property (nonatomic, strong) IBOutlet UIView *loginToDropboxView;
@property (nonatomic, strong) IBOutlet UIButton *loginToDropboxButton;

- (IBAction)loginToDropboxAction:(id)sender;

- (void)updateViewAfterSessionChange;

@end
