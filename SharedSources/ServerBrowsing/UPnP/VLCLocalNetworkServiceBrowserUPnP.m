/*****************************************************************************
 * VLCLocalNetworkServiceBrowserUPnP.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
#import "VLCLocalNetworkServiceBrowserUPnP.h"
#import "VLCLocalNetworkServiceUPnP.h"

#import "UPnPManager.h"

@interface VLCLocalNetworkServiceBrowserUPnP () <UPnPDBObserver>{
    BOOL _udnpDiscoveryRunning;
    NSTimer *_searchTimer;
    BOOL _setup;
}
@property (nonatomic) NSArray<VLCLocalNetworkServiceUPnP*> *filteredUPNPDevices;
@property (nonatomic) NSArray *UPNPdevices;
@end

@implementation VLCLocalNetworkServiceBrowserUPnP
@synthesize name = _name, delegate = _delegate;


- (instancetype)init
{
    self = [super init];
    if (self) {
#if TARGET_OS_TV
        _name = NSLocalizedString(@"UPNP_SHORT", nil);
#else
        _name = NSLocalizedString(@"UPNP_LONG", nil);
#endif
    }
    return self;
}

#pragma mark - VLCLocalNetworkServiceBrowser Protocol
- (NSUInteger)numberOfItems {
    return _filteredUPNPDevices.count;
}

- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    if (index < _filteredUPNPDevices.count)
        return _filteredUPNPDevices[index];
    return nil;
}

- (void)startDiscovery {
    [self _startUPNPDiscovery];
}
- (void)stopDiscovery {
    [self _stopUPNPDiscovery];
}

#pragma mark -

#pragma mark - UPNP discovery
- (void)_startUPNPDiscovery
{
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

#pragma mark - UPnPDBObserver protocol
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
            [mutArray addObject:[[VLCLocalNetworkServiceUPnP alloc] initWithUPnPDevice:device serviceName:self.name]];
        else
            APLog(@"found device '%@' with unsupported urn '%@'", [device friendlyName], [device urn]);
    }
    _filteredUPNPDevices = nil;
    _filteredUPNPDevices = [NSArray arrayWithArray:mutArray];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.delegate localNetworkServiceBrowserDidUpdateServices:self];
    }];
}

@end
