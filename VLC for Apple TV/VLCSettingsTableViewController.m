/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSettingsTableViewController.h"
#import "IASKSettingsReader.h"
#import "IASKSpecifier.h"

#define SettingsReUseIdentifier @"SettingsReUseIdentifier"
#define SettingsHeaderReUseIdentifier @"SettingsHeaderReUseIdentifier"

@interface VLCSettingsTableViewController ()
{
    NSUserDefaults *_userDefaults;
    IASKSettingsReader *_settingsReader;
}
@end

@implementation VLCSettingsTableViewController

- (void)loadView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:SettingsHeaderReUseIdentifier];
    self.view = tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    _userDefaults = [NSUserDefaults standardUserDefaults];
    _settingsReader = [[IASKSettingsReader alloc] init];
}

- (NSString *)title
{
    return NSLocalizedString(@"Settings", nil);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _settingsReader.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_settingsReader numberOfRowsForSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SettingsReUseIdentifier];

    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:SettingsReUseIdentifier];

    IASKSpecifier *specifier = [_settingsReader specifierForIndexPath:indexPath];
    cell.textLabel.text = [specifier title];
    NSString *specifierType = specifier.type;
    if ([specifierType isEqualToString:kIASKPSMultiValueSpecifier]) {
        NSArray *titles = [specifier multipleTitles];
        NSArray *values = [specifier multipleValues];
        NSUInteger selectedIndex = [values indexOfObject:[_userDefaults objectForKey:[specifier key]]];
        NSUInteger titlesCount = titles.count;
        if (selectedIndex < titlesCount)
            cell.detailTextLabel.text = [_settingsReader titleForStringId:titles[selectedIndex]];
        else {
            selectedIndex = [values indexOfObject:[specifier defaultValue]];
            if (selectedIndex < titlesCount)
                cell.detailTextLabel.text = [_settingsReader titleForStringId:titles[selectedIndex]];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([specifierType isEqualToString:kIASKPSToggleSwitchSpecifier]) {
        cell.detailTextLabel.text = [_userDefaults boolForKey:[specifier key]] ? NSLocalizedString(@"On", nil) : NSLocalizedString(@"Off", nil);
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_settingsReader titleForSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    IASKSpecifier *specifier = [_settingsReader specifierForIndexPath:indexPath];

    NSString *specifierType = specifier.type;
    if ([specifierType isEqualToString:kIASKPSMultiValueSpecifier]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:specifier.title
                                                                                 message:nil preferredStyle:UIAlertControllerStyleActionSheet];

        NSUInteger count = [specifier multipleValuesCount];
        NSArray *titles = [specifier multipleTitles];
        NSUInteger indexOfPreferredAction = [[specifier multipleValues] indexOfObject:[_userDefaults objectForKey:[specifier key]]];
        for (NSUInteger i = 0; i < count; i++) {
            id value = [[specifier multipleValues][i] copy];
            UIAlertAction *action = [UIAlertAction actionWithTitle:[_settingsReader titleForStringId:titles[i]]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  [_userDefaults setObject:value forKey:[specifier key]];
                                                                  [_userDefaults synchronize];
                                                                  [self.tableView reloadData];
                                                              }];
            [alertController addAction:action];
            if (i == indexOfPreferredAction)
                [alertController setPreferredAction:action];
        }

        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil]];

        [self presentViewController:alertController animated:YES completion:nil];
    } else if ([specifierType isEqualToString:kIASKPSToggleSwitchSpecifier]) {
        NSString *specifierKey = [specifier key];
        [_userDefaults setBool:![_userDefaults boolForKey:specifierKey] forKey:specifierKey];
        [_userDefaults synchronize];
        [self.tableView reloadData];
    }
}

@end
