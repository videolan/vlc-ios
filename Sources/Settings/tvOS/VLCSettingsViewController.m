/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSettingsViewController.h"

#import "IASKSettingsReader.h"
#import "IASKSpecifier.h"
#import "VLCAboutViewController.h"

#define SettingsReUseIdentifier @"SettingsReUseIdentifier"

@interface VLCSettingsViewController () <UITableViewDataSource, UITableViewDelegate>
{
    BOOL _debugLoggingOn;
}

@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (strong, nonatomic) IASKSettingsReader *settingsReader;

@end

@implementation VLCSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (@available(tvOS 13.0, *)) {
        self.navigationController.navigationBarHidden = YES;
    }

    self.userDefaults = [NSUserDefaults standardUserDefaults];
    self.settingsReader = [[IASKSettingsReader alloc] init];

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeAll ^ UIRectEdgeTop;

    self.tableView.opaque = NO;
    self.tableView.backgroundColor = [UIColor clearColor];

    _debugLoggingOn = [self.userDefaults boolForKey:kVLCSaveDebugLogs];
}

- (NSString *)title
{
    return NSLocalizedString(@"Settings", nil);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    /* if debug logging was disabled in this session of the settings screen, delete all the logs */
    if (_debugLoggingOn) {
        if (![self.userDefaults boolForKey:kVLCSaveDebugLogs]) {
            NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString* logFilePath = [searchPaths.firstObject stringByAppendingPathComponent:@"Logs"];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:logFilePath error:nil];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.settingsReader.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.settingsReader numberOfRowsForSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SettingsReUseIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:SettingsReUseIdentifier];
    }

    IASKSpecifier *specifier = [self.settingsReader specifierForIndexPath:indexPath];
    cell.textLabel.text = [specifier title];
    NSString *specifierType = specifier.type;
    if ([specifierType isEqualToString:kIASKPSMultiValueSpecifier]) {
        NSArray *titles = [specifier multipleTitles];
        NSArray *values = [specifier multipleValues];
        NSUInteger selectedIndex = [values indexOfObject:[self.userDefaults objectForKey:[specifier key]]];
        NSUInteger titlesCount = titles.count;
        if (selectedIndex < titlesCount)
            cell.detailTextLabel.text = [_settingsReader titleForId:titles[selectedIndex]];
        else {
            selectedIndex = [values indexOfObject:[specifier defaultValue]];
            if (selectedIndex < titlesCount)
                cell.detailTextLabel.text = [_settingsReader titleForId:titles[selectedIndex]];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([specifierType isEqualToString:kIASKPSToggleSwitchSpecifier]) {
        cell.detailTextLabel.text = [self.userDefaults boolForKey:[specifier key]] ? NSLocalizedString(@"ON", nil) : NSLocalizedString(@"OFF", nil);
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else if ([specifierType isEqualToString:@"PSTextFieldSpecifier"]) {
        cell.detailTextLabel.text = [self.userDefaults stringForKey:[specifier key]];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.detailTextLabel.text = @"";
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.settingsReader titleForSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    IASKSpecifier *specifier = [self.settingsReader specifierForIndexPath:indexPath];

    NSString *specifierType = specifier.type;
    if ([specifierType isEqualToString:kIASKPSMultiValueSpecifier]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:specifier.title
                                                                                 message:nil preferredStyle:UIAlertControllerStyleActionSheet];

        NSUInteger count = [specifier multipleValuesCount];
        NSArray *titles = [specifier multipleTitles];
        NSValue *currentValue = [self.userDefaults objectForKey:[specifier key]] ?: [specifier defaultValue];
        NSUInteger indexOfPreferredAction = [[specifier multipleValues] indexOfObject:currentValue];
        for (NSUInteger i = 0; i < count; i++) {
            id value = [[specifier multipleValues][i] copy];
            UIAlertAction *action = [UIAlertAction actionWithTitle:[_settingsReader titleForId:titles[i]]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               [self.userDefaults setObject:value forKey:[specifier key]];
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                                                               });
                                                           }];
            [alertController addAction:action];
            if (i == indexOfPreferredAction) {
                [alertController setPreferredAction:action];
            }
        }

        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil]];

        [self presentViewController:alertController animated:YES completion:nil];
    } else if ([specifierType isEqualToString:kIASKPSToggleSwitchSpecifier]) {
        NSString *specifierKey = [specifier key];
        [self.userDefaults setBool:![self.userDefaults boolForKey:specifierKey] forKey:specifierKey];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    } else if ([specifierType isEqualToString:@"PSTextFieldSpecifier"]) {
        NSString *saveString = NSLocalizedString(@"BUTTON_SAVE", nil);
        NSString *cancelString = NSLocalizedString(@"BUTTON_CANCEL", nil);

        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:specifier.title
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelString
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        UIAlertAction *saveAction = [UIAlertAction actionWithTitle:saveString
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
            NSString *enteredText = alertController.textFields.firstObject.text;
            [self.userDefaults setObject:enteredText forKey:specifier.key];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            });
        }];

        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = [self.userDefaults stringForKey:specifier.key];
            if ([specifier.key isEqualToString:kVLCSettingNetworkSatIPChannelListUrl]) {
                textField.keyboardType = UIKeyboardTypeURL;
                if (@available(tvOS 10.0, *)) {
                    textField.textContentType = UITextContentTypeURL;
                }
            }

            [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification
                                                              object:textField
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification * _Nonnull note) {
                saveAction.enabled = (textField.text.length != 0);
            }];
        }];

        [alertController addAction:cancelAction];
        [alertController addAction:saveAction];

        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        VLCAboutViewController *targetViewController = [[VLCAboutViewController alloc] initWithNibName:nil bundle:nil];
        targetViewController.title = specifier.title;
        [self presentViewController:targetViewController
                           animated:YES
                         completion:nil];
    }
}


@end
