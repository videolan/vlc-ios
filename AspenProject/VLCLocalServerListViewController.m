//
//  VLCLocalServerListViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 10.08.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

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

@interface VLCLocalServerListViewController () <UITableViewDataSource, UITableViewDelegate, NSNetServiceBrowserDelegate, VLCNetworkLoginViewController>
{
    UIBarButtonItem *_backToMenuButton;
    NSArray *_sectionHeaderTexts;

    NSNetServiceBrowser *_netServiceBrowser;

    NSMutableArray *_ftpServices;

    NSArray *_filteredUPNPDevices;
    NSArray *_UPNPdevices;

    VLCNetworkLoginViewController *_loginViewController;
}

@end

@implementation VLCLocalServerListViewController

- (void)dealloc
{
    [_netServiceBrowser stop];
}

- (void)loadView
{
    _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    self.view = _tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _sectionHeaderTexts = @[@"Universal Plug'n'Play (UPNP)", @"File Transfer Protocol (FTP)"];

    _backToMenuButton = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = _backToMenuButton;

    self.tableView.rowHeight = [VLCLocalNetworkListCell heightOfCell];
    self.tableView.separatorColor = [UIColor colorWithWhite:.122 alpha:1.];
    self.view.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];

    self.title = NSLocalizedString(@"LOCAL_NETWORK", @"");

    [self performSelectorInBackground:@selector(_startUPNPDiscovery) withObject:nil];

    _ftpServices = [[NSMutableArray alloc] init];
    [_ftpServices addObject:@"Connect to Server"];

    _netServiceBrowser = [[NSNetServiceBrowser alloc] init];
    _netServiceBrowser.delegate = self;
    [self _triggerNetServiceBrowser];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_netServiceBrowser stop];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _triggerNetServiceBrowser];
}

- (void)_triggerNetServiceBrowser
{
    [_netServiceBrowser searchForServicesOfType:@"_ftp._tcp." inDomain:@""];
}

- (void)_startUPNPDiscovery
{
    UPnPDB* db = [[UPnPManager GetInstance] DB];
    _UPNPdevices = [db rootDevices];

    [db addObserver:(UPnPDBObserver*)self];

    //Optional; set User Agent
    [[[UPnPManager GetInstance] SSDP] setUserAgentProduct:[NSString stringWithFormat:@"VLC for iOS/%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] andOS:@"iOS"];

    //Search for UPnP Devices
    [[[UPnPManager GetInstance] SSDP] searchSSDP];
}

- (IBAction)goBack:(id)sender
{
    [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController] toggleSidebar:![(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController].sidebarShowing duration:kGHRevealSidebarDefaultAnimationDuration];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
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

    return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor colorWithWhite:.122 alpha:1.];
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

    if (section == 0) {
        BasicUPnPDevice *device = _filteredUPNPDevices[row];
        [cell setTitle:[device friendlyName]];
        [cell setIcon:[device smallIcon]];
    } else if (section == 1) {
        if (row == 0)
            [cell setTitle:_ftpServices[row]];
        else
            [cell setTitle:[_ftpServices[row] name]];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        BasicUPnPDevice *device = _filteredUPNPDevices[indexPath.row];
        if ([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"]) {
            MediaServer1Device *server = (MediaServer1Device*)device;
            VLCLocalServerFolderListViewController *targetViewController = [[VLCLocalServerFolderListViewController alloc] initWithDevice:server header:[device friendlyName] andRootID:@"0"];
            [self.navigationController pushViewController:targetViewController animated:YES];
        }
    } else if (indexPath.section == 1) {
        if (_loginViewController == nil) {
            _loginViewController = [[VLCNetworkLoginViewController alloc] initWithNibName:nil bundle:nil];
            _loginViewController.delegate = self;
        }

        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:_loginViewController];
        [navCon loadTheme];
        navCon.navigationBarHidden = NO;

        if (indexPath.row != 0) { // FTP Connect To Server Special Item
            if ([_ftpServices[indexPath.row] hostName].length > 0)
                _loginViewController.serverAddressField.text = [NSString stringWithFormat:@"ftp://%@", [_ftpServices[indexPath.row] hostName]];
        }

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            navCon.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentModalViewController:navCon animated:YES];

            if (_loginViewController.navigationItem.leftBarButtonItem == nil) {
                UIBarButtonItem *doneButton = [UIBarButtonItem themedDoneButtonWithTarget:_loginViewController andSelector:@selector(dismiss:)];

                _loginViewController.navigationItem.leftBarButtonItem = doneButton;
            }
        } else
            [self.navigationController pushViewController:_loginViewController animated:YES];
    }
}

#pragma mark - login panel protocol

- (void)loginToServer:(NSString *)server confirmedWithUsername:(NSString *)username andPassword:(NSString *)password
{
    _loginViewController = nil;
    NSLog(@"user wants to connect to %@ with %@/%@", server, username, password);
}

#pragma mark - custom table view appearance

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 21.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSObject *headerText = NSLocalizedString(_sectionHeaderTexts[section], @"");
	UIView *headerView = nil;
	if (headerText != [NSNull null]) {
		headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, 21.0f)];
		CAGradientLayer *gradient = [CAGradientLayer layer];
		gradient.frame = headerView.bounds;
		gradient.colors = @[
                      (id)[UIColor colorWithRed:(67.0f/255.0f) green:(74.0f/255.0f) blue:(94.0f/255.0f) alpha:1.0f].CGColor,
                      (id)[UIColor colorWithRed:(57.0f/255.0f) green:(64.0f/255.0f) blue:(82.0f/255.0f) alpha:1.0f].CGColor,
                      ];
		[headerView.layer insertSublayer:gradient atIndex:0];

		UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectInset(headerView.bounds, 12.0f, 5.0f)];
		textLabel.text = (NSString *) headerText;
		textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:([UIFont systemFontSize] * 0.8f)];
		textLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		textLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.25f];
		textLabel.textColor = [UIColor colorWithRed:(125.0f/255.0f) green:(129.0f/255.0f) blue:(146.0f/255.0f) alpha:1.0f];
		textLabel.backgroundColor = [UIColor clearColor];
		[headerView addSubview:textLabel];

		UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
		topLine.backgroundColor = [UIColor colorWithRed:(78.0f/255.0f) green:(86.0f/255.0f) blue:(103.0f/255.0f) alpha:1.0f];
		[headerView addSubview:topLine];

		UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 21.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)];
		bottomLine.backgroundColor = [UIColor colorWithRed:(36.0f/255.0f) green:(42.0f/255.0f) blue:(5.0f/255.0f) alpha:1.0f];
		[headerView addSubview:bottomLine];
	}
	return headerView;
}

#pragma mark - bonjour discovery
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [aNetService resolveWithTimeout:1.];
    if (![_ftpServices containsObject:aNetService])
        [_ftpServices addObject:aNetService];
    if (!moreComing)
        [self.tableView reloadData];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [_ftpServices removeObject:aNetService];
    if (!moreComing)
        [self.tableView reloadData];
}

#pragma mark - UPNP details
//protocol UPnPDBObserver
- (void)UPnPDBWillUpdate:(UPnPDB*)sender{
    APLog(@"UPnPDBWillUpdate %d", _UPNPdevices.count);
}

- (void)UPnPDBUpdated:(UPnPDB*)sender{
    APLog(@"UPnPDBUpdated %d", _UPNPdevices.count);

    NSUInteger count = _UPNPdevices.count;
    BasicUPnPDevice *device;
    NSMutableArray *mutArray = [[NSMutableArray alloc] init];
    for (NSUInteger x = 0; x < count; x++) {
        device = _UPNPdevices[x];
        if ([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"])
            [mutArray addObject:device];
    }
    _filteredUPNPDevices = nil;
    _filteredUPNPDevices = [NSArray arrayWithArray:mutArray];

    [self.tableView performSelectorOnMainThread : @ selector(reloadData) withObject:nil waitUntilDone:YES];
}

@end
