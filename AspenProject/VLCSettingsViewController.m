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
    self.audioPlaybackInBackgroundLabel.text = NSLocalizedString(@"PREF_AUDIOBACKGROUND", @"");
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.passcodeLockSwitch.on = [[defaults objectForKey:kVLCSettingPasscodeOnKey] intValue];
    self.audioPlaybackInBackgroundSwitch.on = [[defaults objectForKey:kVLCSettingContinueAudioInBackgroundKey] intValue];

    [super viewWillAppear:animated];
}

- (IBAction)togglePasscodeLockSetting:(id)sender
{
    if (self.passcodeLockSwitch.on) {
        VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            CGRect frame = self.view.frame;
            frame.size.height -= 44.;
            appDelegate.playlistViewController.passcodeLockViewController.view.frame = frame;
        }
        [self.view addSubview:appDelegate.playlistViewController.passcodeLockViewController.view];
        [appDelegate.playlistViewController.passcodeLockViewController resetPasscode];
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@0 forKey:kVLCSettingPasscodeOnKey];
        [defaults synchronize];
    }
}

- (IBAction)toggleAudioInBackGroundSetting:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(self.audioPlaybackInBackgroundSwitch.on) forKey:kVLCSettingContinueAudioInBackgroundKey];
    [defaults synchronize];
}

- (IBAction)dismiss:(id)sender
{
    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.playlistViewController.navigationController dismissModalViewControllerAnimated:YES];
}

@end
