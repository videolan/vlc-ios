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
#import "PAPasscodeViewController.h"
#import "VLCKeychainCoordinator.h"

@interface VLCSettingsController ()<PAPasscodeViewControllerDelegate, IASKSettingsDelegate>

@end

@implementation VLCSettingsController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingDidChange:) name:kIASKAppSettingChanged object:nil];
    }

    return self;
}

- (void)viewDidLoad
{
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(dismiss:)];
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    self.delegate = self;
    self.showDoneButton = NO;
    self.showCreditsFooter = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self filterCellsWithAnimation:NO];
}

- (void)filterCellsWithAnimation:(BOOL)shouldAnimate
{
    NSMutableSet *hideKeys = [[NSMutableSet alloc] init];

    VLCKeychainCoordinator *keychainCoordinator = [VLCKeychainCoordinator defaultCoordinator];
    if (![keychainCoordinator passcodeLockEnabled])
        [hideKeys addObject:kVLCSettingPasscodeAllowTouchID];

    [self setHiddenKeys:hideKeys animated:shouldAnimate];
}

- (void)settingDidChange:(NSNotification*)notification
{
    if ([notification.object isEqual:kVLCSettingPasscodeOnKey]) {
        BOOL passcodeOn = [[notification.userInfo objectForKey:kVLCSettingPasscodeOnKey] boolValue];

        if (passcodeOn) {
            PAPasscodeViewController *passcodeLockController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionSet];
            passcodeLockController.delegate = self;
            [self presentViewController:passcodeLockController animated:YES completion:nil];
        } else {
            [[VLCKeychainCoordinator defaultCoordinator] setPasscode:nil];
            [self didChangePasscodeStatus:NO];
        }
    }
}

- (void)didChangePasscodeStatus:(BOOL)passcodeEnabled
{
    [self filterCellsWithAnimation:YES];

    BOOL spotlightEnabled = !passcodeEnabled;
    [[MLMediaLibrary sharedMediaLibrary] setSpotlightIndexingEnabled:spotlightEnabled];
    if (!spotlightEnabled) {
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
    [[VLCKeychainCoordinator defaultCoordinator] setPasscode:nil];

    //Set manually the value to NO to disable the UISwitch.
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kVLCSettingPasscodeOnKey];
    [self didChangePasscodeStatus:NO];

    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)PAPasscodeViewControllerDidSetPasscode:(PAPasscodeViewController *)controller
{
    [[VLCKeychainCoordinator defaultCoordinator] setPasscode:controller.passcode];
    [self didChangePasscodeStatus:YES];

    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
