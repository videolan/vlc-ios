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
#import "VLCLibraryViewController.h"
#import "IASKSettingsReader.h"
#import "IASKAppSettingsViewController.h"
#import "PAPasscodeViewController.h"
#import "VLCKeychainCoordinator.h"

@interface VLCSettingsController ()<PAPasscodeViewControllerDelegate, IASKSettingsDelegate>

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

- (void)willShow
{
    [self filterCellsWithAnimation:NO];
}

- (void)filterCellsWithAnimation:(BOOL)shouldAnimate
{
    NSMutableSet *hideKeys = [[NSMutableSet alloc] init];

    VLCKeychainCoordinator *keychainCoordinator = [VLCKeychainCoordinator defaultCoordinator];
    if (![keychainCoordinator passcodeLockEnabled])
        [hideKeys addObject:kVLCSettingPasscodeAllowTouchID];

    [self.viewController setHiddenKeys:hideKeys animated:shouldAnimate];
}

- (void)settingDidChange:(NSNotification*)notification
{
    if ([notification.object isEqual:kVLCSettingPasscodeOnKey]) {
        BOOL passcodeOn = [[notification.userInfo objectForKey:kVLCSettingPasscodeOnKey] boolValue];

        if (passcodeOn) {
            PAPasscodeViewController *passcodeLockController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionSet];
            passcodeLockController.delegate = self;
            [self.viewController presentViewController:passcodeLockController animated:YES completion:nil];
        } else {
            [self updateForPasscode:nil];
        }
    }
}

- (void)updateUIAndCoreSpotlightForPasscodeSetting:(BOOL)passcodeOn
{
    [self filterCellsWithAnimation:YES];

    [[MLMediaLibrary sharedMediaLibrary] setSpotlightIndexingEnabled:!passcodeOn];
    if (passcodeOn) {
        // delete whole index for VLC
        [[CSSearchableIndex defaultSearchableIndex] deleteAllSearchableItemsWithCompletionHandler:nil];
    }
}

#pragma mark - IASKSettings delegate

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
    [[VLCSidebarController sharedInstance] toggleSidebar];
}

#pragma mark - PAPasscode delegate

- (void)PAPasscodeViewControllerDidCancel:(PAPasscodeViewController *)controller
{
    [self updateForPasscode:nil];
}

- (void)PAPasscodeViewControllerDidSetPasscode:(PAPasscodeViewController *)controller
{
    [self updateForPasscode:controller.passcode];
}

- (void)updateForPasscode:(NSString *)passcode
{
    if (passcode == nil) {
        //Set manually the value to NO to disable the UISwitch.
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kVLCSettingPasscodeOnKey];
    }
    [[VLCKeychainCoordinator defaultCoordinator] setPasscode:passcode];
    [self updateUIAndCoreSpotlightForPasscodeSetting:passcode != nil];
    if ([self.navigationController.presentedViewController isKindOfClass:[PAPasscodeViewController class]]) {
        [self.navigationController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}
@end
