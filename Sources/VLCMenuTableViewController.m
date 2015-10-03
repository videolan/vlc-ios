/*****************************************************************************
 * VLCMenuTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *          Tamas Timar <ttimar.vlc # gmail.com>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMenuTableViewController.h"
#import "VLCSidebarViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "VLCWiFiUploadTableViewCell.h"
#import "VLCAppDelegate.h"
#import "IASKAppSettingsViewController.h"
#import "VLCServerListViewController.h"
#import "VLCOpenNetworkStreamViewController.h"
#import "VLCSettingsController.h"
#import "VLCAboutViewController.h"
#import "VLCLibraryViewController.h"
#import "VLCBugreporter.h"
#import "VLCCloudServicesTableViewController.h"
#import "VLCNavigationController.h"

#define ROW_HEIGHT 50.
#define HEADER_HEIGHT 22.

static NSString *CellIdentifier = @"VLCMenuCell";
static NSString *WiFiCellIdentifier = @"VLCMenuWiFiCell";

@interface VLCMenuTableViewController () <UITableViewDataSource, UITableViewDelegate>
{
    NSArray *_sectionHeaderTexts;
    NSArray *_menuItemsSectionOne;
    NSArray *_menuItemsSectionTwo;
    NSArray *_menuItemsSectionThree;
    NSMutableSet *_hiddenSettingKeys;

    UITableView *_menuTableView;
}
@property (strong, nonatomic) IASKAppSettingsViewController *settingsViewController;
@property (strong, nonatomic) VLCSettingsController *settingsController;

@end

@implementation VLCMenuTableViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGRect viewRect = self.view.frame;

    _sectionHeaderTexts = @[@"SECTION_HEADER_LIBRARY", @"SECTION_HEADER_NETWORK", @"Settings"];
    _menuItemsSectionOne = @[@"LIBRARY_ALL_FILES", @"LIBRARY_MUSIC", @"LIBRARY_SERIES"];
    _menuItemsSectionTwo = @[@"LOCAL_NETWORK", @"OPEN_NETWORK", @"DOWNLOAD_FROM_HTTP", @"WEBINTF_TITLE", @"CLOUD_SERVICES"];
    _menuItemsSectionThree = @[@"Settings", @"ABOUT_APP"];

    _menuTableView = ({
        NSUInteger count = _menuItemsSectionOne.count + _menuItemsSectionTwo.count + _menuItemsSectionThree.count;
        CGFloat height = (count * ROW_HEIGHT) + (3. * HEADER_HEIGHT);
        CGFloat top = ([UIScreen mainScreen].bounds.size.height - height) / 2.;

        UITableView *tableView = [[UITableView alloc] initWithFrame:
                                  CGRectMake(20., top, viewRect.size.width - 20., height)
                                                              style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        tableView.rowHeight = ROW_HEIGHT;
        tableView.scrollsToTop = NO;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        tableView;
    });

    [self.view addSubview:_menuTableView];

    [_menuTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
}

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    return (orientation == UIInterfaceOrientationPortraitUpsideDown) ? (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) : YES;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) // media
        return _menuItemsSectionOne.count;
    else if (section == 1) // network
        return _menuItemsSectionTwo.count;
    else if (section == 2) // settings & co
        return _menuItemsSectionThree.count;
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *rawTitle;
    NSUInteger section = indexPath.section;
    if (section == 0)
        rawTitle = _menuItemsSectionOne[indexPath.row];
    else if(section == 1)
        rawTitle = _menuItemsSectionTwo[indexPath.row];
    else if(section == 2)
        rawTitle = _menuItemsSectionThree[indexPath.row];

    UITableViewCell *cell;
    if ([rawTitle isEqualToString:@"WEBINTF_TITLE"]) {
        cell = (VLCWiFiUploadTableViewCell *)[tableView dequeueReusableCellWithIdentifier:WiFiCellIdentifier];
        if (cell == nil) {
            cell = [[VLCWiFiUploadTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:WiFiCellIdentifier];
        }
    } else {
        cell = (VLCSidebarViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
            cell = [[VLCSidebarViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    if (section == 0) {
        if ([rawTitle isEqualToString:@"LIBRARY_ALL_FILES"])
            cell.imageView.image = [UIImage imageNamed:@"AllFiles"];
        else if ([rawTitle isEqualToString:@"LIBRARY_MUSIC"])
            cell.imageView.image = [UIImage imageNamed:@"MusicAlbums"];
        else if ([rawTitle isEqualToString:@"LIBRARY_SERIES"])
            cell.imageView.image = [UIImage imageNamed:@"TVShowsIcon"];
    } else if (section == 1) {
        if ([rawTitle isEqualToString:@"LOCAL_NETWORK"])
            cell.imageView.image = [UIImage imageNamed:@"Local"];
        else if ([rawTitle isEqualToString:@"OPEN_NETWORK"])
            cell.imageView.image = [UIImage imageNamed:@"OpenNetStream"];
        else if ([rawTitle isEqualToString:@"DOWNLOAD_FROM_HTTP"])
            cell.imageView.image = [UIImage imageNamed:@"Downloads"];
        else if ([rawTitle isEqualToString:@"CLOUD_SERVICES"])
            cell.imageView.image = [UIImage imageNamed:@"iCloudIcon"];
    } else if (section == 2) {
        if ([rawTitle isEqualToString:@"Settings"])
            cell.imageView.image = [UIImage imageNamed:@"Settings"];
        else
            cell.imageView.image = [UIImage imageNamed:@"menuCone"];
    }

    if (![rawTitle isEqualToString:@"WEBINTF_TITLE"])
        cell.textLabel.text = NSLocalizedString(rawTitle, nil);

    return cell;
}

#pragma mark - table view delegation
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section < 3)
        return 22.f;
    return 0.;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *headerText = NSLocalizedString(_sectionHeaderTexts[section], nil);
    UIView *headerView = nil;
    if (headerText) {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, HEADER_HEIGHT)];

        UILabel *textLabel = [UILabel new];
        textLabel.text = headerText;
        textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:[UIFont systemFontSize]];
        textLabel.textColor = [UIColor whiteColor];
        textLabel.backgroundColor = [UIColor clearColor];
        [textLabel sizeToFit];
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [headerView addSubview:textLabel];

        UIView *bottomLine = [UIView new];
        bottomLine.backgroundColor = [UIColor whiteColor];
        bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
        [headerView addSubview:bottomLine];

        NSDictionary *dict = NSDictionaryOfVariableBindings(textLabel,bottomLine);
        [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomLine]|" options:0 metrics:0 views:dict]];
        [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(12)-[textLabel]" options:0 metrics:0 views:dict]];
        [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=0-[textLabel]->=0-[bottomLine(0.5)]|" options:0 metrics:0 views:dict]];
    }
    return headerView;
}

#pragma mark - menu implementation

- (void)_revealItem:(NSUInteger)itemIndex inSection:(NSUInteger)sectionNumber
{
    UIViewController *viewController;
    VLCAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (sectionNumber == 1) {
        if (itemIndex == 0)
            viewController = [[VLCServerListViewController alloc] init];
        else if (itemIndex == 1) {
            viewController = [[VLCOpenNetworkStreamViewController alloc] initWithNibName:@"VLCOpenNetworkStreamViewController" bundle:nil];
        } else if (itemIndex == 2)
            viewController = [VLCDownloadViewController sharedInstance];
        else if (itemIndex == 3)
            [((VLCWiFiUploadTableViewCell *)[_menuTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:itemIndex inSection:sectionNumber]]) toggleHTTPServer];
        else if (itemIndex == 4)
            viewController = [[VLCCloudServicesTableViewController alloc] initWithNibName:@"VLCCloudServicesTableViewController" bundle:nil];
    } else if (sectionNumber == 2) {
        if (itemIndex == 0) {
            if (!self.settingsController)
                self.settingsController = [[VLCSettingsController alloc] init];
            VLCSettingsController *settingsController = self.settingsController;

            if (!self.settingsViewController) {
                self.settingsViewController = [[IASKAppSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                settingsController.viewController = self.settingsViewController;
                self.settingsViewController.navigationItem.leftBarButtonItem = [UIBarButtonItem themedRevealMenuButtonWithTarget:self.settingsController.viewController andSelector:@selector(dismiss:)];
            }

            IASKAppSettingsViewController *settingsVC = self.settingsViewController;
            settingsVC.modalPresentationStyle = UIModalPresentationFormSheet;
            settingsVC.delegate = self.settingsController;
            settingsVC.showDoneButton = NO;
            settingsVC.showCreditsFooter = NO;

            viewController = settingsVC;
        } else if (itemIndex == 1)
            viewController = [[VLCAboutViewController alloc] init];
    } else {
        viewController = appDelegate.libraryViewController;
        [(VLCLibraryViewController *)viewController setLibraryMode:(int)itemIndex];
    }

    if (!viewController)
        return;

    VLCSidebarController *sidebarController = [VLCSidebarController sharedInstance];
    if ([sidebarController.contentViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navCon = (UINavigationController*)sidebarController.contentViewController;
        navCon.viewControllers = @[viewController];
    } else
        sidebarController.contentViewController = [[VLCNavigationController alloc] initWithRootViewController:viewController];
    [sidebarController hideSidebar];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self _revealItem:indexPath.row inSection:indexPath.section];
}

#pragma mark Public Methods
- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition
{
    [_menuTableView selectRowAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition];
    if (scrollPosition == UITableViewScrollPositionNone)
        [_menuTableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
    [self _revealItem:indexPath.row inSection:indexPath.section];
}

#pragma mark - shake for support
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
        [[VLCBugreporter sharedInstance] handleBugreportRequest];
}

@end
