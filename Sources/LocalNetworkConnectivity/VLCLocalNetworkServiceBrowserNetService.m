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
    [self.netServiceBrowser searchForServicesOfType:self.serviceType inDomain:self.domain];
}
- (void)stopDiscovery {
    [self.netServiceBrowser stop];
}
- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    return self.resolvedLocalNetworkServices[index];
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

#pragma mark - NSNetServiceDelegate
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    VLCLocalNetworkServiceNetService *localNetworkService = [self localServiceForNetService:sender];
    [self addResolvedLocalNetworkService:localNetworkService];
}
- (VLCLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService {
    return [[VLCLocalNetworkServiceNetService alloc] initWithNetService:netService];
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

#pragma mark - service specific subclasses

@implementation VLCLocalNetworkServiceBrowserFTP
- (instancetype)init {
    return [super initWithName:@"File Transfer Protocol (FTP)"
                   serviceType:@"_ftp._tcp."
                        domain:@""];
}
- (VLCLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService {
    return [[VLCLocalNetworkServiceFTP alloc] initWithNetService:netService];
}
@end

@implementation VLCLocalNetworkServiceBrowserPlex
- (instancetype)init {
    return [super initWithName:@"Plex Media Server (via Bonjour)"
                   serviceType:@"_plexmediasvr._tcp."
                        domain:@""];
}
- (VLCLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService {
    return [[VLCLocalNetworkServicePlex alloc] initWithNetService:netService];
}
@end

#import "VLCSharedLibraryParser.h"
@interface VLCLocalNetworkServiceBrowserHTTP()
@property (nonatomic) VLCSharedLibraryParser *httpParser;
@end
@implementation VLCLocalNetworkServiceBrowserHTTP
- (instancetype)init {
    return [super initWithName:NSLocalizedString(@"SHARED_VLC_IOS_LIBRARY", nil)
                   serviceType:@"_http._tcp."
                        domain:@""];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (VLCSharedLibraryParser *)httpParser {
    if (!_httpParser) {
        _httpParser = [[VLCSharedLibraryParser alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sharedLibraryFound:)
                                                     name:VLCSharedLibraryParserDeterminedNetserviceAsVLCInstance
                                                   object:_httpParser];
    }
    return _httpParser;
}
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    [self.httpParser checkNetserviceForVLCService:sender];
}

- (void)sharedLibraryFound:(NSNotification *)aNotification {
    NSNetService *netService = [aNotification.userInfo objectForKey:@"aNetService"];
    [self addResolvedLocalNetworkService:[self localServiceForNetService:netService]];
}

- (VLCLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService {
    return [[VLCLocalNetworkServiceHTTP alloc] initWithNetService:netService];
}
@end
