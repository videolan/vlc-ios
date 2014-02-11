/*****************************************************************************
 * VLCLocalServerListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalServerListViewController.h"
#import "UIBarButtonItem+Theme.h"
#import "VLCAppDelegate.h"
#import "UPnPManager.h"
#import "VLCLocalNetworkListCell.h"
#import "VLCLocalServerFolderListViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "GHRevealViewController.h"
#import "VLCNetworkLoginViewController.h"
#import "UINavigationController+Theme.h"
#import "VLCPlaylistViewController.h"
#import "Reachability.h"

@interface VLCLocalServerListViewController () <UITableViewDataSource, UITableViewDelegate, NSNetServiceBrowserDelegate, VLCNetworkLoginViewController, NSNetServiceDelegate, VLCMediaListDelegate>
{
    UIBarButtonItem *_backToMenuButton;
    NSArray *_sectionHeaderTexts;

    NSNetServiceBrowser *_ftpNetServiceBrowser;
    NSMutableArray *_rawNetServices;
    NSMutableArray *_ftpServices;

    NSArray *_filteredUPNPDevices;
    NSArray *_UPNPdevices;

    VLCMediaDiscoverer * _sapDiscoverer;

    VLCNetworkLoginViewController *_loginViewController;

    UIRefreshControl *_refreshControl;
    UIActivityIndicatorView *_activityIndicator;
    Reachability *_reachability;

    BOOL _udnpDiscoveryRunning;
}

@end

@implementation VLCLocalServerListViewController

- (void)dealloc
{
    [_reachability stopNotifier];
    [_ftpNetServiceBrowser stop];
}

- (void)loadView
{
    _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];
    _tableView.delegate = self;
    _tableView.dataSource = self;
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

/*    if (SYSTEM_RUNS_IOS7_OR_LATER)
        _sectionHeaderTexts = @[@"Universal Plug'n'Play (UPNP)", @"File Transfer Protocol (FTP)", @"Network Streams (SAP)"];
    else*/
        _sectionHeaderTexts = @[@"Universal Plug'n'Play (UPNP)", @"File Transfer Protocol (FTP)"];

    _backToMenuButton = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = _backToMenuButton;

    self.tableView.rowHeight = [VLCLocalNetworkListCell heightOfCell];
    self.tableView.separatorColor = [UIColor colorWithWhite:.122 alpha:1.];
    self.view.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];

    self.title = NSLocalizedString(@"LOCAL_NETWORK", @"");

    _ftpServices = [[NSMutableArray alloc] init];
    [_ftpServices addObject:NSLocalizedString(@"CONNECT_TO_SERVER", nil)];

    _rawNetServices = [[NSMutableArray alloc] init];

    _ftpNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
    _ftpNetServiceBrowser.delegate = self;

    [self _triggerNetServiceBrowser];

    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];

    if (SYSTEM_RUNS_IOS7_OR_LATER)
        _loginViewController = [[VLCNetworkLoginViewController alloc] initWithNibName:@"VLCFutureNetworkLoginViewController" bundle:nil];
    else
        _loginViewController = [[VLCNetworkLoginViewController alloc] initWithNibName:@"VLCNetworkLoginViewController" bundle:nil];

    _loginViewController.delegate = self;

    _reachability = [Reachability reachabilityForLocalWiFi];
    [_reachability startNotifier];

    [self netReachabilityChanged:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_activityIndicator stopAnimating];
    [_ftpNetServiceBrowser stop];
}

- (void)viewWillAppear:(BOOL)animated
{
    [_activityIndicator stopAnimating];
    [super viewWillAppear:animated];

    [self netReachabilityChanged:nil];
}

- (void)netReachabilityChanged:(NSNotification *)notification
{
    if (_reachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self _triggerNetServiceBrowser];
        [self performSelectorInBackground:@selector(_startUPNPDiscovery) withObject:nil];
        [self performSelectorInBackground:@selector(_startSAPDiscovery) withObject:nil];
    } else {
        [_ftpNetServiceBrowser stop];
        [self _stopUPNPDiscovery];
        [self _stopSAPDiscovery];
    }
}

- (void)_triggerNetServiceBrowser
{
    [_ftpNetServiceBrowser searchForServicesOfType:@"_ftp._tcp." inDomain:@""];
}

- (void)_startUPNPDiscovery
{
    if (_reachability.currentReachabilityStatus != ReachableViaWiFi)
        return;

    UPnPManager *managerInstance = [UPnPManager GetInstance];

    _UPNPdevices = [[managerInstance DB] rootDevices];

    if (_UPNPdevices.count > 0)
        [self UPnPDBUpdated:nil];

    [[managerInstance DB] addObserver:(UPnPDBObserver*)self];

    //Optional; set User Agent
    [[managerInstance SSDP] setUserAgentProduct:[NSString stringWithFormat:@"VLC for iOS/%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] andOS:@"iOS"];

    //Search for UPnP Devices
    [[managerInstance SSDP] startSSDP];
    [[managerInstance SSDP] searchSSDP];
    [[managerInstance SSDP] SSDPDBUpdate];
    _udnpDiscoveryRunning = YES;
}

- (void)_stopUPNPDiscovery
{
    if (_udnpDiscoveryRunning) {
        UPnPManager *managerInstance = [UPnPManager GetInstance];
        [[managerInstance DB] removeObserver:(UPnPDBObserver*)self];
        [[managerInstance SSDP] stopSSDP];
        _udnpDiscoveryRunning = NO;
    }
}

- (IBAction)goBack:(id)sender
{
    [self _stopUPNPDiscovery];
    [self _stopSAPDiscovery];

    [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController] toggleSidebar:![(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController].sidebarShowing duration:kGHRevealSidebarDefaultAnimationDuration];
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
    if (section == 0)
        return _filteredUPNPDevices.count;
    else if (section == 1)
        return _ftpServices.count;
    else if (section == 2)
        return _sapDiscoverer.discoveredMedia.count;

    return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCLocalNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *color = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor colorWithWhite:.122 alpha:1.];
    cell.contentView.backgroundColor = cell.titleLabel.backgroundColor = cell.folderTitleLabel.backgroundColor = cell.subtitleLabel.backgroundColor = color;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalNetworkCell";

    VLCLocalNetworkListCell *cell = (VLCLocalNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCLocalNetworkListCell cellWithReuseIdentifier:CellIdentifier];

    NSUInteger row = indexPath.row;
    NSUInteger section = indexPath.section;

    [cell setIsDirectory:YES];
    [cell setIcon:nil];

    if (section == 0) {
        UIImage *icon;
        if (_filteredUPNPDevices.count > row) {
            BasicUPnPDevice *device = _filteredUPNPDevices[row];
            [cell setTitle:[device friendlyName]];
            icon = [device smallIcon];
        }
        [cell setIcon:icon != nil ? icon : [UIImage imageNamed:@"serverIcon"]];
    } else if (section == 1) {
        if (row == 0)
            [cell setTitle:_ftpServices[row]];
        else {
            [cell setTitle:[_ftpServices[row] name]];
            [cell setIcon:[UIImage imageNamed:@"serverIcon"]];
        }
    } else if (section == 2)
        [cell setTitle:[[_sapDiscoverer.discoveredMedia mediaAtIndex:row] metadataForKey: VLCMetaInformationTitle]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSUInteger row = indexPath.row;
    NSUInteger section = indexPath.section;

    if (section == 0) {
        if (_filteredUPNPDevices.count < row || _filteredUPNPDevices.count == 0)
            return;

        [_activityIndicator startAnimating];
        BasicUPnPDevice *device = _filteredUPNPDevices[row];
        if ([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"]) {
            MediaServer1Device *server = (MediaServer1Device*)device;
            VLCLocalServerFolderListViewController *targetViewController = [[VLCLocalServerFolderListViewController alloc] initWithUPNPDevice:server header:[device friendlyName] andRootID:@"0"];
            [self.navigationController pushViewController:targetViewController animated:YES];
        }
    } else if (section == 1) {
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:_loginViewController];
        [navCon loadTheme];
        navCon.navigationBarHidden = NO;

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            navCon.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:navCon animated:YES completion:nil];

            if (_loginViewController.navigationItem.leftBarButtonItem == nil) {
                UIBarButtonItem *doneButton = [UIBarButtonItem themedDoneButtonWithTarget:_loginViewController andSelector:@selector(dismissWithAnimation:)];

                _loginViewController.navigationItem.leftBarButtonItem = doneButton;
            }
        } else
            [self.navigationController pushViewController:_loginViewController animated:YES];

        if (row != 0 && [_ftpServices[row] hostName].length > 0) // FTP Connect To Server Special Item and hostname is long enough
            _loginViewController.hostname = [_ftpServices[row] hostName];
        else
            _loginViewController.hostname = @"";
    } else if (section == 2) {
        VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate openMovieFromURL:[[_sapDiscoverer.discoveredMedia mediaAtIndex:row] url]];
    }
}

#pragma mark - Refresh

-(void)handleRefresh
{
    UPnPManager *managerInstance = [UPnPManager GetInstance];
    [[managerInstance DB] removeObserver:(UPnPDBObserver*)self];
    [[managerInstance SSDP] stopSSDP];

    //set the title while refreshing
    _refreshControl.attributedTitle = [[NSAttributedString alloc]initWithString:NSLocalizedString(@"LOCAL_SERVER_REFRESH",nil)];
    //set the date and time of refreshing
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc]init];
    [formattedDate setDateFormat:@"MMM d, h:mm a"];
    NSString *lastupdated = [NSString stringWithFormat:NSLocalizedString(@"LOCAL_SERVER_LAST_UPDATE",nil),[formattedDate stringFromDate:[NSDate date]]];
    _refreshControl.attributedTitle = [[NSAttributedString alloc]initWithString:lastupdated];
    //end the refreshing
    [_refreshControl endRefreshing];

    [self.tableView reloadData];

    [self performSelectorInBackground:@selector(_startUPNPDiscovery) withObject:nil];
    [self performSelectorInBackground:@selector(_startSAPDiscovery) withObject:nil];
}

#pragma mark - login panel protocol

- (void)loginToURL:(NSURL *)url confirmedWithUsername:(NSString *)username andPassword:(NSString *)password
{
    if ([url.scheme isEqualToString:@"ftp"]) {
        if (url.host.length > 0) {
            VLCLocalServerFolderListViewController *targetViewController = [[VLCLocalServerFolderListViewController alloc] initWithFTPServer:url.host userName:username andPassword:password atPath:@"/"];
            [self.navigationController pushViewController:targetViewController animated:YES];
        }
    } else
        APLog(@"Unsupported URL Scheme requested %@", url.scheme);
}

#pragma mark - custom table view appearance

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 21.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSObject *headerText = NSLocalizedString(_sectionHeaderTexts[section], @"");
    UIView *headerView = nil;
    if (headerText != [NSNull null]) {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, 21.0f)];
        if (!SYSTEM_RUNS_IOS7_OR_LATER) {
            CAGradientLayer *gradient = [CAGradientLayer layer];
            gradient.frame = headerView.bounds;
            gradient.colors = @[
                          (id)[UIColor colorWithRed:(66.0f/255.0f) green:(66.0f/255.0f) blue:(66.0f/255.0f) alpha:1.0f].CGColor,
                          (id)[UIColor colorWithRed:(56.0f/255.0f) green:(56.0f/255.0f) blue:(56.0f/255.0f) alpha:1.0f].CGColor,
                          ];
            [headerView.layer insertSublayer:gradient atIndex:0];
        } else
            headerView.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];

        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectInset(headerView.bounds, 12.0f, 5.0f)];
        textLabel.text = (NSString *) headerText;
        textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:([UIFont systemFontSize] * 0.8f)];
        textLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
        textLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.25f];
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

#pragma mark - bonjour discovery
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    APLog(@"found bonjour service: %@ (%@)", aNetService.name, aNetService.type);
    [_rawNetServices addObject:aNetService];
    aNetService.delegate = self;
    [aNetService resolveWithTimeout:5.];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    APLog(@"bonjour service disappeared: %@ (%i)", aNetService.name, moreComing);
    if ([_rawNetServices containsObject:aNetService])
        [_rawNetServices removeObject:aNetService];
    if ([aNetService.type isEqualToString:@"_ftp._tcp."])
        [_ftpServices removeObject:aNetService];
    if (!moreComing)
        [self.tableView reloadData];
}

- (void)netServiceDidResolveAddress:(NSNetService *)aNetService
{
    if ([aNetService.type isEqualToString:@"_ftp._tcp."]) {
        if (![_ftpServices containsObject:aNetService])
            [_ftpServices addObject:aNetService];
    }
    [_rawNetServices removeObject:aNetService];
    [self.tableView reloadData];
}

- (void)netService:(NSNetService *)aNetService didNotResolve:(NSDictionary *)errorDict
{
    APLog(@"failed to resolve: %@", aNetService.name);
    [_rawNetServices removeObject:aNetService];
}

#pragma mark - UPNP details
//protocol UPnPDBObserver
- (void)UPnPDBWillUpdate:(UPnPDB*)sender
{
}

- (void)UPnPDBUpdated:(UPnPDB*)sender
{
    NSUInteger count = _UPNPdevices.count;
    BasicUPnPDevice *device;
    NSMutableArray *mutArray = [[NSMutableArray alloc] init];
    for (NSUInteger x = 0; x < count; x++) {
        device = _UPNPdevices[x];
        if ([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"])
            [mutArray addObject:device];
        else
            APLog(@"found device '%@' with unsupported urn '%@'", [device friendlyName], [device urn]);
    }
    _filteredUPNPDevices = nil;
    _filteredUPNPDevices = [NSArray arrayWithArray:mutArray];

    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

#pragma mark SAP discovery

- (void)_startSAPDiscovery
{
    return;

    if (_reachability.currentReachabilityStatus != ReachableViaWiFi)
        return;

    _sapDiscoverer = [[VLCMediaDiscoverer alloc] initWithName:@"sap"];
    _sapDiscoverer.discoveredMedia.delegate = self;
}

- (void)_stopSAPDiscovery
{
    return;

    _sapDiscoverer = nil;
}

- (void)mediaList:(VLCMediaList *)aMediaList mediaAdded:(VLCMedia *)media atIndex:(NSInteger)index
{
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)mediaList:(VLCMediaList *)aMediaList mediaRemovedAtIndex:(NSInteger)index
{
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

@end
