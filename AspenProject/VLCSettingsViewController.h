//
//  VLCSettingsViewController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 19.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "IASKAppSettingsViewController.h"
#import "PAPasscodeViewController.h"

@interface VLCSettingsViewController : UIViewController <IASKSettingsDelegate, PAPasscodeViewControllerDelegate>

@property (nonatomic, strong) IBOutlet UIToolbar *topToolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *dismissButton;

@property (nonatomic, retain) IBOutlet IASKAppSettingsViewController *appSettingsViewController;

- (IBAction)dismiss:(id)sender;

@end

