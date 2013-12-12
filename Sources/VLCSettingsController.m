/*****************************************************************************
 * VLCSettingsController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSettingsController.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "IASKSettingsReader.h"
#import "IASKAppSettingsViewController.h"
#import "PAPasscodeViewController.h"
#import <DropboxSDK/DropboxSDK.h>
#import "VLCGoogleDriveController.h"

@interface VLCSettingsController ()<PAPasscodeViewControllerDelegate, IASKSettingsDelegate>
{
    NSString *_currentUnlinkSpecifier;
    NSString *_currentUnlinkDialogTitle;
    NSString *_currentCloudName;
}
@end

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
            [self.viewController presentViewController:passcodeLockController animated:YES completion:nil];
        }
    }
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
    [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController] toggleSidebar:![(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController].sidebarShowing duration:kGHRevealSidebarDefaultAnimationDuration];
}

- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForSpecifier:(IASKSpecifier*)specifier
{
    _currentUnlinkSpecifier = specifier.key;

    if ([_currentUnlinkSpecifier isEqualToString:@"UnlinkDropbox"]) {
        _currentCloudName = @"Dropbox";
        _currentUnlinkDialogTitle = NSLocalizedString(@"SETTINGS_UNLINK_DROPBOX", @"");
    } else if ([_currentUnlinkSpecifier isEqualToString:@"UnlinkGoogleDrive"]) {
        _currentCloudName = @"Google Drive";
        _currentUnlinkDialogTitle = NSLocalizedString(@"SETTINGS_UNLINK_GOOGLEDRIVE", @"");
    }

    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:_currentUnlinkDialogTitle
                          message:[NSString stringWithFormat:NSLocalizedString(@"CLOUDUNLINKING", @""), _currentCloudName]
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"")
                          otherButtonTitles:NSLocalizedString(@"BUTTON_CLOUDUNLINKING", @""), nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        if ([_currentUnlinkSpecifier isEqualToString:@"UnlinkDropbox"])
            [[DBSession sharedSession] unlinkAll];
        else if ([_currentUnlinkSpecifier isEqualToString:@"UnlinkGoogleDrive"])
            [[VLCGoogleDriveController sharedInstance] logout];
        _currentUnlinkSpecifier = nil;

        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:_currentUnlinkDialogTitle
                              message:[NSString stringWithFormat:NSLocalizedString(@"CLOUDUNLINKING_DONE", @""), _currentCloudName]
                              delegate:self
                              cancelButtonTitle:NSLocalizedString(@"BUTTON_DONE", @"")
                              otherButtonTitles:nil];
        [alert show];
        _currentUnlinkDialogTitle = nil;
        _currentCloudName = nil;
    }
}

#pragma mark - PAPasscode delegate

- (void)PAPasscodeViewControllerDidCancel:(PAPasscodeViewController *)controller
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(NO) forKey:kVLCSettingPasscodeOnKey];
    [defaults synchronize];
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)PAPasscodeViewControllerDidSetPasscode:(PAPasscodeViewController *)controller
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(YES) forKey:kVLCSettingPasscodeOnKey];
    [defaults setObject:controller.passcode forKey:kVLCSettingPasscodeKey];
    [defaults synchronize];

    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
