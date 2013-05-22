//
//  VLCSettingsViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 19.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCSettingsViewController.h"
#import "VLCPlaylistViewController.h"
#import "PAPasscodeViewController.h"
#import "VLCAppDelegate.h"
#import "IASKSettingsReader.h"

@implementation VLCSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IASKAppSettingsViewController*)appSettingsViewController {
	if (!_appSettingsViewController) {
		_appSettingsViewController = [[IASKAppSettingsViewController alloc] init];
		_appSettingsViewController.delegate = self;
	}
	return _appSettingsViewController;
}

- (void)viewDidLoad
{
    self.dismissButton.title = NSLocalizedString(@"BUTTON_DONE", @"");

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingDidChange:) name:kIASKAppSettingChanged object:nil];

    CGRect frame = self.view.frame;
    CGFloat toolbarHeight = self.topToolbar.frame.size.height;
    frame.size.height = frame.size.height - toolbarHeight;
    frame.origin.y = frame.origin.y + toolbarHeight;
    self.appSettingsViewController.tableView.frame = frame;
    [self.view addSubview:self.appSettingsViewController.tableView];

    [super viewDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (IBAction)dismiss:(id)sender
{
    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.playlistViewController.navigationController dismissModalViewControllerAnimated:YES];
}

#pragma mark - IASKAppSettingsViewController delegate

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
    // adapt app behavior if needed
}

- (void)settingDidChange:(NSNotification*)notification
{
    if ([notification.object isEqual:kVLCSettingPasscodeOnKey]) {
        BOOL passcodeOn = (BOOL)[[notification.userInfo objectForKey:@"PasscodeProtection"] intValue];

        if (passcodeOn) {
            PAPasscodeViewController *passcodeLockController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionSet];
            passcodeLockController.delegate = self;
            [self presentModalViewController:passcodeLockController animated:YES];
        }
    }
}

#pragma mark - PAPasscode delegate

- (void)PAPasscodeViewControllerDidCancel:(PAPasscodeViewController *)controller
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(NO) forKey:kVLCSettingPasscodeOnKey];
    [defaults synchronize];
    [controller dismissModalViewControllerAnimated:YES];
}

- (void)PAPasscodeViewControllerDidSetPasscode:(PAPasscodeViewController *)controller
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(YES) forKey:kVLCSettingPasscodeOnKey];
    [defaults setObject:controller.passcode forKey:kVLCSettingPasscodeKey];
    [defaults synchronize];
    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    appDelegate.nextPasscodeCheckDate = [NSDate dateWithTimeIntervalSinceNow:300];

    [controller dismissModalViewControllerAnimated:YES];
}

@end
