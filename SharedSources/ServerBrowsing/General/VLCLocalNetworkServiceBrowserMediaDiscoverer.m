/*****************************************************************************
 * VLCLocalNetworkServiceBrowserMediaDiscoverer.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2020 VideoLAN. All rights reserved.
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

@interface VLCLocalNetworkServiceBrowserMediaDiscoverer () <VLCMediaListDelegate>
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
    VLCMediaDiscoverer *discoverer = [[VLCMediaDiscoverer alloc] initWithName:self.serviceName];
    self.mediaDiscoverer = discoverer;
    /* enable this boolean to debug the discovery session
     * note that this will not necessarily enable debug for playback
     * self.mediaDiscoverer.libraryInstance.debugLogging = YES;
     * self.mediaDiscoverer.libraryInstance.debugLoggingLevel = 4; */
    [discoverer startDiscoverer];
    discoverer.discoveredMedia.delegate = self;
}

- (void)stopDiscovery
{
    /* the UPnP module is special and may not be terminated */
    if ([self.serviceName isEqualToString:VLCNetworkServerProtocolIdentifierUPnP]) {
        return;
    }
    VLCMediaDiscoverer *discoverer = self.mediaDiscoverer;
    discoverer.discoveredMedia.delegate = nil;
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

#pragma mark - VLCMediaListDelegate
- (void)mediaList:(VLCMediaList *)aMediaList mediaAdded:(VLCMedia *)media atIndex:(NSUInteger)index
{
    [self.delegate localNetworkServiceBrowserDidUpdateServices:self];
}
- (void)mediaList:(VLCMediaList *)aMediaList mediaRemovedAtIndex:(NSUInteger)index
{
    [self.delegate localNetworkServiceBrowserDidUpdateServices:self];
}

@end
