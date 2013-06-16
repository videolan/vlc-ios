//
//  VLCMenuViewController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 19.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import <UIKit/UIKit.h>

@class VLCSettingsController;
@class IASKAppSettingsViewController;

@interface VLCMenuViewController : UIViewController

@property (strong, nonatomic) IASKAppSettingsViewController *settingsViewController;
@property (strong, nonatomic) VLCSettingsController *settingsController;

@property (strong, nonatomic) IBOutlet UIButton *aboutButton;
@property (strong, nonatomic) IBOutlet UIButton *openNetworkStreamButton;
@property (strong, nonatomic) IBOutlet UIButton *downloadFromHTTPServerButton;
@property (strong, nonatomic) IBOutlet UIButton *settingsButton;
@property (strong, nonatomic) IBOutlet UISwitch *httpUploadServerSwitch;
@property (strong, nonatomic) IBOutlet UILabel *httpUploadLabel;
@property (strong, nonatomic) IBOutlet UILabel *httpUploadServerLocationLabel;
@property (strong, nonatomic) IBOutlet UIButton *dropboxButton;

- (IBAction)dismiss:(id)sender;
- (IBAction)openAboutPanel:(id)sender;
- (IBAction)openNetworkStream:(id)sender;
- (IBAction)downloadFromHTTPServer:(id)sender;
- (IBAction)showDropbox:(id)sender;
- (IBAction)showSettings:(id)sender;
- (IBAction)toggleHTTPServer:(id)sender;

@end
