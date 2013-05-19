//
//  VLCAddMediaViewController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 19.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VLCSettingsViewController;

@interface VLCAddMediaViewController : UIViewController

@property (strong, nonatomic) VLCSettingsViewController *settingsViewController;

@property (strong, nonatomic) IBOutlet UIButton *dismissButton;
@property (strong, nonatomic) IBOutlet UIButton *aboutButton;
@property (strong, nonatomic) IBOutlet UIButton *openNetworkStreamButton;
@property (strong, nonatomic) IBOutlet UIButton *downloadFromHTTPServerButton;
@property (strong, nonatomic) IBOutlet UIButton *settingsButton;
@property (strong, nonatomic) IBOutlet UIButton *showInformationOnHTTPUploadButton;
@property (strong, nonatomic) IBOutlet UISwitch *httpUploadServerSwitch;

@property (strong, nonatomic) IBOutlet UIView *openURLView;
@property (strong, nonatomic) IBOutlet UITextField *openURLField;
@property (strong, nonatomic) IBOutlet UIButton *openURLButton;

- (IBAction)openAboutPanel:(id)sender;
- (IBAction)openNetworkStream:(id)sender;
- (IBAction)downloadFromHTTPServer:(id)sender;
- (IBAction)showSettings:(id)sender;
- (IBAction)showInformationOnHTTPServer:(id)sender;
- (IBAction)toggleHTTPServer:(id)sender;

@end
