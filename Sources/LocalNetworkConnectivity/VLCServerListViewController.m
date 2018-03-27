/*****************************************************************************
 * VLCLocalServerListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Vincent L. Cone <vincent.l.cone # tuta.io>
 *          Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCServerListViewController.h"
#import "VLCLocalServerDiscoveryController.h"

#import "VLCPlaybackController.h"
#import "VLCNetworkListCell.h"
#import "VLCNetworkLoginViewController.h"
#import "VLCNetworkServerBrowserViewController.h"

#import "VLCNetworkServerLoginInformation+Keychain.h"

#import "VLCNetworkServerBrowserFTP.h"
#import "VLCNetworkServerBrowserVLCMedia.h"
#import "VLCNetworkServerBrowserPlex.h"

#import "VLCLocalNetworkServiceBrowserManualConnect.h"
#import "VLCLocalNetworkServiceBrowserPlex.h"
#import "VLCLocalNetworkServiceBrowserFTP.h"
#import "VLCLocalNetworkServiceBrowserUPnP.h"
#import "VLCLocalNetworkServiceBrowserHTTP.h"
#import "VLCLocalNetworkServiceBrowserSAP.h"
#import "VLCLocalNetworkServiceBrowserDSM.h"
#import "VLCLocalNetworkServiceBrowserBonjour.h"

#import "VLCWiFiUploadTableViewCell.h"

#import "VLC_iOS-Swift.h"

@interface VLCServerListViewController () <UITableViewDataSource, UITableViewDelegate, VLCLocalServerDiscoveryControllerDelegate, VLCNetworkLoginViewControllerDelegate>
{
    VLCLocalServerDiscoveryController *_discoveryController;

    UIRefreshControl *_refreshControl;
    UIActivityIndicatorView *_activityIndicator;
    UITableView *_localNetworkTableView;
    UITableView *_remoteNetworkTableView;
    VLCRemoteNetworkDataSource *_remoteNetworkDatasource;
}

@end

@implementation VLCServerListViewController

- (void)loadView
{
    [super loadView];

    _remoteNetworkDatasource = [VLCRemoteNetworkDataSource new];

    _localNetworkTableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _localNetworkTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _localNetworkTableView.backgroundColor = PresentationTheme.current.colors.background;
    _localNetworkTableView.delegate = self;
    _localNetworkTableView.dataSource = self;
    _localNetworkTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _localNetworkTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _localNetworkTableView.bounces = NO;
    _localNetworkTableView.rowHeight = [VLCNetworkListCell heightOfCell];
    _localNetworkTableView.separatorColor = PresentationTheme.current.colors.background;

    //TODO: this is very much work in progress we need to accomodate the wificell for now
    //When we know how many cells go above the the local servers we should create and move this into a headerview of the localNetworkTable
    _remoteNetworkTableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _remoteNetworkTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _remoteNetworkTableView.backgroundColor = PresentationTheme.current.colors.background;
    _remoteNetworkTableView.delegate = self;
    _remoteNetworkTableView.dataSource = _remoteNetworkDatasource;
    _remoteNetworkTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _remoteNetworkTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _remoteNetworkTableView.bounces = NO;
    [_remoteNetworkTableView registerClass:[VLCWiFiUploadTableViewCell class] forCellReuseIdentifier:[VLCWiFiUploadTableViewCell cellIdentifier]];

    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.backgroundColor = PresentationTheme.current.colors.background;
    _refreshControl.tintColor = [UIColor whiteColor];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [_localNetworkTableView addSubview:_refreshControl];

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.center = _localNetworkTableView.center;
    _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _activityIndicator.hidesWhenStopped = YES;
    [_localNetworkTableView addSubview:_activityIndicator];

    [self.view addSubview:_localNetworkTableView];
    [self.view addSubview:_remoteNetworkTableView];
    [NSLayoutConstraint activateConstraints:@[
                                              [_remoteNetworkTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
                                              [_remoteNetworkTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
                                              [_remoteNetworkTableView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor],
                                              [_remoteNetworkTableView.heightAnchor constraintEqualToConstant:50],
                                              [_localNetworkTableView.topAnchor constraintEqualToAnchor:_remoteNetworkTableView.bottomAnchor],
                                              [_localNetworkTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
                                              [_localNetworkTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
                                              [_localNetworkTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
                                              ]];
    self.view.backgroundColor = PresentationTheme.current.colors.background;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange) name:kVLCThemeDidChangeNotification object:nil];

    NSArray *browserClasses = @[
                                [VLCLocalNetworkServiceBrowserManualConnect class],
                                [VLCLocalNetworkServiceBrowserUPnP class],
                                [VLCLocalNetworkServiceBrowserPlex class],
                                [VLCLocalNetworkServiceBrowserFTP class],
                                [VLCLocalNetworkServiceBrowserHTTP class],
#ifndef NDEBUG
                                [VLCLocalNetworkServiceBrowserSAP class],
#endif
                                [VLCLocalNetworkServiceBrowserDSM class],
                                [VLCLocalNetworkServiceBrowserBonjour class],
                                ];

    _discoveryController = [[VLCLocalServerDiscoveryController alloc] initWithServiceBrowserClasses:browserClasses];
    _discoveryController.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_activityIndicator stopAnimating];

    [_discoveryController stopDiscovery];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_discoveryController startDiscovery];
}

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

#pragma mark - table view handling

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _discoveryController.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_discoveryController numberOfItemsInSection:section];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _remoteNetworkTableView) return;
    UIColor *color = (indexPath.row % 2 == 0)? PresentationTheme.current.colors.cellBackgroundB : PresentationTheme.current.colors.cellBackgroundA;
    cell.backgroundColor = cell.titleLabel.backgroundColor = cell.folderTitleLabel.backgroundColor = cell.subtitleLabel.backgroundColor = color;
    cell.titleLabel.textColor = cell.folderTitleLabel.textColor = cell.subtitleLabel.textColor = cell.thumbnailView.tintColor = PresentationTheme.current.colors.cellTextColor;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.textColor = PresentationTheme.current.colors.sectionHeaderTextColor;
    header.textLabel.font = [UIFont boldSystemFontOfSize:([UIFont systemFontSize] * 0.8f)];

    header.tintColor = PresentationTheme.current.colors.sectionHeaderTintColor;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalNetworkCell";

    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:CellIdentifier];

    id<VLCLocalNetworkService> service = [_discoveryController networkServiceForIndexPath:indexPath];

    [cell setIsDirectory:YES];
    [cell setIcon:service.icon];
    [cell setTitle:service.title];

    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView == _remoteNetworkTableView ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    id<VLCLocalNetworkService> service = [_discoveryController networkServiceForIndexPath:indexPath];

    if ([service respondsToSelector:@selector(serverBrowser)]) {
        id<VLCNetworkServerBrowser> serverBrowser = [service serverBrowser];
        if (serverBrowser) {
            VLCNetworkServerBrowserViewController *vc = [[VLCNetworkServerBrowserViewController alloc] initWithServerBrowser:serverBrowser];
            [self.navigationController pushViewController:vc animated:YES];
            return;
        }
    }

    if ([service respondsToSelector:@selector(directPlaybackURL)]) {
        NSURL *playbackURL = [service directPlaybackURL];
        if (playbackURL) {

            VLCMediaList *medialist = [[VLCMediaList alloc] init];
            [medialist addMedia:[VLCMedia mediaWithURL:playbackURL]];
            [[VLCPlaybackController sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
            return;
        }
    }

    VLCNetworkServerLoginInformation *login;
    if ([service respondsToSelector:@selector(loginInformation)]) {
        login = [service loginInformation];
    }

    [login loadLoginInformationFromKeychainWithError:nil];

    VLCNetworkLoginViewController *loginViewController = [[VLCNetworkLoginViewController alloc] initWithNibName:@"VLCNetworkLoginViewController" bundle:nil];

    loginViewController.loginInformation = login;
    loginViewController.delegate = self;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:loginViewController];
        navCon.navigationBarHidden = NO;
        navCon.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navCon animated:YES completion:nil];

        if (loginViewController.navigationItem.leftBarButtonItem == nil)
            loginViewController.navigationItem.leftBarButtonItem = [UIBarButtonItem themedDarkToolbarButtonWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) target:self andSelector:@selector(_dismissLogin)];
    } else {
        [self.navigationController pushViewController:loginViewController animated:YES];
    }
}
#pragma mark -
- (void)themeDidChange
{
    _localNetworkTableView.backgroundColor = PresentationTheme.current.colors.background;
    _localNetworkTableView.separatorColor = PresentationTheme.current.colors.background;
    _refreshControl.backgroundColor = PresentationTheme.current.colors.background;
}

- (void)_dismissLogin
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Refresh

-(void)handleRefresh
{
    //set the title while refreshing
    _refreshControl.attributedTitle = [[NSAttributedString alloc]initWithString:NSLocalizedString(@"LOCAL_SERVER_REFRESH",nil)];
    //set the date and time of refreshing
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc]init];
    [formattedDate setDateFormat:@"MMM d, h:mm a"];
    NSString *lastupdated = [NSString stringWithFormat:NSLocalizedString(@"LOCAL_SERVER_LAST_UPDATE",nil),[formattedDate stringFromDate:[NSDate date]]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastupdated attributes:attrsDictionary];
    //end the refreshing

    if ([_discoveryController refreshDiscoveredData])
        [_localNetworkTableView reloadData];

    [_refreshControl endRefreshing];
}

#pragma mark - VLCNetworkLoginViewControllerDelegate

- (void)loginWithLoginViewController:(VLCNetworkLoginViewController *)loginViewController loginInfo:(VLCNetworkServerLoginInformation *)loginInformation
{
    id<VLCNetworkServerBrowser> serverBrowser = nil;
    NSString *identifier = loginInformation.protocolIdentifier;

    if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierFTP]) {
        serverBrowser = [[VLCNetworkServerBrowserFTP alloc] initWithLogin:loginInformation];
    } else if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierPlex]) {
        serverBrowser = [[VLCNetworkServerBrowserPlex alloc] initWithLogin:loginInformation];
    } else if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierSMB]) {
        serverBrowser = [VLCNetworkServerBrowserVLCMedia SMBNetworkServerBrowserWithLogin:loginInformation];
    } else {
        APLog(@"Unsupported URL Scheme requested %@", identifier);
    }

    [self _dismissLogin];

    if (serverBrowser) {
        VLCNetworkServerBrowserViewController *targetViewController = [[VLCNetworkServerBrowserViewController alloc] initWithServerBrowser:serverBrowser];
        [self.navigationController pushViewController:targetViewController animated:YES];
    }
}

- (void)discoveryFoundSomethingNew
{
    [_localNetworkTableView reloadData];
}

#pragma mark - custom table view appearance

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // always hide the header of the first section
    if (section == 0)
        return 0.;

    if ([_discoveryController numberOfItemsInSection:section] == 0)
        return 0.;

    return 21.f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_discoveryController titleForSection:section];
}

@end
