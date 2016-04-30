/*****************************************************************************
 * VLCLocalNetworkServiceBrowserNetService.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceBrowserNetService.h"

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

#pragma mark - NetService based implementation

@implementation VLCLocalNetworkServiceBrowserNetService
@synthesize name = _name;

- (instancetype)initWithName:(NSString *)name serviceType:(NSString *)serviceType domain:(NSString *)domain
{
    self = [super init];
    if (self) {
        _name = name;
        _serviceType = serviceType;
        _domain = domain;
        _netServiceBrowser = [[NSNetServiceBrowser alloc] init];
        _netServiceBrowser.delegate = self;
        _rawNetServices = [[NSMutableArray alloc] init];
        _resolvedLocalNetworkServices = [[NSMutableArray alloc] init];
    }
    return self;
}
- (instancetype)init {
    return [self initWithName:@"" serviceType:@"" domain:@""];
}

- (NSUInteger)numberOfItems {
    return self.resolvedLocalNetworkServices.count;
}
- (void)startDiscovery {
    if (self.isDiscovering) {
        return;
    }
    _discovering = YES;
    [self.netServiceBrowser searchForServicesOfType:self.serviceType inDomain:self.domain];
}
- (void)stopDiscovery {
    [self.netServiceBrowser stop];
    _discovering = NO;
}
- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    if (index < _resolvedLocalNetworkServices.count)
        return self.resolvedLocalNetworkServices[index];
    return nil;
}

#pragma mark - NSNetServiceBrowserDelegate
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    APLog(@"found bonjour service: %@ (%@)", service.name, service.type);
    [self.rawNetServices addObject:service];
    service.delegate = self;
    [service resolveWithTimeout:5.];
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(nonnull NSNetService *)service moreComing:(BOOL)moreComing {
    APLog(@"bonjour service disappeared: %@ (%i)", service.name, moreComing);
    [self.rawNetServices removeObject:service];
    [self.resolvedLocalNetworkServices vlc_removeServiceWithNetService:service];

    if (!moreComing) {
        [self.delegate localNetworkServiceBrowserDidUpdateServices:self];
    }
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *,NSNumber *> *)errorDict {
    APLog(@"bonjour service did not search: %@ %@", browser, errorDict);
}


#pragma mark - NSNetServiceDelegate
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    VLCLocalNetworkServiceNetService *localNetworkService = [self localServiceForNetService:sender];
    [self addResolvedLocalNetworkService:localNetworkService];
}
- (VLCLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService {
    return [[VLCLocalNetworkServiceNetService alloc] initWithNetService:netService serviceName:self.name];
}

#pragma mark -
- (void)addResolvedLocalNetworkService:(VLCLocalNetworkServiceNetService *)localNetworkService {
    if ([self.resolvedLocalNetworkServices vlc_indexOfServiceWithNetService:localNetworkService.netService] != NSNotFound) {
        return;
    }
    [self.resolvedLocalNetworkServices addObject:localNetworkService];
    [self.delegate localNetworkServiceBrowserDidUpdateServices:self];
}
@end
