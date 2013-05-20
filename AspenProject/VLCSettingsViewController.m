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
    self.audioStretchingLabel.text = NSLocalizedString(@"PREF_AUDIOSTRETCH", @"");
    self.debugOutputLabel.text = NSLocalizedString(@"PREF_VERBOSEDEBUG", @"");
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.passcodeLockSwitch.on = [[defaults objectForKey:kVLCSettingPasscodeOnKey] intValue];
    self.audioPlaybackInBackgroundSwitch.on = [[defaults objectForKey:kVLCSettingContinueAudioInBackgroundKey] intValue];
    self.audioStretchingSwitch.on = ![[defaults objectForKey:kVLCSettingStretchAudio] isEqualToString:kVLCSettingStretchAudioDefaultValue];
    self.debugOutputSwitch.on = [[defaults objectForKey:kVLCSettingVerboseOutput] isEqualToString:kVLCSettingVerboseOutputDefaultValue];

    [super viewWillAppear:animated];
}

- (IBAction)toggleSetting:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (sender == self.passcodeLockSwitch) {
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
            [defaults setObject:@0 forKey:kVLCSettingPasscodeOnKey];
        }
    } else if (sender == self.audioPlaybackInBackgroundSwitch) {
        [defaults setObject:@(self.audioPlaybackInBackgroundSwitch.on) forKey:kVLCSettingContinueAudioInBackgroundKey];
    } else if (sender == self.audioStretchingSwitch) {
        if (self.audioStretchingSwitch.on)
            [defaults setObject:@"--audio-time-stretch" forKey:kVLCSettingStretchAudio];
        else
            [defaults setObject:kVLCSettingStretchAudioDefaultValue forKey:kVLCSettingStretchAudio];
    } else if (sender == self.debugOutputSwitch) {
        if (self.debugOutputSwitch.on)
            [defaults setObject:kVLCSettingVerboseOutputDefaultValue forKey:kVLCSettingVerboseOutput];
        else
            [defaults setObject:@"--verbose=0" forKey:kVLCSettingVerboseOutput];
    }

    [defaults synchronize];
}

- (IBAction)dismiss:(id)sender
{
    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.playlistViewController.navigationController dismissModalViewControllerAnimated:YES];
}

@end
