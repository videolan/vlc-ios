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
#import "GHRevealViewController.h"

#define ROW_HEIGHT 50
static NSString *CellIdentifier = @"VLCMenuCell";
static NSString *WiFiCellIdentifier = @"VLCMenuWiFiCell";

@interface VLCMenuTableViewController () <UITableViewDataSource, UITableViewDelegate>
{
    NSArray *_sectionHeaderTexts;
    NSArray *_menuItemsSectionOne;
    NSArray *_menuItemsSectionTwo;
    NSArray *_menuItemsSectionThree;
    NSMutableSet *_hiddenSettingKeys;
    
}

@end

@implementation VLCMenuTableViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.frame = CGRectMake(0.0f, 0.0f, kGHRevealSidebarWidth, CGRectGetHeight(self.view.bounds));
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;

    _sectionHeaderTexts = @[@"SECTION_HEADER_LIBRARY", @"SECTION_HEADER_NETWORK", @"Settings"];
    _menuItemsSectionOne = @[@"LIBRARY_ALL_FILES", @"LIBRARY_MUSIC", @"LIBRARY_SERIES"];
    _menuItemsSectionTwo = @[@"LOCAL_NETWORK", @"OPEN_NETWORK", @"DOWNLOAD_FROM_HTTP", @"WEBINTF_TITLE", @"CLOUD_SERVICES"];

    _menuItemsSectionThree = @[@"Settings", @"ABOUT_APP"];

    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, 44.0f + 20.0f, kGHRevealSidebarWidth, CGRectGetHeight(self.view.bounds) - (44.0f + 20.0f)) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = [UIColor colorWithRed:(43.0f/255.0f) green:(43.0f/255.0f) blue:(43.0f/255.0f) alpha:1.0f];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _tableView.rowHeight = ROW_HEIGHT;
    _tableView.scrollsToTop = NO;
    [_tableView registerClass:[VLCWiFiUploadTableViewCell class] forCellReuseIdentifier:WiFiCellIdentifier];

    self.view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kGHRevealSidebarWidth, CGRectGetHeight(self.view.bounds))];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_tableView];

    UIView *brandingBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kGHRevealSidebarWidth, 64.0f)];
    brandingBackgroundView.backgroundColor = [UIColor colorWithRed:0.1608 green:0.1608 blue:0.1608 alpha:1.0000];
    [self.view addSubview:brandingBackgroundView];

    UIImageView *brandingImageView;
    brandingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kGHRevealSidebarWidth, 44.0f + 40.0f)];
    brandingImageView.contentMode = UIViewContentModeCenter;
    brandingImageView.image = [UIImage imageNamed:@"title"];
    [self.view addSubview:brandingImageView];

    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.view.frame = CGRectMake(0.0f, 0.0f,kGHRevealSidebarWidth, CGRectGetHeight(self.view.bounds));
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
        return 21.f;
    return 0.;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSObject *headerText = NSLocalizedString(_sectionHeaderTexts[section], nil);
    UIView *headerView = nil;
    if (headerText != [NSNull null]) {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, 21.0f)];
        headerView.backgroundColor = [UIColor VLCDarkBackgroundColor];

        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectInset(headerView.bounds, 12.0f, 5.0f)];
        textLabel.text = (NSString *) headerText;
        textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:([UIFont systemFontSize] * 0.8f)];
        textLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
        textLabel.shadowColor = [UIColor VLCDarkTextShadowColor];
        textLabel.textColor = [UIColor colorWithRed:(118.0f/255.0f) green:(118.0f/255.0f) blue:(118.0f/255.0f) alpha:1.0f];
        textLabel.backgroundColor = [UIColor clearColor];
        [headerView addSubview:textLabel];

        UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
        topLine.backgroundColor = [UIColor colorWithRed:(95.0f/255.0f) green:(95.0f/255.0f) blue:(95.0f/255.0f) alpha:1.0f];
        [headerView addSubview:topLine];

        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 21.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
        bottomLine.backgroundColor = [UIColor colorWithRed:(16.0f/255.0f) green:(16.0f/255.0f) blue:(16.0f/255.0f) alpha:1.0f];
        [headerView addSubview:bottomLine];
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
            [((VLCWiFiUploadTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:itemIndex inSection:sectionNumber]]) toggleHTTPServer];
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
    UITableView *tableView = self.tableView;
    [tableView selectRowAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition];
    if (scrollPosition == UITableViewScrollPositionNone)
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
    [self _revealItem:indexPath.row inSection:indexPath.section];
}

#pragma mark - shake for support
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
        [[VLCBugreporter sharedInstance] handleBugreportRequest];
}

@end
