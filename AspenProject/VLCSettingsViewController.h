//
//  VLCSettingsViewController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 19.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VLCSettingsViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIBarButtonItem *dismissButton;
@property (nonatomic, strong) IBOutlet UISwitch *passcodeLockSwitch;
@property (nonatomic, strong) IBOutlet UILabel *passcodeLockLabel;

@property (nonatomic, strong) IBOutlet UISwitch *audioPlaybackInBackgroundSwitch;
@property (nonatomic, strong) IBOutlet UILabel *audioPlaybackInBackgroundLabel;

- (IBAction)toggleSetting:(id)sender;

- (IBAction)dismiss:(id)sender;

@end

