/*****************************************************************************
 * VLCLocalServerListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
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

#define kPlexServiceType @"_plexmediasvr._tcp."

@interface VLCLocalServerDiscoveryController () <NSNetServiceBrowserDelegate, NSNetServiceDelegate, VLCMediaListDelegate, UPnPDBObserver>
{
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
    [_ftpNetServiceBrowser stop];
    [_PlexNetServiceBrowser stop];
    [_httpNetServiceBrowser stop];
}

- (void)stopDiscovery
{
    [self _stopUPNPDiscovery];
    [self _stopSAPDiscovery];
    [self _stopDSMDiscovery];

    [_ftpNetServiceBrowser stop];
    [_PlexNetServiceBrowser stop];
    [_httpNetServiceBrowser stop];
}

- (void)startDiscovery
{
    [_ftpNetServiceBrowser searchForServicesOfType:@"_ftp._tcp." inDomain:@""];
    [_PlexNetServiceBrowser searchForServicesOfType:kPlexServiceType inDomain:@""];
    [_httpNetServiceBrowser searchForServicesOfType:@"_http._tcp." inDomain:@""];

    [self netReachabilityChanged];
}

- (NSArray *)sectionHeaderTexts
{
    return @[@"Generic", @"Universal Plug'n'Play (UPnP)", @"Plex Media Server (via Bonjour)", @"File Transfer Protocol (FTP)", NSLocalizedString(@"SHARED_VLC_IOS_LIBRARY", nil), NSLocalizedString(@"SMB_CIFS_FILE_SERVERS", nil), @"SAP"];
}

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;

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

- (NSInteger)numberOfItemsInSection:(NSInteger)section
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

- (NSString *)titleForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    NSUInteger section = indexPath.section;

    switch (section) {
        case 0:
        {
            return NSLocalizedString(@"CONNECT_TO_SERVER", nil);
        }

        case 1:
        {
            if (_filteredUPNPDevices.count > row) {
                BasicUPnPDevice *device = _filteredUPNPDevices[row];
                return [device friendlyName];
            }
            return @"";
        }

        case 2:
        {
            return [_plexServices[row] name];
        }

        case 3:
        {
            return [_ftpServices[row] name];
        }

        case 4:
        {
            return [_httpServices[row] name];
        }

        case 5:
        {
            return [[_dsmDiscoverer.discoveredMedia mediaAtIndex:row] metadataForKey: VLCMetaInformationTitle];
        }

        case 6:
        {
            return [[_sapDiscoverer.discoveredMedia mediaAtIndex:row] metadataForKey: VLCMetaInformationTitle];
        }

        default:
            return @"";
    }
}

- (UIImage *)iconForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    NSUInteger section = indexPath.section;

    switch (section) {
        case 0:
        {
            return [UIImage imageNamed:@"menuCone"];
        }

        case 1:
        {
            UIImage *icon;
            if (_filteredUPNPDevices.count > row) {
                BasicUPnPDevice *device = _filteredUPNPDevices[row];
                icon = [device smallIcon];
            }
            return icon != nil ? icon : [UIImage imageNamed:@"serverIcon"];
        }

        case 2:
        {
            return [UIImage imageNamed:@"PlexServerIcon"];
        }

        case 3:
        {
            return [UIImage imageNamed:@"serverIcon"];
        }

        case 4:
        {
            return [UIImage imageNamed:@"menuCone"];
        }

        case 5:
        {
            return [UIImage imageNamed:@"serverIcon"];
        }

        case 6:
        {
            return [UIImage imageNamed:@"TVBroadcastIcon"];
        }

        default:
            return nil;
    }
}

- (BasicUPnPDevice *)upnpDeviceForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    if (row > _filteredUPNPDevices.count || _filteredUPNPDevices.count == 0)
        return nil;
    return _filteredUPNPDevices[row];
}

- (NSDictionary *)plexServiceDescriptionForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    if (row > _PlexServicesInfo.count || _PlexServicesInfo.count == 0)
        return nil;
    return _PlexServicesInfo[row];
}

- (NSString *)ftpHostnameForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    if (row > _ftpServices.count || _ftpServices.count == 0)
        return nil;
    return [_ftpServices[row] hostName];
}

- (NSDictionary *)httpServiceDescriptionForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    if (row > _httpServicesInfo.count || _httpServicesInfo.count == 0)
        return nil;
    return _httpServicesInfo[row];
}

- (VLCMedia *)dsmDiscoveryForIndexPath:(NSIndexPath *)indexPath
{
    return [_dsmDiscoverer.discoveredMedia mediaAtIndex:indexPath.row];
}

- (VLCMedia *)sapDiscoveryForIndexPath:(NSIndexPath *)indexPath
{
    return [_sapDiscoverer.discoveredMedia mediaAtIndex:indexPath.row];
}

- (BOOL)refreshDiscoveredData
{
    if (_reachability.currentReachabilityStatus != ReachableViaWiFi)
         return NO;

    UPnPManager *managerInstance = [UPnPManager GetInstance];
    [[managerInstance DB] removeObserver:self];
    [[managerInstance SSDP] stopSSDP];
    [self _stopDSMDiscovery];

    [self _startUPNPDiscovery];
    [self _startSAPDiscovery];
    [self _startDSMDiscovery];

    return YES;
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
    if (!moreComing) {
        if (self.delegate) {
            if ([self.delegate respondsToSelector:@selector(discoveryFoundSomethingNew)]) {
                [self.delegate discoveryFoundSomethingNew];
            }
        }
    }
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
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(discoveryFoundSomethingNew)]) {
            [self.delegate discoveryFoundSomethingNew];
        }
    }
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

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(discoveryFoundSomethingNew)]) {
            [self.delegate performSelectorOnMainThread:@selector(discoveryFoundSomethingNew) withObject:nil waitUntilDone:NO];
        }
    }
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
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(discoveryFoundSomethingNew)]) {
            [self.delegate performSelectorOnMainThread:@selector(discoveryFoundSomethingNew) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)mediaList:(VLCMediaList *)aMediaList mediaRemovedAtIndex:(NSInteger)index
{
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(discoveryFoundSomethingNew)]) {
            [self.delegate performSelectorOnMainThread:@selector(discoveryFoundSomethingNew) withObject:nil waitUntilDone:NO];
        }
    }
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
