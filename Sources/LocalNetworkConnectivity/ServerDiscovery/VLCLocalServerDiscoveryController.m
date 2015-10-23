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

#import "Reachability.h"

#import "VLCLocalNetworkServiceBrowserNetService.h"
#import "VLCLocalNetworkServiceBrowserMediaDiscoverer.h"
#import "VLCLocalNetworkServiceBrowserManualConnect.h"
#import "VLCLocalNetworkServiceBrowserUPnP.h"


@interface VLCLocalServerDiscoveryController () <VLCLocalNetworkServiceBrowserDelegate>
{
    NSArray<id<VLCLocalNetworkServiceBrowser>> *_serviceBrowsers;
    Reachability *_reachability;
}

@end

@implementation VLCLocalServerDiscoveryController


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
                      selector:@selector(startDiscovery)
                          name:UIApplicationDidBecomeActiveNotification
                        object:[UIApplication sharedApplication]];

    _serviceBrowsers = @[
                         [[VLCLocalNetworkServiceBrowserManualConnect alloc] init],
                         [[VLCLocalNetworkServiceBrowserUPnP alloc] init],
                         [[VLCLocalNetworkServiceBrowserPlex alloc] init],
                         [[VLCLocalNetworkServiceBrowserFTP alloc] init],
                         [[VLCLocalNetworkServiceBrowserHTTP alloc] init],
                         [[VLCLocalNetworkServiceBrowserSAP alloc] init],
                         [[VLCLocalNetworkServiceBrowserDSM alloc] init],
                         ];

    [_serviceBrowsers enumerateObjectsUsingBlock:^(id<VLCLocalNetworkServiceBrowser>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.delegate = self;
    }];


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netReachabilityChanged) name:kReachabilityChangedNotification object:nil];

    _reachability = [Reachability reachabilityForLocalWiFi];
    [_reachability startNotifier];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_reachability stopNotifier];
    [self stopDiscovery];
}

- (void)startDiscovery
{
    if (_reachability.currentReachabilityStatus != ReachableViaWiFi) {
        return;
    }

    [_serviceBrowsers makeObjectsPerformSelector:@selector(startDiscovery)];
}

- (void)stopDiscovery
{
    [_serviceBrowsers makeObjectsPerformSelector:@selector(stopDiscovery)];
}

- (BOOL)refreshDiscoveredData
{
    if (_reachability.currentReachabilityStatus != ReachableViaWiFi)
        return NO;

    [self stopDiscovery];
    [self startDiscovery];

    return YES;
}

#pragma mark - Reachability
- (void)netReachabilityChanged
{
    if (_reachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self startDiscovery];
    } else {
        [self stopDiscovery];
    }
}

#pragma mark - data source

- (NSUInteger)numberOfSections {
    return _serviceBrowsers.count;
}

- (NSString *)titleForSection:(NSUInteger)section
{
    id<VLCLocalNetworkServiceBrowser> browser = _serviceBrowsers[section];
    return browser.name;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
    id<VLCLocalNetworkServiceBrowser> browser = _serviceBrowsers[section];
    return browser.numberOfItems;
}

- (id<VLCLocalNetworkService>)networkServiceForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = indexPath.section;
    NSUInteger row = indexPath.row;

    id<VLCLocalNetworkServiceBrowser> browser = _serviceBrowsers[section];
    return [browser networkServiceForIndex:row];
}

#pragma mark - VLCLocalNetworkServiceBrowserDelegate
- (void)localNetworkServiceBrowserDidUpdateServices:(id<VLCLocalNetworkServiceBrowser>)serviceBrowser {
    if ([self.delegate respondsToSelector:@selector(discoveryFoundSomethingNew)]) {
        [self.delegate discoveryFoundSomethingNew];
    }
}

@end
