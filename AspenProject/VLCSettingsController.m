//
//  VLCSettingsViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 23.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCSettingsController.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "IASKSettingsReader.h"
#import <DropboxSDK/DropboxSDK.h>

@implementation VLCSettingsController

- (id)init
{
    self = [super init];
    if (self)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingDidChange:) name:kIASKAppSettingChanged object:nil];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)settingDidChange:(NSNotification*)notification
{
    if ([notification.object isEqual:kVLCSettingPasscodeOnKey]) {
        BOOL passcodeOn = [[notification.userInfo objectForKey:kVLCSettingPasscodeOnKey] boolValue];

        if (passcodeOn) {
            PAPasscodeViewController *passcodeLockController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionSet];
            passcodeLockController.delegate = self;
            [self.viewController presentModalViewController:passcodeLockController animated:YES];
        }
    }
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
    [self.viewController.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForSpecifier:(IASKSpecifier*)specifier {
    if ([specifier.key isEqualToString:@"UnlinkDropbox"])
        [[DBSession sharedSession] unlinkAll];
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
