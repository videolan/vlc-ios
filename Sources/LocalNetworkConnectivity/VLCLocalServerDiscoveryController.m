/*****************************************************************************
 * VLCLocalServerListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalServerDiscoveryController.h"

#import "VLCServerListViewController.h"
#import "VLCPlaybackController.h"
#import "UPnPManager.h"
#import "VLCNetworkListCell.h"

#import "VLCLocalPlexFolderListViewController.h"

#import "VLCFTPServerListViewController.h"
#import "VLCUPnPServerListViewController.h"
#import "VLCDiscoveryListViewController.h"

#import "VLCSharedLibraryListViewController.h"
#import "VLCSharedLibraryParser.h"

#import "VLCHTTPUploaderController.h"

#import "Reachability.h"
#import "VLCLocalNetworkServiceBrowserNetService.h"
#import "VLCLocalNetworkServiceBrowserMediaDiscoverer.h"


typedef NS_ENUM(NSUInteger, VLCLocalServerSections) {
    VLCLocalServerSectionGeneric = 0,
    VLCLocalServerSectionUPnP,
    VLCLocalServerSectionPlex,
    VLCLocalServerSectionFTP,
    VLCLocalServerSectionVLCiOS,
    VLCLocalServerSectionSMB,
    VLCLocalServerSectionSAP
};



@interface VLCLocalServerDiscoveryController () <VLCLocalNetworkServiceBrowserDelegate, VLCMediaListDelegate, UPnPDBObserver>
{

    id<VLCLocalNetworkServiceBrowser> _plexBrowser;
    id<VLCLocalNetworkServiceBrowser> _FTPBrowser;
    id<VLCLocalNetworkServiceBrowser> _HTTPBrowser;

    NSArray<VLCLocalNetworkServiceUPnP*> *_filteredUPNPDevices;
    NSArray *_UPNPdevices;

    id<VLCLocalNetworkServiceBrowser> _sapBrowser;
    id<VLCLocalNetworkServiceBrowser> _dsmBrowser;

    VLCSharedLibraryParser *_httpParser;

    Reachability *_reachability;

    NSString *_myHostName;

    BOOL _udnpDiscoveryRunning;
    NSTimer *_searchTimer;
    BOOL _setup;
}

@end

@implementation VLCLocalServerDiscoveryController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_reachability stopNotifier];
    [self stopDiscovery];
}

- (void)stopDiscovery
{
    [self _stopUPNPDiscovery];
    [_sapBrowser stopDiscovery];
    [_dsmBrowser stopDiscovery];

    [_FTPBrowser stopDiscovery];
    [_plexBrowser stopDiscovery];
    [_HTTPBrowser stopDiscovery];
}

- (void)startDiscovery
{

    [_FTPBrowser startDiscovery];
    [_plexBrowser startDiscovery];
    [_HTTPBrowser startDiscovery];

    [self netReachabilityChanged];
}

- (NSArray *)sectionHeaderTexts
{
    return @[@"Generic",
             @"Universal Plug'n'Play (UPnP)",
             _plexBrowser.name,
             _FTPBrowser.name,
             _HTTPBrowser.name,
             _dsmBrowser.name,
             _sapBrowser.name];
}

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter addObserver:self
                      selector:@selector(stopDiscovery)
                          name:UIApplicationWillResignActiveNotification
                        object:[UIApplication sharedApplication]];

    [defaultCenter addObserver:self
                      selector:@selector(startDiscovery:)
                          name:UIApplicationDidBecomeActiveNotification
                        object:[UIApplication sharedApplication]];


    _plexBrowser = [[VLCLocalNetworkServiceBrowserPlex alloc] init];
    _plexBrowser.delegate = self;
    _FTPBrowser = [[VLCLocalNetworkServiceBrowserFTP alloc] init];
    _FTPBrowser.delegate = self;
    _HTTPBrowser = [[VLCLocalNetworkServiceBrowserHTTP alloc] init];
    _HTTPBrowser.delegate = self;

    _sapBrowser = [[VLCLocalNetworkServiceBrowserSAP alloc] init];
    _sapBrowser.delegate = self;


    _reachability = [Reachability reachabilityForLocalWiFi];
    [_reachability startNotifier];

    [self netReachabilityChanged];

    _myHostName = [[VLCHTTPUploaderController sharedInstance] hostname];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netReachabilityChanged) name:kReachabilityChangedNotification object:nil];

    return self;
}

- (void)netReachabilityChanged
{
    if (_reachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self _startUPNPDiscovery];
        [self startDiscovery];
    } else {
        [self _stopUPNPDiscovery];
        [self stopDiscovery];
    }
}

- (IBAction)goBack:(id)sender
{
    [self _stopUPNPDiscovery];
    [self stopDiscovery];

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

- (id<VLCLocalNetworkService>)networkServiceForIndexPath:(NSIndexPath *)indexPath
{
    VLCLocalServerSections section = indexPath.section;
    NSUInteger row = indexPath.row;


    switch (section) {
        case VLCLocalServerSectionGeneric:
        {
            return [[VLCLocalNetworkServiceItemLogin alloc] init];
        }

        case VLCLocalServerSectionUPnP:
        {
            if (_filteredUPNPDevices.count > row) {
                return _filteredUPNPDevices[row];
            }
        }

        case VLCLocalServerSectionPlex:
        {
            return [_plexBrowser networkServiceForIndex:row];
        }

        case VLCLocalServerSectionFTP:
        {
            return [_FTPBrowser networkServiceForIndex:row];
        }

        case VLCLocalServerSectionVLCiOS:
        {
            return [_HTTPBrowser networkServiceForIndex:row];
        }

        case VLCLocalServerSectionSMB:
        {
            return [_dsmBrowser networkServiceForIndex:row];
        }

        case VLCLocalServerSectionSAP:
        {
            return [_sapBrowser networkServiceForIndex:row];
        }

        default:
            break;
    }
    return [[VLCLocalNetworkServiceItem alloc] initWithTile:@"FAIL"
                                                       icon:nil];

}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    switch (section) {
        case VLCLocalServerSectionGeneric:
            return 1;

        case VLCLocalServerSectionUPnP:
            return _filteredUPNPDevices.count;

        case VLCLocalServerSectionPlex:
            return _plexBrowser.numberOfItems;

        case VLCLocalServerSectionFTP:
            return _FTPBrowser.numberOfItems;

        case VLCLocalServerSectionVLCiOS:
            return _HTTPBrowser.numberOfItems;

        case VLCLocalServerSectionSMB:
            return _dsmBrowser.numberOfItems;

        case VLCLocalServerSectionSAP:
            return _sapBrowser.numberOfItems;

        default:
            return 0;
    }
}

- (BOOL)refreshDiscoveredData
{
    if (_reachability.currentReachabilityStatus != ReachableViaWiFi)
         return NO;

    UPnPManager *managerInstance = [UPnPManager GetInstance];
    [[managerInstance DB] removeObserver:self];
    [[managerInstance SSDP] stopSSDP];

    [self _startUPNPDiscovery];

    return YES;
}

#pragma mark - VLCLocalNetworkServiceBrowserDelegate
- (void)localNetworkServiceBrowserDidUpdateServices:(id<VLCLocalNetworkServiceBrowser>)serviceBrowser {
    if ([self.delegate respondsToSelector:@selector(discoveryFoundSomethingNew)]) {
        [self.delegate discoveryFoundSomethingNew];
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
    NSMutableArray<VLCLocalNetworkServiceUPnP*> *mutArray = [[NSMutableArray alloc] init];
    for (NSUInteger x = 0; x < count; x++) {
        device = _UPNPdevices[x];
        if ([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"])
            [mutArray addObject:[[VLCLocalNetworkServiceUPnP alloc] initWithUPnPDevice:device]];
        else
            APLog(@"found device '%@' with unsupported urn '%@'", [device friendlyName], [device urn]);
    }
    _filteredUPNPDevices = nil;
    _filteredUPNPDevices = [NSArray arrayWithArray:mutArray];

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(discoveryFoundSomethingNew)]) {
            [self.delegate performSelectorOnMainThread:@selector(discoveryFoundSomethingNew) withObject:nil waitUntilDone:NO];
        }
    }
}

@end
