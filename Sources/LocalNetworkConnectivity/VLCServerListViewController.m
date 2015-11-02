/*****************************************************************************
 * VLCLocalServerListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCServerListViewController.h"
#import "VLCLocalServerDiscoveryController.h"

#import "VLCPlaybackController.h"
#import "VLCNetworkListCell.h"
#import "VLCNetworkLoginViewController.h"
#import "VLCNetworkServerBrowserViewController.h"

#import "VLCNetworkServerLoginInformation.h"

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

@interface VLCServerListViewController () <UITableViewDataSource, UITableViewDelegate, VLCLocalServerDiscoveryControllerDelegate>
{
    VLCLocalServerDiscoveryController *_discoveryController;

    UIBarButtonItem *_backToMenuButton;

    UIRefreshControl *_refreshControl;
    UIActivityIndicatorView *_activityIndicator;
}

@end

@implementation VLCServerListViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor VLCDarkBackgroundColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.view = _tableView;
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.center = _tableView.center;
    _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:_activityIndicator];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

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
                                ];

    _discoveryController = [[VLCLocalServerDiscoveryController alloc] initWithServiceBrowserClasses:browserClasses];
    _discoveryController.delegate = self;

    _backToMenuButton = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = _backToMenuButton;

    self.tableView.rowHeight = [VLCNetworkListCell heightOfCell];
    self.tableView.separatorColor = [UIColor VLCDarkBackgroundColor];
    self.view.backgroundColor = [UIColor VLCDarkBackgroundColor];

    self.title = NSLocalizedString(@"LOCAL_NETWORK", nil);

    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.backgroundColor = [UIColor VLCDarkBackgroundColor];
    _refreshControl.tintColor = [UIColor whiteColor];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];
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

- (IBAction)goBack:(id)sender
{
    [_discoveryController stopDiscovery];
    [[VLCSidebarController sharedInstance] toggleSidebar];
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
    UIColor *color = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor VLCDarkBackgroundColor];
    cell.contentView.backgroundColor = cell.titleLabel.backgroundColor = cell.folderTitleLabel.backgroundColor = cell.subtitleLabel.backgroundColor = color;
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
            VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
            [vpc playURL:playbackURL successCallback:nil errorCallback:nil];
            return;
        }
    }

    VLCNetworkServerLoginInformation *login;
    if ([service respondsToSelector:@selector(loginInformation)]) {
        login = [service loginInformation];
    }

    VLCNetworkLoginViewController *loginViewController = [[VLCNetworkLoginViewController alloc] initWithNibName:@"VLCNetworkLoginViewController" bundle:nil];

    VLCServerProtocol protocol = VLCServerProtocolUndefined;
    NSString *protocolIdentifier = login.protocolIdentifier;
    if ([protocolIdentifier isEqualToString:VLCNetworkServerProtocolIdentifierFTP]) {
        protocol = VLCServerProtocolFTP;
    } else if ([protocolIdentifier isEqualToString:VLCNetworkServerProtocolIdentifierPlex]) {
        protocol = VLCServerProtocolPLEX;
    } else if ([protocolIdentifier isEqualToString:VLCNetworkServerProtocolIdentifierSMB]) {
        protocol = VLCServerProtocolSMB;
    }

    loginViewController.serverProtocol = protocol;
    loginViewController.hostname = login.address;
    loginViewController.username = login.username;
    loginViewController.password = login.password;
    loginViewController.port = login.port.stringValue;
    loginViewController.delegate = self;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UINavigationController *navCon = [[VLCNavigationController alloc] initWithRootViewController:loginViewController];
        navCon.navigationBarHidden = NO;
        navCon.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navCon animated:YES completion:nil];

        if (loginViewController.navigationItem.leftBarButtonItem == nil)
            loginViewController.navigationItem.leftBarButtonItem = [UIBarButtonItem themedDarkToolbarButtonWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) target:loginViewController andSelector:@selector(_dismiss)];
    } else {
        [self.navigationController pushViewController:loginViewController animated:YES];
    }
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
        [self.tableView reloadData];

    [_refreshControl endRefreshing];
}

#pragma mark - login panel protocol

- (void)loginToServer:(NSString *)server
                 port:(NSString *)port
             protocol:(VLCServerProtocol)protocol
confirmedWithUsername:(NSString *)username
          andPassword:(NSString *)password
{

    id<VLCNetworkServerBrowser> serverBrowser = nil;
    switch (protocol) {
        case VLCServerProtocolFTP:
        {
            serverBrowser = [[VLCNetworkServerBrowserFTP alloc]initWithFTPServer:server
                                                                        userName:username
                                                                     andPassword:password atPath:@"/"];
            break;
        }
        case VLCServerProtocolPLEX:
        {

            NSNumber *portNumber;
            NSUInteger portInteger = 0;
            if (port.length) {
                portInteger = [port integerValue];
            }
            portNumber = portInteger != 0 ? @(portInteger) : @(32400);

            serverBrowser = [[VLCNetworkServerBrowserPlex alloc] initWithName:server
                                                                         host:server
                                                                   portNumber:@([port integerValue])
                                                                         path:@""
                                                           authentificication:@""];
            break;
        }
        case VLCServerProtocolSMB:
        {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"smb://%@", server]];
            serverBrowser = [VLCNetworkServerBrowserVLCMedia SMBNetworkServerBrowserWithURL:url
                                                                                   username:username
                                                                                   password:password
                                                                                  workgroup:nil];
        }

        default:
            APLog(@"Unsupported URL Scheme requested %ld", (long)protocol);
            break;
    }
    if (serverBrowser) {
        VLCNetworkServerBrowserViewController *targetViewController = [[VLCNetworkServerBrowserViewController alloc] initWithServerBrowser:serverBrowser];
        [self.navigationController pushViewController:targetViewController animated:YES];
    }
}

- (void)discoveryFoundSomethingNew
{
    [self.tableView reloadData];
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *headerText = [_discoveryController titleForSection:section];
    UIView *headerView = nil;
    headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, 21.0f)];
    headerView.backgroundColor = [UIColor VLCDarkBackgroundColor];

    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectInset(headerView.bounds, 12.0f, 0.f)];
    textLabel.text = (NSString *) headerText;
    textLabel.font = [UIFont boldSystemFontOfSize:([UIFont systemFontSize] * 0.8f)];
    textLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    textLabel.shadowColor = [UIColor VLCDarkTextShadowColor];
    textLabel.textColor = [UIColor colorWithRed:(118.0f/255.0f) green:(118.0f/255.0f) blue:(118.0f/255.0f) alpha:1.0f];
    textLabel.backgroundColor = [UIColor clearColor];
    [headerView addSubview:textLabel];

    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
    topLine.backgroundColor = [UIColor colorWithRed:(95.0f/255.0f) green:(95.0f/255.0f) blue:(95.0f/255.0f) alpha:1.0f];
    topLine.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [headerView addSubview:topLine];

    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 21.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
    bottomLine.backgroundColor = [UIColor colorWithRed:(16.0f/255.0f) green:(16.0f/255.0f) blue:(16.0f/255.0f) alpha:1.0f];
    bottomLine.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [headerView addSubview:bottomLine];
    return headerView;
}

@end
