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
@property (readwrite) VLCMediaDiscoverer* mediaDiscoverer;

@end

static dispatch_queue_t VLCMediaDiscoveryQueue(void)
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,
                                                                                  QOS_CLASS_UTILITY, 0);
        queue = dispatch_queue_create("org.videolan.vlc-ios.media-discovery", attributes);
    });
    return queue;
}

@implementation VLCLocalNetworkServiceBrowserMediaDiscoverer
@synthesize name = _name, delegate = _delegate;

- (instancetype)initWithName:(NSString *)name serviceServiceName:(NSString *)serviceName
{
    self = [super init];
    if (self) {
        _name = name;
        _serviceName = serviceName;
        _isUPnPdiscoverer = [serviceName isEqualToString:@"upnp"];
    }
    return self;
}
- (instancetype)init {
    return [self initWithName:@"" serviceServiceName:@""];
}

/* special case for UPnP to allow custom SAT>IP channel lists
 * launching an extra libvlc instance just for this is expensive,
 * so it should be only if explicitly demanded by the user */
- (NSArray<NSString *> *)libVLCOptionsForUPnP
{
    NSMutableArray *libVLCOptions = [NSMutableArray array];
    NSString *satipURLstring = [[NSUserDefaults standardUserDefaults] stringForKey:kVLCSettingNetworkSatIPChannelListUrl];
    if (satipURLstring.length > 0) {
        [libVLCOptions addObject:[NSString stringWithFormat:@"--%@=%@", kVLCSettingNetworkSatIPChannelListUrl, satipURLstring]];
        [libVLCOptions addObject:[NSString stringWithFormat:@"--%@=%@", kVLCSettingNetworkSatIPChannelList, kVLCSettingNetworkSatIPChannelListCustom]];
    }
    NSString *multicastInterfaceName = [[[VLCAppCoordinator sharedInstance] httpUploaderController] nameOfUsedNetworkInterface];
    if (multicastInterfaceName.length > 0) {
        [libVLCOptions addObject:[NSString stringWithFormat:@"--miface=%@", multicastInterfaceName]];
    }
    return libVLCOptions;
}

- (void)startDiscovery
{
    NSArray<NSString *> *libVLCOptions = _isUPnPdiscoverer ? [self libVLCOptionsForUPnP] : nil;

    dispatch_async(VLCMediaDiscoveryQueue(), ^{
        // don't start discovery twice
        if (self.mediaDiscoverer) {
            return;
        }

        if (libVLCOptions.count > 0 && !self->_internalLibraryInstance) {
            self->_internalLibraryInstance = [[VLCLibrary alloc] initWithOptions:libVLCOptions];
        }

        VLCMediaDiscoverer *discoverer;
        if (self->_internalLibraryInstance) {
            discoverer = [[VLCMediaDiscoverer alloc] initWithName:self->_serviceName
                                                  libraryInstance:self->_internalLibraryInstance];
        } else {
            discoverer = [[VLCMediaDiscoverer alloc] initWithName:self->_serviceName];
        }

        self.mediaDiscoverer = discoverer;
#if MEDIA_DISCOVERY_DEBUG
        VLCConsoleLogger *consoleLogger = [[VLCConsoleLogger alloc] init];
        consoleLogger.level = kVLCLogLevelDebug;
        [discoverer.libraryInstance setLoggers:@[consoleLogger]];
#endif
        [discoverer startDiscoverer];
        discoverer.delegate = self;
    });
}

- (void)stopDiscovery
{
    /* the UPnP module is special and may not be terminated */
    if (_isUPnPdiscoverer) {
        return;
    }

    dispatch_async(VLCMediaDiscoveryQueue(), ^{
        VLCMediaDiscoverer *discoverer = self.mediaDiscoverer;
        discoverer.delegate = nil;
        self.mediaDiscoverer = nil;
        [discoverer stopDiscoverer];
    });
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
