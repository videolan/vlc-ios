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
#import "VLC-Swift.h"

NSString * const kVLCSectionTableHeaderViewIdentifier = @"VLCSectionTableHeaderViewIdentifier";

@interface VLCSettingsController ()<PAPasscodeViewControllerDelegate>
{
    VLCActionSheet *actionSheet;
    VLCSettingsSpecifierManager *specifierManager;
    MediaLibraryService *_medialibraryService;
}
@end

@implementation VLCSettingsController

- (instancetype)initWithMediaLibraryService:(MediaLibraryService *)medialibraryService
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        [self setupUI];
        _medialibraryService = medialibraryService;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingDidChange:) name:kIASKAppSettingChanged object:nil];
    }

    return self;
}

- (void)setupUI
{
    self.title = NSLocalizedString(@"Settings", nil);
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle: NSLocalizedString(@"Settings", nil)
                                                    image: [UIImage imageNamed:@"Settings"]
                                            selectedImage: [UIImage imageNamed:@"Settings"]];
    self.tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.settings;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.modalPresentationStyle = UIModalPresentationFormSheet;
    self.delegate = self;
    self.showDoneButton = NO;
    self.showCreditsFooter = NO;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_ABOUT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(showAbout)];
    self.navigationItem.leftBarButtonItem.accessibilityIdentifier = VLCAccessibilityIdentifier.about;
    self.navigationItem.rightBarButtonItem = nil;

    self.neverShowPrivacySettings = YES;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 100;
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 64;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[VLCSectionTableHeaderView class] forHeaderFooterViewReuseIdentifier:kVLCSectionTableHeaderViewIdentifier];
    [self themeDidChange];
    
    actionSheet = [[VLCActionSheet alloc] init];
    actionSheet.modalPresentationStyle = UIModalPresentationCustom;
    
    specifierManager = [[VLCSettingsSpecifierManager alloc] initWithSettingsReader:self.settingsReader settingsStore:self.settingsStore];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeDidChange)
                                                 name:kVLCThemeDidChangeNotification
                                               object:nil];
}

- (void)themeDidChange
{
    self.view.backgroundColor = PresentationTheme.current.colors.background;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self filterCellsWithAnimation:NO];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return PresentationTheme.current.colors.statusBarStyle;
}

- (NSSet *)hiddenBiometryKeys
{
    if (@available(iOS 11.0.1, *)) {
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
    if ([notification.userInfo objectForKey: kVLCSettingPasscodeOnKey]) {
        BOOL passcodeOn = [[notification.userInfo objectForKey:kVLCSettingPasscodeOnKey] boolValue];

        [self updateForPasscode:nil];
        if (passcodeOn) {
            PAPasscodeViewController *passcodeLockController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionSet];
            passcodeLockController.delegate = self;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:passcodeLockController];
            // Specify modal presentation style due to iOS 13 behaviour
            navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self.navigationController presentViewController:navigationController animated:YES completion:nil];
        }
    } else if ([notification.userInfo objectForKey:kVLCSettingBackupMediaLibrary]) {
        BOOL backupMediaLibrary = [[notification.userInfo objectForKey:kVLCSettingBackupMediaLibrary] boolValue];
        NSNumber *excludeMediaLibrary = [NSNumber numberWithBool:!backupMediaLibrary];
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = [searchPaths firstObject];

        if (documentPath) {
            NSURL *documentURL = [NSURL fileURLWithPath:documentPath];
            [documentURL setResourceValue:excludeMediaLibrary forKey:NSURLIsExcludedFromBackupKey error:nil];
        } else {
            [self.settingsStore setBool:!backupMediaLibrary forKey:kVLCSettingBackupMediaLibrary];
        }
    }
}

- (void)showAbout
{
    VLCAboutViewController *aboutVC = [[VLCAboutViewController alloc] init];
    UINavigationController *modalNavigationController = [[UINavigationController alloc] initWithRootViewController:aboutVC];
    [self presentViewController:modalNavigationController animated:YES completion:nil];
}

#pragma mark - PAPasscode delegate

- (void)PAPasscodeViewControllerDidCancel:(PAPasscodeViewController *)controller
{
    [self updateForPasscode:nil];
    [self.settingsStore setBool:false forKey:kVLCSettingPasscodeOnKey];
}

- (void)PAPasscodeViewControllerDidSetPasscode:(PAPasscodeViewController *)controller
{
    [self updateForPasscode:controller.passcode];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IASKSpecifier *specifier = [self.settingsReader specifierForIndexPath:indexPath];
    VLCSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:specifier.type];
    if (!cell) {
        cell = [[VLCSettingsTableViewCell alloc] initWithReuseIdentifier:specifier.type target:self];
    }
    [cell configureWithSpecifier:specifier settingsValue:[self.settingsStore objectForKey:specifier.key]];
    return cell;
}

- (void)updateForPasscode:(NSString *)passcode
{
    NSError *error = nil;
    [VLCKeychainCoordinator setPasscodeWithPasscode:passcode error:&error];
    if (error == nil) {
        if (passcode != nil) {
            [[CSSearchableIndex defaultSearchableIndex] deleteAllSearchableItemsWithCompletionHandler:nil];
        } else {
            [_medialibraryService reindexAllMediaForSpotlight];
        }
        //Set manually the value to enable/disable the UISwitch.
        [self filterCellsWithAnimation:YES];
    }
    if ([self.navigationController.presentedViewController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)self.navigationController.presentedViewController).viewControllers.firstObject isKindOfClass:[PAPasscodeViewController class]]) {
        [self.navigationController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - InAppSettings customization

- (UIView *)settingsViewController:(id<IASKViewController>)settingsViewController tableView:(UITableView *)tableView viewForHeaderForSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    }
    VLCSectionTableHeaderView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kVLCSectionTableHeaderViewIdentifier];
    header.label.text = [self.settingsReader titleForSection:section];
    return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    IASKSpecifier *specifier = [self.settingsReader specifierForIndexPath:indexPath];

    if ([specifier.type isEqualToString: kIASKPSMultiValueSpecifier]) {
        [self displayActionSheetFor:specifier];
    } else if ([specifier.type isEqualToString: kIASKButtonSpecifier]) {
        [self buttonTappedFor:specifier];
    } else {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (void)displayActionSheetFor:(IASKSpecifier *)specifier
{
    specifierManager.specifier = specifier;
    actionSheet.delegate = specifierManager;
    actionSheet.dataSource = specifierManager;
    
    [self presentViewController:actionSheet animated:NO completion:^{
        [self->actionSheet.collectionView selectItemAtIndexPath:self->specifierManager.selectedIndex animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    }];
}

- (void)buttonTappedFor:(IASKSpecifier *)specifier
{
    __weak typeof(self) weakSelf = self;

    if ([specifier.specifierDict[@"Key"] isEqual: @"forceMediaLibraryRescan"]) {
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:NSLocalizedString(@"FORCE_RESCAN_TITLE", "")
                                                     message:NSLocalizedString(@"FORCE_RESCAN_MESSAGE", "")
                                              preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* rescanAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_RESCAN", "")
                                                                style:UIAlertActionStyleDestructive
                                                              handler:^(UIAlertAction * action) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [strongSelf->_medialibraryService forceRescan];
            });
        }];
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", "")
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];

        [alert addAction:cancelAction];
        [alert addAction:rescanAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
