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

#define kPlexServiceType @"_plexmediasvr._tcp."

typedef NS_ENUM(NSUInteger, VLCLocalServerSections) {
    VLCLocalServerSectionGeneric = 0,
    VLCLocalServerSectionUPnP,
    VLCLocalServerSectionPlex,
    VLCLocalServerSectionFTP,
    VLCLocalServerSectionVLCiOS,
    VLCLocalServerSectionSMB,
    VLCLocalServerSectionSAP
};

@interface NSMutableArray(VLCLocalNetworkServiceNetService)
-(NSUInteger)vlc_indexOfServiceWithNetService:(NSNetService*)netService;
-(void)vlc_removeServiceWithNetService:(NSNetService*)netService;

@end
@implementation NSMutableArray (VLCLocalNetworkServiceNetService)

- (NSUInteger)vlc_indexOfServiceWithNetService:(NSNetService *)netService {
    NSUInteger index = [self indexOfObjectPassingTest:^BOOL(VLCLocalNetworkServiceNetService *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj respondsToSelector:@selector(netService)]) return false;

        BOOL equal = [obj.netService isEqual:netService];
        if (equal) {
            *stop = YES;
        }
        return equal;
    }];
    return index;
}

-(void)vlc_removeServiceWithNetService:(NSNetService *)netService {
    NSUInteger index = [self vlc_indexOfServiceWithNetService:netService];
    if (index != NSNotFound) {
        [self removeObjectAtIndex:index];
    }
}
@end


@interface VLCLocalServerDiscoveryController () <NSNetServiceBrowserDelegate, NSNetServiceDelegate, VLCMediaListDelegate, UPnPDBObserver>
{
    NSNetServiceBrowser *_ftpNetServiceBrowser;
    NSNetServiceBrowser *_PlexNetServiceBrowser;
    NSNetServiceBrowser *_httpNetServiceBrowser;
    NSMutableArray<VLCLocalNetworkServicePlex*> *_plexServices;
    NSMutableArray<VLCLocalNetworkServiceHTTP*> *_httpVLCServices;
    NSMutableArray<VLCLocalNetworkServiceFTP*> *_ftpServices;

    // to keep strong references while resolving
    NSMutableArray *_rawNetServices;

    NSArray<VLCLocalNetworkServiceUPnP*> *_filteredUPNPDevices;
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
    return @[@"Generic",
             @"Universal Plug'n'Play (UPnP)",
             @"Plex Media Server (via Bonjour)",
             @"File Transfer Protocol (FTP)",
             NSLocalizedString(@"SHARED_VLC_IOS_LIBRARY", nil),
             NSLocalizedString(@"SMB_CIFS_FILE_SERVERS", nil),
             @"SAP"];
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

    [defaultCenter addObserver:self
                      selector:@selector(sharedLibraryFound:)
                          name:VLCSharedLibraryParserDeterminedNetserviceAsVLCInstance
                        object:nil];

    _ftpServices = [[NSMutableArray alloc] init];

    _rawNetServices = [[NSMutableArray alloc] init];

    _ftpNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
    _ftpNetServiceBrowser.delegate = self;

    _plexServices = [[NSMutableArray alloc] init];
    _PlexNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
    _PlexNetServiceBrowser.delegate = self;

    _httpVLCServices = [[NSMutableArray alloc] init];
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
            return _plexServices[row];
        }

        case VLCLocalServerSectionFTP:
        {
            return _ftpServices[row];
        }

        case VLCLocalServerSectionVLCiOS:
        {
            return _httpVLCServices[row];
        }

        case VLCLocalServerSectionSMB:
        {
            return [[VLCLocalNetworkServiceDSM alloc] initWithMediaItem:[_dsmDiscoverer.discoveredMedia mediaAtIndex:row]];
        }

        case VLCLocalServerSectionSAP:
        {
            return [[VLCLocalNetworkServiceSAP alloc] initWithMediaItem:[_sapDiscoverer.discoveredMedia mediaAtIndex:row]];
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
            return _plexServices.count;

        case VLCLocalServerSectionFTP:
            return _ftpServices.count;

        case VLCLocalServerSectionVLCiOS:
            return _httpVLCServices.count;

        case VLCLocalServerSectionSMB:
            return _dsmDiscoverer.discoveredMedia.count;

        case VLCLocalServerSectionSAP:
            return _sapDiscoverer.discoveredMedia.count;

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
    if ([aNetService.type isEqualToString:@"_ftp._tcp."]) {
        [_ftpServices vlc_removeServiceWithNetService:aNetService];
    }
    if ([aNetService.type isEqualToString:kPlexServiceType]) {
        [_plexServices vlc_removeServiceWithNetService:aNetService];
    }
    if ([aNetService.type isEqualToString:@"_http._tcp."]) {
        NSUInteger index = [_httpVLCServices vlc_indexOfServiceWithNetService:aNetService];
        if (index != NSNotFound) {
            [_httpVLCServices removeObjectAtIndex:index];
        }
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
        NSUInteger index = [_ftpServices vlc_indexOfServiceWithNetService:aNetService];
        if (index == NSNotFound) {
            [_ftpServices addObject:[[VLCLocalNetworkServiceFTP alloc] initWithNetService:aNetService]];
        }
    } else if ([aNetService.type isEqualToString:kPlexServiceType]) {
        if ([_plexServices vlc_indexOfServiceWithNetService:aNetService] == NSNotFound) {
            [_plexServices addObject:[[VLCLocalNetworkServicePlex alloc] initWithNetService: aNetService]];
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

    NSUInteger index = [_httpVLCServices vlc_indexOfServiceWithNetService:aNetService];
    if (index == NSNotFound) {
        [_httpVLCServices addObject:[[VLCLocalNetworkServiceHTTP alloc] initWithNetService:aNetService]];
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
