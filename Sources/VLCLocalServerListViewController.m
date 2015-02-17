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

#import "VLCLocalServerListViewController.h"
#import "UIBarButtonItem+Theme.h"
#import "VLCAppDelegate.h"
#import "UPnPManager.h"
#import "VLCLocalNetworkListCell.h"
#import "VLCLocalServerFolderListViewController.h"
#import "VLCLocalPlexFolderListViewController.h"
#import "VLCSharedLibraryListViewController.h"
#import "VLCSharedLibraryParser.h"
#import <QuartzCore/QuartzCore.h>
#import "GHRevealViewController.h"
#import "VLCNetworkLoginViewController.h"
#import "UINavigationController+Theme.h"
#import "VLCPlaylistViewController.h"
#import "VLCHTTPUploaderController.h"
#import "Reachability.h"

#define kPlexServiceType @"_plexmediasvr._tcp."

@interface VLCLocalServerListViewController () <UITableViewDataSource, UITableViewDelegate, NSNetServiceBrowserDelegate, VLCNetworkLoginViewController, NSNetServiceDelegate, VLCMediaListDelegate, UPnPDBObserver>
{
    UIBarButtonItem *_backToMenuButton;
    NSArray *_sectionHeaderTexts;

    NSNetServiceBrowser *_ftpNetServiceBrowser;
    NSNetServiceBrowser *_PlexNetServiceBrowser;
    NSNetServiceBrowser *_httpNetServiceBrowser;
    NSMutableArray *_PlexServices;
    NSMutableArray *_PlexServicesInfo;
    NSMutableArray *_httpServices;
    NSMutableArray *_httpServicesInfo;
    NSMutableArray *_rawNetServices;
    NSMutableArray *_ftpServices;

    NSArray *_filteredUPNPDevices;
    NSArray *_UPNPdevices;

    VLCMediaDiscoverer * _sapDiscoverer;

    VLCNetworkLoginViewController *_loginViewController;

    VLCSharedLibraryParser *_httpParser;

    UIRefreshControl *_refreshControl;
    UIActivityIndicatorView *_activityIndicator;
    Reachability *_reachability;

    NSString *_myHostName;

    BOOL _udnpDiscoveryRunning;
    NSTimer *_searchTimer;
}

@property (nonatomic) VLCHTTPUploaderController *uploadController;

@end

@implementation VLCLocalServerListViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:[UIApplication sharedApplication]];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:[UIApplication sharedApplication]];

    [_reachability stopNotifier];
    [_ftpNetServiceBrowser stop];
    [_PlexNetServiceBrowser stop];
    [_httpNetServiceBrowser stop];
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

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self _stopUPNPDiscovery];
    [self _stopSAPDiscovery];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (_reachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self performSelectorInBackground:@selector(_startUPNPDiscovery) withObject:nil];
        [self performSelectorInBackground:@selector(_startSAPDiscovery) withObject:nil];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:[UIApplication sharedApplication]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:[UIApplication sharedApplication]];

/*    if (SYSTEM_RUNS_IOS7_OR_LATER)
        _sectionHeaderTexts = @[@"Universal Plug'n'Play (UPNP)", @"File Transfer Protocol (FTP)", NSLocalizedString(@"SAP_STREAMS", nil)];
    else*/
    _sectionHeaderTexts = @[@"Universal Plug'n'Play (UPnP)", @"Plex Media Server (via Bonjour)", @"File Transfer Protocol (FTP)", NSLocalizedString(@"SHARED_VLC_IOS_LIBRARY", nil)];

    _backToMenuButton = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = _backToMenuButton;

    self.tableView.rowHeight = [VLCLocalNetworkListCell heightOfCell];
    self.tableView.separatorColor = [UIColor VLCDarkBackgroundColor];
    self.view.backgroundColor = [UIColor VLCDarkBackgroundColor];

    self.title = NSLocalizedString(@"LOCAL_NETWORK", nil);

    _ftpServices = [[NSMutableArray alloc] init];
    [_ftpServices addObject:NSLocalizedString(@"CONNECT_TO_SERVER", nil)];

    _rawNetServices = [[NSMutableArray alloc] init];

    _ftpNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
    _ftpNetServiceBrowser.delegate = self;

    _PlexServices = [[NSMutableArray alloc] init];
    _PlexServicesInfo = [[NSMutableArray alloc] init];
    _PlexNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
    _PlexNetServiceBrowser.delegate = self;

    _httpServices = [[NSMutableArray alloc] init];
    _httpServicesInfo = [[NSMutableArray alloc] init];
    _httpNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
    _httpNetServiceBrowser.delegate = self;

    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.backgroundColor = [UIColor VLCDarkBackgroundColor];
    _refreshControl.tintColor = [UIColor whiteColor];
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

    self.uploadController = [[VLCHTTPUploaderController alloc] init];
    _myHostName = [self.uploadController hostname];
    _httpParser = [[VLCSharedLibraryParser alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_activityIndicator stopAnimating];
    [_ftpNetServiceBrowser stop];
    [_PlexNetServiceBrowser stop];
    [_httpNetServiceBrowser stop];
}

- (void)viewWillAppear:(BOOL)animated
{
    [_ftpNetServiceBrowser searchForServicesOfType:@"_ftp._tcp." inDomain:@""];
    [_PlexNetServiceBrowser searchForServicesOfType:kPlexServiceType inDomain:@""];
    [_httpNetServiceBrowser searchForServicesOfType:@"_http._tcp." inDomain:@""];
    [_activityIndicator stopAnimating];
    [super viewWillAppear:animated];

    [self netReachabilityChanged:nil];
}

- (void)netReachabilityChanged:(NSNotification *)notification
{
    if (_reachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self performSelectorInBackground:@selector(_startUPNPDiscovery) withObject:nil];
        [self performSelectorInBackground:@selector(_startSAPDiscovery) withObject:nil];
    } else {
        [self _stopUPNPDiscovery];
        [self _stopSAPDiscovery];
    }
}

- (void)_startUPNPDiscovery
{
    if (_reachability.currentReachabilityStatus != ReachableViaWiFi)
        return;

    UPnPManager *managerInstance = [UPnPManager GetInstance];

    _UPNPdevices = [[managerInstance DB] rootDevices];

    if (_UPNPdevices.count > 0)
        [self UPnPDBUpdated:nil];

    [[managerInstance DB] addObserver:self];

    //Optional; set User Agent
    [[managerInstance SSDP] setUserAgentProduct:[NSString stringWithFormat:@"VLCforiOS/%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] andOS:[NSString stringWithFormat:@"iOS/%@", [[UIDevice currentDevice] systemVersion]]];

    //Search for UPnP Devices
    [[managerInstance SSDP] startSSDP];
    [[managerInstance SSDP] notifySSDPAlive];
    _searchTimer = [NSTimer timerWithTimeInterval:10.0 target:self selector:@selector(_performSSDPSearch) userInfo:nil repeats:YES];
    [_searchTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    [[NSRunLoop mainRunLoop] addTimer:_searchTimer forMode:NSRunLoopCommonModes];
    _udnpDiscoveryRunning = YES;
}

- (void)_performSSDPSearch
{
    UPnPManager *managerInstance = [UPnPManager GetInstance];
    [[managerInstance SSDP] searchSSDP];
    [[managerInstance SSDP] searchForMediaServer];
    [[managerInstance SSDP] SSDPDBUpdate];
}

- (void)_stopUPNPDiscovery
{
    if (_udnpDiscoveryRunning) {
        UPnPManager *managerInstance = [UPnPManager GetInstance];
        [[managerInstance SSDP] notifySSDPByeBye];
        [_searchTimer invalidate];
        _searchTimer = nil;
        [[managerInstance DB] removeObserver:self];
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
        return _PlexServices.count;
    else if (section == 2)
        return _ftpServices.count;
    else if (section == 3)
        return _httpServices.count;
    else if (section == 4)
        return _sapDiscoverer.discoveredMedia.count;

    return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCLocalNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *color = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor VLCDarkBackgroundColor];
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
        [cell setTitle:[_PlexServices[row] name]];
        [cell setIcon:[UIImage imageNamed:@"PlexServerIcon"]];
    } else if (section == 2) {
        if (row == 0)
            [cell setTitle:_ftpServices[row]];
        else {
            [cell setTitle:[_ftpServices[row] name]];
            [cell setIcon:[UIImage imageNamed:@"serverIcon"]];
        }
    } else if (section == 3) {
        [cell setTitle:[_httpServices[row] name]];
        [cell setIcon:[UIImage imageNamed:@"menuCone"]];
    } else if (section == 4)
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
        NSString *name = [_PlexServicesInfo[row] objectForKey:@"name"];
        NSString *hostName = [_PlexServicesInfo[row] objectForKey:@"hostName"];
        NSString *portNum = [_PlexServicesInfo[row] objectForKey:@"port"];
        VLCLocalPlexFolderListViewController *targetViewController = [[VLCLocalPlexFolderListViewController alloc] initWithPlexServer:name serverAddress:hostName portNumber:portNum atPath:@""];
        [[self navigationController] pushViewController:targetViewController animated:YES];
    } else if (section == 2) {
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
    } else if (section == 3) {
        NSString *name = [_httpServicesInfo[row] objectForKey:@"name"];
        NSString *hostName = [_httpServicesInfo[row] objectForKey:@"hostName"];
        NSString *portNum = [_httpServicesInfo[row] objectForKey:@"port"];
        VLCSharedLibraryListViewController *targetViewController = [[VLCSharedLibraryListViewController alloc] initWithHttpServer:name serverAddress:hostName portNumber:portNum];
        [[self navigationController] pushViewController:targetViewController animated:YES];
    } else if (section == 4) {
        VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate openMovieFromURL:[[_sapDiscoverer.discoveredMedia mediaAtIndex:row] url]];
    }
}

#pragma mark - Refresh

-(void)handleRefresh
{
    if (_reachability.currentReachabilityStatus != ReachableViaWiFi) {
        [_refreshControl endRefreshing];
        return;
    }
    UPnPManager *managerInstance = [UPnPManager GetInstance];
    [[managerInstance DB] removeObserver:self];
    [[managerInstance SSDP] stopSSDP];

    //set the title while refreshing
    _refreshControl.attributedTitle = [[NSAttributedString alloc]initWithString:NSLocalizedString(@"LOCAL_SERVER_REFRESH",nil)];
    //set the date and time of refreshing
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc]init];
    [formattedDate setDateFormat:@"MMM d, h:mm a"];
    NSString *lastupdated = [NSString stringWithFormat:NSLocalizedString(@"LOCAL_SERVER_LAST_UPDATE",nil),[formattedDate stringFromDate:[NSDate date]]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastupdated attributes:attrsDictionary];
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
    NSObject *headerText = NSLocalizedString(_sectionHeaderTexts[section], nil);
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
    if ([aNetService.type isEqualToString:kPlexServiceType]) {
        [_PlexServices removeObject:aNetService];
        [_PlexServicesInfo removeAllObjects];
    }
    if ([aNetService.type isEqualToString:@"_http._tcp."]) {
        [_httpServices removeObject:aNetService];
        [_httpServicesInfo removeAllObjects];
    }
    if (!moreComing)
        [self.tableView reloadData];
}

- (void)netServiceDidResolveAddress:(NSNetService *)aNetService
{
    if ([aNetService.type isEqualToString:@"_ftp._tcp."]) {
        if (![_ftpServices containsObject:aNetService])
            [_ftpServices addObject:aNetService];
    } else if ([aNetService.type isEqualToString:kPlexServiceType]) {
        if (![_PlexServices containsObject:aNetService]) {
            [_PlexServices addObject:aNetService];
            NSMutableDictionary *_dictService = [[NSMutableDictionary alloc] init];
            [_dictService setObject:[aNetService name] forKey:@"name"];
            [_dictService setObject:[aNetService hostName] forKey:@"hostName"];
            NSString *portStr = [[NSString alloc] initWithFormat:@":%ld", (long)[aNetService port]];
            [_dictService setObject:portStr forKey:@"port"];
            [_PlexServicesInfo addObject:_dictService];
        }
    }  else if ([aNetService.type isEqualToString:@"_http._tcp."]) {
        if ([[aNetService hostName] rangeOfString:_myHostName].location == NSNotFound) {
            if ([_httpParser isVLCMediaServer:[aNetService hostName] port:[NSString stringWithFormat:@":%ld", (long)[aNetService port]]]) {
                if (![_httpServices containsObject:aNetService]) {
                    [_httpServices addObject:aNetService];
                    NSMutableDictionary *_dictService = [[NSMutableDictionary alloc] init];
                    [_dictService setObject:[aNetService name] forKey:@"name"];
                    [_dictService setObject:[aNetService hostName] forKey:@"hostName"];
                    NSString *portStr = [[NSString alloc] initWithFormat:@":%ld", (long)[aNetService port]];
                    [_dictService setObject:portStr forKey:@"port"];
                    [_httpServicesInfo addObject:_dictService];
                }
            }
        }
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
