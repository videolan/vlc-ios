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
        if ([self.enterCodeField.text isEqualToString:_passcode]) {
            VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
            appDelegate.playlistViewController.nextPasscodeCheckDate = [NSDate dateWithTimeIntervalSinceNow:300]; // five min
            appDelegate.playlistViewController.passcodeValidated = YES;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)resetPasscode
{
    
}

@end
