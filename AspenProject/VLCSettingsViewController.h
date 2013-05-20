//
//  VLCSettingsViewController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 19.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VLCSettingsViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) IBOutlet UIBarButtonItem *dismissButton;
@property (nonatomic, strong) IBOutlet UISwitch *passcodeLockSwitch;
@property (nonatomic, strong) IBOutlet UILabel *passcodeLockLabel;

@property (nonatomic, strong) IBOutlet UISwitch *audioPlaybackInBackgroundSwitch;
@property (nonatomic, strong) IBOutlet UILabel *audioPlaybackInBackgroundLabel;

@property (nonatomic, strong) IBOutlet UISwitch *audioStretchingSwitch;
@property (nonatomic, strong) IBOutlet UILabel *audioStretchingLabel;

@property (nonatomic, strong) IBOutlet UISwitch *debugOutputSwitch;
@property (nonatomic, strong) IBOutlet UILabel *debugOutputLabel;

@property (nonatomic, strong) IBOutlet UIPickerView *textEncodingPicker;
@property (nonatomic, strong) IBOutlet UILabel *textEncodingLabel;

- (IBAction)toggleSetting:(id)sender;

- (IBAction)dismiss:(id)sender;

@end

