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
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCServerListViewController.h"
#import "VLCLocalServerDiscoveryController.h"

#import "VLCPlaybackController.h"
#import "VLCNetworkListCell.h"
#import "VLCNetworkLoginViewController.h"
#import "VLCUPnPServerListViewController.h"
#import "VLCLocalPlexFolderListViewController.h"
#import "VLCSharedLibraryListViewController.h"
#import "VLCDiscoveryListViewController.h"
#import "VLCFTPServerListViewController.h"

@interface VLCServerListViewController () <UITableViewDataSource, UITableViewDelegate, VLCLocalServerDiscoveryControllerDelegate>
{
    VLCLocalServerDiscoveryController *_discoveryController;

    UIBarButtonItem *_backToMenuButton;
    NSArray *_sectionHeaderTexts;

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

    _discoveryController = [[VLCLocalServerDiscoveryController alloc] init];
    _discoveryController.delegate = self;

    _sectionHeaderTexts = _discoveryController.sectionHeaderTexts;

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
    return _sectionHeaderTexts.count;
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


    [cell setIsDirectory:YES];
    [cell setIcon:[_discoveryController iconForIndexPath:indexPath]];
    [cell setTitle:[_discoveryController titleForIndexPath:indexPath]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSUInteger section = indexPath.section;

    switch (section) {
        case 0:
        {
            VLCNetworkLoginViewController *loginViewController = [[VLCNetworkLoginViewController alloc] initWithNibName:@"VLCNetworkLoginViewController" bundle:nil];
            loginViewController.delegate = self;
            loginViewController.serverProtocol = VLCServerProtocolUndefined;

            UINavigationController *navCon = [[VLCNavigationController alloc] initWithRootViewController:loginViewController];
            navCon.navigationBarHidden = NO;

            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                navCon.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:navCon animated:YES completion:nil];

                if (loginViewController.navigationItem.leftBarButtonItem == nil)
                    loginViewController.navigationItem.leftBarButtonItem = [UIBarButtonItem themedDarkToolbarButtonWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) target:loginViewController andSelector:@selector(_dismiss)];
            } else
                [self.navigationController pushViewController:loginViewController animated:YES];
            break;
        }
        case 1:
        {
            [_activityIndicator startAnimating];
            BasicUPnPDevice *device = [_discoveryController upnpDeviceForIndexPath:indexPath];
            if (device != nil) {
                if ([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"]) {
                    MediaServer1Device *server = (MediaServer1Device*)device;
                    VLCUPnPServerListViewController *targetViewController = [[VLCUPnPServerListViewController alloc] initWithUPNPDevice:server header:[device friendlyName] andRootID:@"0"];
                    [self.navigationController pushViewController:targetViewController animated:YES];
                }
            }
            break;
        }

        case 2:
        {
            NSDictionary *serviceDescription = [_discoveryController plexServiceDescriptionForIndexPath:indexPath];
            if (serviceDescription != nil) {
                NSString *name = serviceDescription[@"name"];
                NSString *hostName = serviceDescription[@"hostName"];
                NSString *portNum = serviceDescription[@"port"];
                VLCLocalPlexFolderListViewController *targetViewController = [[VLCLocalPlexFolderListViewController alloc] initWithPlexServer:name serverAddress:hostName portNumber:portNum atPath:@"" authentification:@""];
                [[self navigationController] pushViewController:targetViewController animated:YES];
            }
            break;
        }

        case 3:
        {
            VLCNetworkLoginViewController *loginViewController = [[VLCNetworkLoginViewController alloc] initWithNibName:@"VLCNetworkLoginViewController" bundle:nil];
            loginViewController.delegate = self;
            loginViewController.serverProtocol = VLCServerProtocolFTP;

            UINavigationController *navCon = [[VLCNavigationController alloc] initWithRootViewController:loginViewController];
            navCon.navigationBarHidden = NO;

            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                navCon.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:navCon animated:YES completion:nil];

                if (loginViewController.navigationItem.leftBarButtonItem == nil)
                    loginViewController.navigationItem.leftBarButtonItem = [UIBarButtonItem themedDarkToolbarButtonWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) target:loginViewController andSelector:@selector(_dismiss)];
            } else
                [self.navigationController pushViewController:loginViewController animated:YES];
            loginViewController.hostname = [_discoveryController ftpHostnameForIndexPath:indexPath];
            break;
        }

        case 4:
        {
            NSDictionary *serviceDescription = [_discoveryController httpServiceDescriptionForIndexPath:indexPath];
            if (serviceDescription != nil) {
                NSString *name = serviceDescription[@"name"];
                NSString *hostName = serviceDescription[@"hostName"];
                NSString *portNum = serviceDescription[@"port"];
                VLCSharedLibraryListViewController *targetViewController = [[VLCSharedLibraryListViewController alloc]
                                                                            initWithHttpServer:name
                                                                            serverAddress:hostName
                                                                            portNumber:portNum];
                [[self navigationController] pushViewController:targetViewController animated:YES];
            }
            break;
        }

        case 5:
        {
            VLCMedia *cellMedia = [_discoveryController dsmDiscoveryForIndexPath:indexPath];
            if (cellMedia.mediaType != VLCMediaTypeDirectory)
                return;

            NSDictionary *mediaOptions = @{@"smb-user" : @"",
                                           @"smb-pwd" : @"",
                                           @"smb-domain" : @""};
            [cellMedia addOptions:mediaOptions];

            VLCDiscoveryListViewController *targetViewController = [[VLCDiscoveryListViewController alloc]
                                                                    initWithMedia:cellMedia
                                                                    options:mediaOptions];
            [[self navigationController] pushViewController:targetViewController animated:YES];
            break;
        }

        case 6:
        {
            VLCMedia *cellMedia = [_discoveryController sapDiscoveryForIndexPath:indexPath];
            VLCMediaType mediaType = cellMedia.mediaType;
            if (mediaType != VLCMediaTypeDirectory && mediaType != VLCMediaTypeDisc) {
                VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
                [vpc playURL:[cellMedia url] successCallback:nil errorCallback:nil];
            }
            break;
        }

        default:
            break;
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
    switch (protocol) {
        case VLCServerProtocolFTP:
        {
            VLCFTPServerListViewController *targetViewController = [[VLCFTPServerListViewController alloc]
                                                                    initWithFTPServer:server
                                                                    userName:username
                                                                    andPassword:password atPath:@"/"];
            [self.navigationController pushViewController:targetViewController animated:YES];
            break;
        }
        case VLCServerProtocolPLEX:
        {
            if (port == nil || port.length == 0)
                port = @"32400";
            VLCLocalPlexFolderListViewController *targetViewController = [[VLCLocalPlexFolderListViewController alloc]
                                                                          initWithPlexServer:server
                                                                          serverAddress:server
                                                                          portNumber:[NSString stringWithFormat:@":%@", port] atPath:@""
                                                                          authentification:username];
            [[self navigationController] pushViewController:targetViewController animated:YES];
            break;
        }
        case VLCServerProtocolSMB:
        {
            VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"smb://%@", server]]];
            NSDictionary *mediaOptions = @{@"smb-user" : username ? username : @"",
                                           @"smb-pwd" : password ? password : @"",
                                           @"smb-domain" : @"WORKGROUP"};
            [media addOptions:mediaOptions];

            VLCDiscoveryListViewController *targetViewController = [[VLCDiscoveryListViewController alloc]
                                                                    initWithMedia:media
                                                                    options:mediaOptions];
            [[self navigationController] pushViewController:targetViewController animated:YES];
        }

        default:
            APLog(@"Unsupported URL Scheme requested %ld", (long)protocol);
            break;
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
    NSObject *headerText = NSLocalizedString(_sectionHeaderTexts[section], nil);
    UIView *headerView = nil;
    if (headerText != [NSNull null]) {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, 21.0f)];
        headerView.backgroundColor = [UIColor VLCDarkBackgroundColor];

        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectInset(headerView.bounds, 12.0f, 0.f)];
        textLabel.text = (NSString *) headerText;
        textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:([UIFont systemFontSize] * 0.8f)];
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
    }
    return headerView;
}

@end
