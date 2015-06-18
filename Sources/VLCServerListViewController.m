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
#import "VLCAppDelegate.h"
#import "UPnPManager.h"
#import "VLCNetworkListCell.h"

#import "VLCLocalPlexFolderListViewController.h"

#import "VLCFTPServerListViewController.h"
#import "VLCUPnPServerListViewController.h"
#import "VLCDiscoveryListViewController.h"

#import "VLCSharedLibraryListViewController.h"
#import "VLCSharedLibraryParser.h"

#import "VLCNetworkLoginViewController.h"
#import "VLCHTTPUploaderController.h"

#import "Reachability.h"

#define kPlexServiceType @"_plexmediasvr._tcp."

@interface VLCServerListViewController () <UITableViewDataSource, UITableViewDelegate, NSNetServiceBrowserDelegate, VLCNetworkLoginViewControllerDelegate, NSNetServiceDelegate, VLCMediaListDelegate, UPnPDBObserver>
{
    UIBarButtonItem *_backToMenuButton;
    NSArray *_sectionHeaderTexts;

    NSNetServiceBrowser *_ftpNetServiceBrowser;
    NSNetServiceBrowser *_PlexNetServiceBrowser;
    NSNetServiceBrowser *_httpNetServiceBrowser;
    NSMutableArray *_plexServices;
    NSMutableArray *_PlexServicesInfo;
    NSMutableArray *_httpServices;
    NSMutableArray *_httpServicesInfo;
    NSMutableArray *_rawNetServices;
    NSMutableArray *_ftpServices;

    NSArray *_filteredUPNPDevices;
    NSArray *_UPNPdevices;

    VLCMediaDiscoverer *_sapDiscoverer;
    VLCMediaDiscoverer *_dsmDiscoverer;

    VLCSharedLibraryParser *_httpParser;

    UIRefreshControl *_refreshControl;
    UIActivityIndicatorView *_activityIndicator;
    Reachability *_reachability;

    NSString *_myHostName;

    BOOL _udnpDiscoveryRunning;
    NSTimer *_searchTimer;
    BOOL _setup;
}

@end

@implementation VLCServerListViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

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
    [self _stopDSMDiscovery];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (_reachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self _startUPNPDiscovery];
        [self _startSAPDiscovery];
        [self _startDSMDiscovery];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter addObserver:self
                      selector:@selector(applicationWillResignActive:)
                          name:UIApplicationWillResignActiveNotification
                        object:[UIApplication sharedApplication]];

    [defaultCenter addObserver:self
                      selector:@selector(applicationDidBecomeActive:)
                          name:UIApplicationDidBecomeActiveNotification
                        object:[UIApplication sharedApplication]];

    [defaultCenter addObserver:self
                      selector:@selector(sharedLibraryFound:)
                          name:VLCSharedLibraryParserDeterminedNetserviceAsVLCInstance
                        object:nil];

    _sectionHeaderTexts = @[@"Generic", @"Universal Plug'n'Play (UPnP)", @"Plex Media Server (via Bonjour)", @"File Transfer Protocol (FTP)", NSLocalizedString(@"SHARED_VLC_IOS_LIBRARY", nil), NSLocalizedString(@"SMB_CIFS_FILE_SERVERS", nil), @"SAP"];

    _backToMenuButton = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = _backToMenuButton;

    self.tableView.rowHeight = [VLCNetworkListCell heightOfCell];
    self.tableView.separatorColor = [UIColor VLCDarkBackgroundColor];
    self.view.backgroundColor = [UIColor VLCDarkBackgroundColor];

    self.title = NSLocalizedString(@"LOCAL_NETWORK", nil);

    _ftpServices = [[NSMutableArray alloc] init];

    _rawNetServices = [[NSMutableArray alloc] init];

    _ftpNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
    _ftpNetServiceBrowser.delegate = self;

    _plexServices = [[NSMutableArray alloc] init];
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

    _reachability = [Reachability reachabilityForLocalWiFi];
    [_reachability startNotifier];

    [self netReachabilityChanged:nil];

    _myHostName = [[VLCHTTPUploaderController sharedInstance] hostname];

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
        [self _startUPNPDiscovery];
        [self _startSAPDiscovery];
        [self _startDSMDiscovery];
    } else {
        [self _stopUPNPDiscovery];
        [self _stopSAPDiscovery];
        [self _stopDSMDiscovery];
    }
}

- (IBAction)goBack:(id)sender
{
    [self _stopUPNPDiscovery];
    [self _stopSAPDiscovery];
    [self _stopDSMDiscovery];

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
    switch (section) {
        case 0:
            return 1;

        case 1:
            return _filteredUPNPDevices.count;

        case 2:
            return _plexServices.count;

        case 3:
            return _ftpServices.count;

        case 4:
            return _httpServices.count;

        case 5:
            return _dsmDiscoverer.discoveredMedia.count;

        case 6:
            return _sapDiscoverer.discoveredMedia.count;

        default:
            return 0;
    }
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

    NSUInteger row = indexPath.row;
    NSUInteger section = indexPath.section;

    [cell setIsDirectory:YES];
    [cell setIcon:nil];

    switch (section) {
        case 0:
        {
            [cell setTitle:NSLocalizedString(@"CONNECT_TO_SERVER", nil)];
            [cell setIcon:[UIImage imageNamed:@"menuCone"]];
            break;
        }

        case 1:
        {
            UIImage *icon;
            if (_filteredUPNPDevices.count > row) {
                BasicUPnPDevice *device = _filteredUPNPDevices[row];
                [cell setTitle:[device friendlyName]];
                icon = [device smallIcon];
            }
            [cell setIcon:icon != nil ? icon : [UIImage imageNamed:@"serverIcon"]];
            break;
        }

        case 2:
        {
            [cell setTitle:[_plexServices[row] name]];
            [cell setIcon:[UIImage imageNamed:@"PlexServerIcon"]];
            break;
        }

        case 3:
        {
            [cell setTitle:[_ftpServices[row] name]];
            [cell setIcon:[UIImage imageNamed:@"serverIcon"]];
            break;
        }

        case 4:
        {
            [cell setTitle:[_httpServices[row] name]];
            [cell setIcon:[UIImage imageNamed:@"menuCone"]];
            break;
        }

        case 5:
        {
            [cell setTitle:[[_dsmDiscoverer.discoveredMedia mediaAtIndex:row] metadataForKey: VLCMetaInformationTitle]];
            [cell setIcon:[UIImage imageNamed:@"serverIcon"]];
            break;
        }

        case 6:
        {
            [cell setTitle:[[_sapDiscoverer.discoveredMedia mediaAtIndex:row] metadataForKey: VLCMetaInformationTitle]];
            [cell setIcon:[UIImage imageNamed:@"TVBroadcastIcon"]];
            break;
        }

        default:
            break;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSUInteger row = indexPath.row;
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
            if (_filteredUPNPDevices.count < row || _filteredUPNPDevices.count == 0)
                return;

            [_activityIndicator startAnimating];
            BasicUPnPDevice *device = _filteredUPNPDevices[row];
            if ([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"]) {
                MediaServer1Device *server = (MediaServer1Device*)device;
                VLCUPnPServerListViewController *targetViewController = [[VLCUPnPServerListViewController alloc] initWithUPNPDevice:server header:[device friendlyName] andRootID:@"0"];
                [self.navigationController pushViewController:targetViewController animated:YES];
            }
            break;
        }

        case 2:
        {
            NSString *name = [_PlexServicesInfo[row] objectForKey:@"name"];
            NSString *hostName = [_PlexServicesInfo[row] objectForKey:@"hostName"];
            NSString *portNum = [_PlexServicesInfo[row] objectForKey:@"port"];
            VLCLocalPlexFolderListViewController *targetViewController = [[VLCLocalPlexFolderListViewController alloc] initWithPlexServer:name serverAddress:hostName portNumber:portNum atPath:@"" authentification:@""];
            [[self navigationController] pushViewController:targetViewController animated:YES];
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
            loginViewController.hostname = [_ftpServices[row] hostName];
            break;
        }

        case 4:
        {
            NSString *name = [_httpServicesInfo[row] objectForKey:@"name"];
            NSString *hostName = [_httpServicesInfo[row] objectForKey:@"hostName"];
            NSString *portNum = [_httpServicesInfo[row] objectForKey:@"port"];
            VLCSharedLibraryListViewController *targetViewController = [[VLCSharedLibraryListViewController alloc]
                                                                        initWithHttpServer:name
                                                                        serverAddress:hostName
                                                                        portNumber:portNum];
            [[self navigationController] pushViewController:targetViewController animated:YES];
            break;
        }

        case 5:
        {
            VLCMedia *cellMedia = [_dsmDiscoverer.discoveredMedia mediaAtIndex:row];
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
            VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
            VLCMedia *cellMedia = [_sapDiscoverer.discoveredMedia mediaAtIndex:row];
            VLCMediaType mediaType = cellMedia.mediaType;
            if (mediaType != VLCMediaTypeDirectory && mediaType != VLCMediaTypeDisc)
                [appDelegate openMovieFromURL:[[_sapDiscoverer.discoveredMedia mediaAtIndex:row] url]];
            break;
        }

        default:
            break;
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
    [self _stopDSMDiscovery];

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

    [self _startUPNPDiscovery];
    [self _startSAPDiscovery];
    [self _startDSMDiscovery];
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
                                                                    initWithFTPServer:[NSString stringWithFormat:@"ftp://%@", server]
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
            APLog(@"Unsupported URL Scheme requested %lu", protocol);
            break;
    }
}

#pragma mark - custom table view appearance

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
        {
            // always hide the header of the first section
            return 0.;
        }
        case 1:
        {
            if (_filteredUPNPDevices.count == 0)
                return .0;
            break;
        }

        case 2:
        {
            if (_plexServices.count == 0)
                return .0;
            break;
        }

        case 3:
        {
            if (_ftpServices.count == 0)
                return .0;
            break;
        }

        case 4:
        {
            if (_httpServices.count == 0)
                return .0;
            break;
        }

        case 5:
        {
            if (_dsmDiscoverer.discoveredMedia.count == 0)
                return .0;
            break;
        }

        case 6:
        {
            if (_sapDiscoverer.discoveredMedia.count == 0)
                return .0;
            break;
        }

        default:
            break;
    }

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
        [_plexServices removeObject:aNetService];
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
        if (![_plexServices containsObject:aNetService]) {
            [_plexServices addObject:aNetService];
            NSMutableDictionary *_dictService = [[NSMutableDictionary alloc] init];
            [_dictService setObject:[aNetService name] forKey:@"name"];
            [_dictService setObject:[aNetService hostName] forKey:@"hostName"];
            NSString *portStr = [[NSString alloc] initWithFormat:@":%ld", (long)[aNetService port]];
            [_dictService setObject:portStr forKey:@"port"];
            [_PlexServicesInfo addObject:_dictService];
        }
    }  else if ([aNetService.type isEqualToString:@"_http._tcp."]) {
        if ([[aNetService hostName] rangeOfString:_myHostName].location == NSNotFound) {
            if (!_httpParser)
                _httpParser = [[VLCSharedLibraryParser alloc] init];
            [_httpParser checkNetserviceForVLCService:aNetService];
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

#pragma mark - shared library stuff

- (void)sharedLibraryFound:(NSNotification *)aNotification
{
    NSNetService *aNetService = [aNotification.userInfo objectForKey:@"aNetService"];

    if (![_httpServices containsObject:aNetService]) {
        [_httpServices addObject:aNetService];
        NSMutableDictionary *_dictService = [[NSMutableDictionary alloc] init];
        [_dictService setObject:[aNetService name] forKey:@"name"];
        [_dictService setObject:[aNetService hostName] forKey:@"hostName"];
        NSString *portStr = [[NSString alloc] initWithFormat:@"%ld", (long)[aNetService port]];
        [_dictService setObject:portStr forKey:@"port"];
        [_httpServicesInfo addObject:_dictService];
    }
}

#pragma mark - UPNP discovery
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
    if (!_setup) {
        [[managerInstance SSDP] setUserAgentProduct:[NSString stringWithFormat:@"VLCforiOS/%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]] andOS:[NSString stringWithFormat:@"iOS/%@", [[UIDevice currentDevice] systemVersion]]];
        _setup = YES;
    }

    //Search for UPnP Devices
    [[managerInstance SSDP] startSSDP];
    [[managerInstance SSDP] notifySSDPAlive];

    _searchTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:1.0] interval:10.0 target:self selector:@selector(_performSSDPSearch) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_searchTimer forMode:NSRunLoopCommonModes];
    _udnpDiscoveryRunning = YES;
}

- (void)_performSSDPSearch
{
    UPnPManager *managerInstance = [UPnPManager GetInstance];
    [[managerInstance SSDP] searchSSDP];
    [[managerInstance SSDP] searchForMediaServer];
    [[managerInstance SSDP] performSelectorInBackground:@selector(SSDPDBUpdate) withObject:nil];
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
    if (_reachability.currentReachabilityStatus != ReachableViaWiFi)
        return;

    if (!_sapDiscoverer)
        _sapDiscoverer = [[VLCMediaDiscoverer alloc] initWithName:@"sap"];
    [_sapDiscoverer startDiscoverer];
    _sapDiscoverer.discoveredMedia.delegate = self;
}

- (void)_stopSAPDiscovery
{
    [_sapDiscoverer stopDiscoverer];
    _sapDiscoverer = nil;
}

- (void)mediaList:(VLCMediaList *)aMediaList mediaAdded:(VLCMedia *)media atIndex:(NSInteger)index
{
    [media parseWithOptions:VLCMediaParseNetwork];
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)mediaList:(VLCMediaList *)aMediaList mediaRemovedAtIndex:(NSInteger)index
{
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

#pragma DSM discovery

- (void)_startDSMDiscovery
{
    if (_reachability.currentReachabilityStatus != ReachableViaWiFi)
        return;

    if (_dsmDiscoverer)
        return;

    _dsmDiscoverer = [[VLCMediaDiscoverer alloc] initWithName:@"dsm"];
    [_dsmDiscoverer startDiscoverer];
    _dsmDiscoverer.discoveredMedia.delegate = self;
}

- (void)_stopDSMDiscovery
{
    [_dsmDiscoverer stopDiscoverer];
    _dsmDiscoverer = nil;
}

@end
