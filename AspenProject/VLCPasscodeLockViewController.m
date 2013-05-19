//
//  VLCPasscodeLockViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 18.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCPasscodeLockViewController.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"

@implementation VLCPasscodeLockViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.enterCodeField.secureTextEntry = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _passcode = [defaults objectForKey:@"Passcode"];

    self.enterPasscodeLabel.text = NSLocalizedString(@"ENTER_PASSCODE", @"");

    [self.navigationController setNavigationBarHidden:YES animated:NO];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    self.enterCodeField.text = @"";
    [self.enterCodeField becomeFirstResponder];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [super viewWillDisappear:animated];
}

- (IBAction)textFieldValueChanged:(id)sender
{
    if (self.enterCodeField.text.length == 4) {
        VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
        if (_resetStage == 1) {
            _tmpPasscode = self.enterCodeField.text;
            self.enterCodeField.text = @"";
            self.enterPasscodeLabel.text = NSLocalizedString(@"REENTER_PASSCODE", @"");
            _resetStage = 2;
        } else if (_resetStage == 2) {
            if ([self.enterCodeField.text isEqualToString:_tmpPasscode]) {
                NSUserDefaults *defaults;
                [defaults setObject:@1 forKey:@"PasscodeProtection"];
                [defaults setObject:_tmpPasscode forKey:@"Passcode"];
                _passcode = _tmpPasscode;
                _resetStage = 0;
                appDelegate.playlistViewController.nextPasscodeCheckDate = [NSDate dateWithTimeIntervalSinceNow:300]; // five min
                appDelegate.playlistViewController.passcodeValidated = YES;
                [self.view removeFromSuperview];
            }
        } else if ([self.enterCodeField.text isEqualToString:_passcode]) {
            appDelegate.playlistViewController.nextPasscodeCheckDate = [NSDate dateWithTimeIntervalSinceNow:300]; // five min
            appDelegate.playlistViewController.passcodeValidated = YES;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)resetPasscode
{
    _resetStage = 1;
}

@end
