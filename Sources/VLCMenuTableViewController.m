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
#import "VLCDownloadViewController.h"
#import "VLCServerListViewController.h"
#import "VLCOpenNetworkStreamViewController.h"
#import "VLCSettingsController.h"
#import "VLCAboutViewController.h"
#import "VLCBugreporter.h"
#import "VLCCloudServicesTableViewController.h"
#import "VLC_iOS-Swift.h"

#define ROW_HEIGHT 50.
#define IPAD_ROW_HEIGHT 65.
#define HEADER_HEIGHT 22.
#define MENU_WIDTH 320.
#define TOP_PADDING 20.
#define STANDARD_PADDING 8.
#define MAX_LEFT_INSET 170.
#define COMPACT_INSET 20.

static NSString *CellIdentifier = @"VLCMenuCell";
static NSString *WiFiCellIdentifier = @"VLCMenuWiFiCell";

@interface VLCMenuTableViewController () <UITableViewDataSource, UITableViewDelegate, VLCMediaViewControllerDelegate>
{
    NSArray *_sectionHeaderTexts;
    NSArray *_menuItemsSectionOne;
    NSArray *_menuItemsSectionTwo;
    NSArray *_menuItemsSectionThree;

    UITableView *_menuTableView;
    NSLayoutConstraint *_heightConstraint;
    NSLayoutConstraint *_leftTableConstraint;
    VLCSettingsController *_settingsController;
    VLCMediaViewController *_videoViewController;
}

@end

@implementation VLCMenuTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _sectionHeaderTexts = @[@"SECTION_HEADER_LIBRARY", @"SECTION_HEADER_NETWORK", @"Settings"];
    _menuItemsSectionOne = @[@"LIBRARY_ALL_FILES", @"LIBRARY_MUSIC", @"LIBRARY_SERIES"];
    _menuItemsSectionTwo = @[@"LOCAL_NETWORK", @"NETWORK_TITLE", @"DOWNLOAD_FROM_HTTP", @"WEBINTF_TITLE", @"CLOUD_SERVICES"];
    _menuItemsSectionThree = @[@"Settings", @"ABOUT_APP"];

    _menuTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _menuTableView.delegate = self;
    _menuTableView.dataSource = self;
    _menuTableView.backgroundColor = [UIColor VLCMenuBackgroundColor];
    _menuTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _menuTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _menuTableView.rowHeight = UITableViewAutomaticDimension;
    _menuTableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    _menuTableView.estimatedSectionHeaderHeight = HEADER_HEIGHT;
    _menuTableView.estimatedRowHeight = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? IPAD_ROW_HEIGHT : ROW_HEIGHT;
    _menuTableView.scrollsToTop = NO;
    _menuTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _menuTableView.showsHorizontalScrollIndicator = NO;
    _menuTableView.showsVerticalScrollIndicator = NO;
    [_menuTableView registerClass:[VLCWiFiUploadTableViewCell class] forCellReuseIdentifier:WiFiCellIdentifier];
    [_menuTableView registerClass:[VLCSidebarViewCell class] forCellReuseIdentifier:CellIdentifier];

    [self.view addSubview:_menuTableView];

    NSDictionary *dict;

    dict = NSDictionaryOfVariableBindings(_menuTableView);
    NSDictionary *metrics = @{@"TopPadding": @(TOP_PADDING),
                              @"Standard": @(STANDARD_PADDING),
                              @"menuWidth" : @(MENU_WIDTH)
                              };
    // 20 to avoid seeing the tableview above the first sectionheader
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=TopPadding-[_menuTableView]->=Standard-|" options:0 metrics:metrics views:dict]];
    _heightConstraint = [NSLayoutConstraint constraintWithItem:_menuTableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:0];
    _heightConstraint.priority = UILayoutPriorityRequired -1;
    [self.view addConstraint:_heightConstraint];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_menuTableView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];

    _leftTableConstraint = [NSLayoutConstraint constraintWithItem:_menuTableView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0];
    [self.view addConstraint:_leftTableConstraint];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|->=0-[_menuTableView(==menuWidth)]" options:0 metrics:metrics views:dict]];

    [self selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
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

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _heightConstraint.constant = MIN(_menuTableView.contentSize.height, self.view.frame.size.height-TOP_PADDING-STANDARD_PADDING);
    _leftTableConstraint.constant = MAX((self.view.frame.size.width*2 /3.0  - _menuTableView.frame.size.width)/2.0, STANDARD_PADDING);
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
        else if ([rawTitle isEqualToString:@"NETWORK_TITLE"])
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *headerText = NSLocalizedString(_sectionHeaderTexts[section], nil);
    UIView *headerView = nil;
    if (headerText) {
        headerView = [[UIView alloc] initWithFrame:CGRectZero];
        headerView.backgroundColor = [UIColor VLCMenuBackgroundColor];

        UILabel *textLabel = [UILabel new];
        textLabel.text = headerText;
        textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:[UIFont systemFontSize]];
        textLabel.textColor = [UIColor whiteColor];
        textLabel.backgroundColor = [UIColor VLCMenuBackgroundColor];
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
        [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=0-[textLabel(==22)]->=0-[bottomLine(0.5)]|" options:0 metrics:0 views:dict]];
    }
    return headerView;
}

#pragma mark - menu implementation
- (VLCSettingsController *)settingsController
{
    if (!_settingsController){
        _settingsController = [[VLCSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
    }
    return _settingsController;
}

- (VLCMediaViewController *)videoViewController
{
    if (!_videoViewController) {
        _videoViewController = [[VLCMediaViewController alloc] initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
    }
    return _videoViewController;
}

- (void)_revealItem:(NSUInteger)itemIndex inSection:(NSUInteger)sectionNumber
{
    UIViewController *viewController;
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
            viewController = self.settingsController;
        } else if (itemIndex == 1)
            viewController = [[VLCAboutViewController alloc] init];
    } else {
        viewController = self.videoViewController;
    }

    if (!viewController) {
        APLog(@"no view controller found for menu item");
        return;
    }

    VLCSidebarController *sidebarController = [VLCSidebarController sharedInstance];
    if ([sidebarController.contentViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navCon = (UINavigationController*)sidebarController.contentViewController;
        navCon.viewControllers = @[viewController];
    } else
        sidebarController.contentViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [sidebarController hideSidebar];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
#pragma mark - VLCMediaViewControllerDelegate

- (void)videoViewControllerDidSelectMediaObjectWithVLCMediaViewController:(VLCMediaViewController *)VLCMediaViewController mediaObject:(NSManagedObject *)mediaObject
{
    
}

- (void)videoViewControllerDidSelectBackbuttonWithVLCMediaViewController:(VLCMediaViewController *)VLCMediaViewController {
    [[VLCSidebarController sharedInstance] toggleSidebar];
}
@end
