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
#import "IASKSettingsReader.h"
#import "PAPasscodeViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "VLC_iOS-Swift.h"

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
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    self.delegate = self;
    self.showDoneButton = NO;
    self.showCreditsFooter = NO;
    [self themeDidChange];
}

- (void)themeDidChange
{
    self.view.backgroundColor = PresentationTheme.current.colors.settingsBackground;
    self.tableView.separatorColor = PresentationTheme.current.colors.settingsSeparatorColor;
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self filterCellsWithAnimation:NO];
}

- (NSSet *)hiddenBiometryKeys
{
    if (@available(iOS 11.0, *)) {
        LAContext *laContext = [[LAContext alloc] init];
        if ([laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil]) {
            switch (laContext.biometryType) {
                case LABiometryTypeFaceID:
                    return [NSSet setWithObject:kVLCSettingPasscodeAllowTouchID];
                case LABiometryTypeTouchID:
                    return [NSSet setWithObject:kVLCSettingPasscodeAllowFaceID];
                case LABiometryNone:
                    return [NSSet setWithObjects:kVLCSettingPasscodeAllowFaceID, kVLCSettingPasscodeAllowTouchID, nil];
            }
        }
        return [NSSet setWithObjects:kVLCSettingPasscodeAllowFaceID, kVLCSettingPasscodeAllowTouchID, nil];
    }
    return [NSSet setWithObject:kVLCSettingPasscodeAllowFaceID];
}

- (void)filterCellsWithAnimation:(BOOL)shouldAnimate
{
    NSMutableSet *hideKeys = [[NSMutableSet alloc] init];
    if (![VLCKeychainCoordinator passcodeLockEnabled]) {
        [hideKeys addObject:kVLCSettingPasscodeAllowTouchID];
        [hideKeys addObject:kVLCSettingPasscodeAllowFaceID];
        [self setHiddenKeys:hideKeys animated:shouldAnimate];
        return;
    }
    [self setHiddenKeys:[self hiddenBiometryKeys] animated:shouldAnimate];
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
            [self updateForPasscode:nil];
        }
    }
    if ([notification.object isEqual:kVLCSettingAppTheme]) {
        BOOL darkTheme = [[notification.userInfo objectForKey:kVLCSettingAppTheme] boolValue];
        PresentationTheme.current = darkTheme ? PresentationTheme.darkTheme : PresentationTheme.brightTheme;
        [self themeDidChange];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = PresentationTheme.current.colors.settingsCellBackground;
    cell.textLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    cell.detailTextLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor;
    return cell;
}

- (void)updateForPasscode:(NSString *)passcode
{
    NSError *error = nil;
    [VLCKeychainCoordinator setPasscodeWithPasscode:passcode error:&error];
    if (error == nil) {
        if (passcode == nil) {
            //Set manually the value to NO to disable the UISwitch.
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kVLCSettingPasscodeOnKey];
        }
        [self updateUIAndCoreSpotlightForPasscodeSetting:passcode != nil];
    }
    if ([self.navigationController.presentedViewController isKindOfClass:[PAPasscodeViewController class]]) {
        [self.navigationController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}
@end
