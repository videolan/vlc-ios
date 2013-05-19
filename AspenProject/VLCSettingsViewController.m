//
//  VLCSettingsViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 19.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCSettingsViewController.h"
#import "VLCPlaylistViewController.h"
#import "VLCPasscodeLockViewController.h"
#import "VLCAppDelegate.h"

@implementation VLCSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.dismissButton.title = NSLocalizedString(@"BUTTON_DONE", @"");
    self.passcodeLockLabel.text = NSLocalizedString(@"PREF_PASSCODE", @"");
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.passcodeLockSwitch.on = [[defaults objectForKey:@"PasscodeProtection"] intValue];

    [super viewWillAppear:animated];
}

- (IBAction)togglePasscodeLockSetting:(id)sender
{
    if (self.passcodeLockSwitch.on) {
        VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate.playlistViewController.passcodeLockViewController resetPasscode];
    } else
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:@"PasscodeProtection"];
}

- (IBAction)dismiss:(id)sender
{
    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.playlistViewController.navigationController dismissModalViewControllerAnimated:YES];
}

@end
