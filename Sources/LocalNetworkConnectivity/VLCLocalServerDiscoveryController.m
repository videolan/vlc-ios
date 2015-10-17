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
#import "VLCLocalNetworkServiceBrowserManualConnect.h"
#import "VLCLocalNetworkServiceBrowserUPnP.h"

typedef NS_ENUM(NSUInteger, VLCLocalServerSections) {
    VLCLocalServerSectionGeneric = 0,
    VLCLocalServerSectionUPnP,
    VLCLocalServerSectionPlex,
    VLCLocalServerSectionFTP,
    VLCLocalServerSectionVLCiOS,
    VLCLocalServerSectionSMB,
    VLCLocalServerSectionSAP
};



@interface VLCLocalServerDiscoveryController () <VLCLocalNetworkServiceBrowserDelegate>
{
    id<VLCLocalNetworkServiceBrowser> _manualConnectBrowser;
    id<VLCLocalNetworkServiceBrowser> _plexBrowser;
    id<VLCLocalNetworkServiceBrowser> _FTPBrowser;
    id<VLCLocalNetworkServiceBrowser> _HTTPBrowser;

    id<VLCLocalNetworkServiceBrowser> _UPnPBrowser;

    id<VLCLocalNetworkServiceBrowser> _sapBrowser;
    id<VLCLocalNetworkServiceBrowser> _dsmBrowser;

    Reachability *_reachability;

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
    [_UPnPBrowser stopDiscovery];
    [_sapBrowser stopDiscovery];
    [_dsmBrowser stopDiscovery];

    [_FTPBrowser stopDiscovery];
    [_plexBrowser stopDiscovery];
    [_HTTPBrowser stopDiscovery];
}

- (void)startDiscovery
{
    if (_reachability.currentReachabilityStatus != ReachableViaWiFi) {
        return;
    }

    [_UPnPBrowser startDiscovery];
    [_sapBrowser startDiscovery];
    [_dsmBrowser startDiscovery];

    [_FTPBrowser startDiscovery];
    [_plexBrowser startDiscovery];
    [_HTTPBrowser startDiscovery];
}

- (NSArray *)sectionHeaderTexts
{
    return @[_manualConnectBrowser.name,
             _UPnPBrowser.name,
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

    _manualConnectBrowser = [[VLCLocalNetworkServiceBrowserManualConnect alloc] init];

    _plexBrowser = [[VLCLocalNetworkServiceBrowserPlex alloc] init];
    _plexBrowser.delegate = self;
    _FTPBrowser = [[VLCLocalNetworkServiceBrowserFTP alloc] init];
    _FTPBrowser.delegate = self;
    _HTTPBrowser = [[VLCLocalNetworkServiceBrowserHTTP alloc] init];
    _HTTPBrowser.delegate = self;

    _sapBrowser = [[VLCLocalNetworkServiceBrowserSAP alloc] init];
    _sapBrowser.delegate = self;

    _dsmBrowser = [[VLCLocalNetworkServiceBrowserDSM alloc] init];
    _dsmBrowser.delegate = self;

    _UPnPBrowser = [[VLCLocalNetworkServiceBrowserUPnP alloc] init];
    _UPnPBrowser.delegate = self;

    _reachability = [Reachability reachabilityForLocalWiFi];
    [_reachability startNotifier];

    [self netReachabilityChanged];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netReachabilityChanged) name:kReachabilityChangedNotification object:nil];

    return self;
}

- (void)netReachabilityChanged
{
    if (_reachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self startDiscovery];
    } else {
        [self stopDiscovery];
    }
}

#pragma mark - table view handling

- (id<VLCLocalNetworkService>)networkServiceForIndexPath:(NSIndexPath *)indexPath
{
    VLCLocalServerSections section = indexPath.section;
    NSUInteger row = indexPath.row;


    switch (section) {
        case VLCLocalServerSectionGeneric:
        {
            return [_manualConnectBrowser networkServiceForIndex:row];
        }

        case VLCLocalServerSectionUPnP:
        {
            return [_UPnPBrowser networkServiceForIndex:row];
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
            return _manualConnectBrowser.numberOfItems;

        case VLCLocalServerSectionUPnP:
            return _UPnPBrowser.numberOfItems;

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

    [self stopDiscovery];
    [self startDiscovery];

    return YES;
}

#pragma mark - VLCLocalNetworkServiceBrowserDelegate
- (void)localNetworkServiceBrowserDidUpdateServices:(id<VLCLocalNetworkServiceBrowser>)serviceBrowser {
    if ([self.delegate respondsToSelector:@selector(discoveryFoundSomethingNew)]) {
        [self.delegate discoveryFoundSomethingNew];
    }
}

@end
