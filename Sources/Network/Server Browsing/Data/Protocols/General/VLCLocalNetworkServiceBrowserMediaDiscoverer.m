/*****************************************************************************
 * VLCLocalNetworkServiceBrowserMediaDiscoverer.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2020-2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceBrowserMediaDiscoverer.h"
#import "VLCLocalNetworkServiceVLCMedia.h"
#import "VLCLocalNetworkServiceBrowserUPnP.h"
#import "VLCAppCoordinator.h"
#import "VLCHTTPUploaderController.h"

@interface VLCLocalNetworkServiceBrowserMediaDiscoverer () <VLCMediaDiscovererDelegate>
{
    VLCLibrary *_internalLibraryInstance;
    BOOL _isUPnPdiscoverer;
}
@property (nonatomic, readonly) NSString *serviceName;
@property (nonatomic, readwrite) VLCMediaDiscoverer* mediaDiscoverer;

@end

@implementation VLCLocalNetworkServiceBrowserMediaDiscoverer
@synthesize name = _name, delegate = _delegate;

- (instancetype)initWithName:(NSString *)name serviceServiceName:(NSString *)serviceName
{
    self = [super init];
    if (self) {
        _name = name;
        _serviceName = serviceName;

        /* special case for UPnP to allow custom SAT>IP channel lists
         * launching an extra libvlc instance just for this is expensive,
         * so it should be only if explicitly demanded by the user */
        _isUPnPdiscoverer = [serviceName isEqualToString:@"upnp"];
        if (_isUPnPdiscoverer) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *satipURLstring = [defaults stringForKey:kVLCSettingNetworkSatIPChannelListUrl];
            NSMutableArray *libVLCOptions = [NSMutableArray array];
            if (satipURLstring.length > 0) {
                [libVLCOptions addObject:[NSString stringWithFormat:@"--%@=%@", kVLCSettingNetworkSatIPChannelListUrl, satipURLstring]];
                [libVLCOptions addObject:[NSString stringWithFormat:@"--%@=%@", kVLCSettingNetworkSatIPChannelList, kVLCSettingNetworkSatIPChannelListCustom]];
            }
            NSString *multicastInterfaceName = [[[VLCAppCoordinator sharedInstance] httpUploaderController] nameOfUsedNetworkInterface];
            if (multicastInterfaceName.length > 0) {
                [libVLCOptions addObject:[NSString stringWithFormat:@"--miface=%@", multicastInterfaceName]];
            }
            if (libVLCOptions.count > 0) {
                _internalLibraryInstance = [[VLCLibrary alloc] initWithOptions:libVLCOptions];
            }
        }
    }
    return self;
}
- (instancetype)init {
    return [self initWithName:@"" serviceServiceName:@""];
}

- (void)startDiscovery
{
    // don't start discovery twice
    if (self.mediaDiscoverer) {
        return;
    }
    VLCMediaDiscoverer *discoverer;

    /* special case for UPnP to allow custom SAT>IP channel lists */
    if (_internalLibraryInstance && _isUPnPdiscoverer) {
        discoverer = [[VLCMediaDiscoverer alloc] initWithName:self.serviceName libraryInstance:_internalLibraryInstance];
    } else {
        discoverer = [[VLCMediaDiscoverer alloc] initWithName:self.serviceName];
    }

    self.mediaDiscoverer = discoverer;
#if MEDIA_DISCOVERY_DEBUG
    VLCConsoleLogger *consoleLogger = [[VLCConsoleLogger alloc] init];
    consoleLogger.level = kVLCLogLevelDebug;
    [self.mediaDiscoverer.libraryInstance setLoggers:@[consoleLogger]];
#endif
    [discoverer startDiscoverer];
    discoverer.delegate = self;
}

- (void)stopDiscovery
{
    /* the UPnP module is special and may not be terminated */
    if ([self.serviceName isEqualToString:@"upnp"]) {
        return;
    }
    VLCMediaDiscoverer *discoverer = self.mediaDiscoverer;
    discoverer.delegate = nil;
    [discoverer stopDiscoverer];
    self.mediaDiscoverer = nil;
}

- (NSUInteger)numberOfItems {
    return self.mediaDiscoverer.discoveredMedia.count;
}
- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    if (media)
        return [[VLCLocalNetworkServiceVLCMedia alloc] initWithMediaItem:media serviceName:self.serviceName];
    return nil;
}

#pragma mark - VLCMediaDiscovererDelegate
- (void)mediaAdded:(VLCMedia *)media parent:(VLCMedia *)parent
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate localNetworkServiceBrowserDidUpdateServices:self];
    });
}
- (void)mediaRemoved:(VLCMedia *)media
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate localNetworkServiceBrowserDidUpdateServices:self];
    });
}

@end
