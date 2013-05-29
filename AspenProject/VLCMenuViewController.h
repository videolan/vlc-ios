//
//  VLCMenuViewController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 19.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VLCSettingsController;
@class VLCCircularProgressIndicator;
@class IASKAppSettingsViewController;

@interface VLCMenuViewController : UIViewController

@property (strong, nonatomic) IASKAppSettingsViewController *settingsViewController;
@property (strong, nonatomic) VLCSettingsController *settingsController;

@property (strong, nonatomic) IBOutlet UIToolbar *dismissToolBar;
@property (strong, nonatomic) IBOutlet UIButton *aboutButton;
@property (strong, nonatomic) IBOutlet UIButton *openNetworkStreamButton;
@property (strong, nonatomic) IBOutlet VLCCircularProgressIndicator *httpDownloadProgressIndicator;
@property (strong, nonatomic) IBOutlet UIButton *downloadFromHTTPServerButton;
@property (strong, nonatomic) IBOutlet UIButton *settingsButton;
@property (strong, nonatomic) IBOutlet UISwitch *httpUploadServerSwitch;
@property (strong, nonatomic) IBOutlet UILabel *httpUploadLabel;
@property (strong, nonatomic) IBOutlet UILabel *httpUploadServerLocationLabel;
@property (strong, nonatomic) IBOutlet UIButton *dropboxButton;

@property (strong, nonatomic) IBOutlet UIView *openURLView;
@property (strong, nonatomic) IBOutlet UITextField *openURLField;
@property (strong, nonatomic) IBOutlet UIButton *openURLButton;

- (IBAction)dismiss:(id)sender;
- (IBAction)openAboutPanel:(id)sender;
- (IBAction)openNetworkStream:(id)sender;
- (IBAction)downloadFromHTTPServer:(id)sender;
- (IBAction)showDropbox:(id)sender;
- (IBAction)showSettings:(id)sender;
- (IBAction)toggleHTTPServer:(id)sender;

@end
