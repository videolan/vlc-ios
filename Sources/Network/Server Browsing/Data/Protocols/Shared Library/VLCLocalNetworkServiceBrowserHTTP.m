/*****************************************************************************
 * VLCLocalNetworkServiceBrowserHTTP.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppCoordinator.h"
#import "VLCLocalNetworkServiceBrowserHTTP.h"
#import "VLCSharedLibraryParser.h"
#import "VLCHTTPUploaderController.h"
#import "VLCNetworkServerBrowserSharedLibrary.h"

#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if.h>
#import <netinet/in.h>
#import <sys/socket.h>

static BOOL SocketAddressHasIP(const struct sockaddr *socketaddress) {
    return socketaddress && (socketaddress->sa_family == AF_INET || socketaddress->sa_family == AF_INET6);
}

static BOOL SockaddrIPEqualIgnoringPort(const struct sockaddr *a, const struct sockaddr *b) {
    if (!SocketAddressHasIP(a) || !SocketAddressHasIP(b))
        return NO;

    if (a->sa_family != b->sa_family)
        return NO;

    if (a->sa_family == AF_INET) {
        const struct sockaddr_in *ia = (const struct sockaddr_in *)a;
        const struct sockaddr_in *ib = (const struct sockaddr_in *)b;
        // Compare only IPv4 address (ignore port)
        return (ia->sin_addr.s_addr == ib->sin_addr.s_addr);
    } else { // AF_INET6
        const struct sockaddr_in6 *ia6 = (const struct sockaddr_in6 *)a;
        const struct sockaddr_in6 *ib6 = (const struct sockaddr_in6 *)b;
        // Compare only IPv6 address (ignore port)
        return (memcmp(&ia6->sin6_addr, &ib6->sin6_addr, sizeof(struct in6_addr)) == 0);
    }
}

static NSArray<NSData *> *LocalInterfaceSocketAddresses(void) {
    NSMutableArray<NSData *> *ret = [NSMutableArray array];

    struct ifaddrs *ifaddr = NULL;
    if (getifaddrs(&ifaddr) != 0 || !ifaddr) {
        return ret;
    }

    for (struct ifaddrs *ifa = ifaddr; ifa; ifa = ifa->ifa_next) {
        if (!ifa->ifa_addr)
            continue;

        if ((ifa->ifa_flags & IFF_UP) == 0)
            continue;

        if (ifa->ifa_flags & IFF_LOOPBACK)
            continue;

        const struct sockaddr *sa = ifa->ifa_addr;
        if (!SocketAddressHasIP(sa))
            continue;

        if (sa->sa_family == AF_INET) {
            [ret addObject:[NSData dataWithBytes:sa length:sizeof(struct sockaddr_in)]];
        } else if (sa->sa_family == AF_INET6) {
            [ret addObject:[NSData dataWithBytes:sa length:sizeof(struct sockaddr_in6)]];
        }
    }

    freeifaddrs(ifaddr);
    return ret;
}

@interface VLCLocalNetworkServiceBrowserHTTP()
@property (nonatomic, strong) VLCSharedLibraryParser *httpParser;
@end
@implementation VLCLocalNetworkServiceBrowserHTTP
- (instancetype)init {
    return [super initWithName:NSLocalizedString(@"SHARED_VLC_IOS_LIBRARY", nil)
                   serviceType:@"_http._tcp."
                        domain:@""];
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
#if !TARGET_OS_TV
    if (!sender)
        return;

    NSArray<NSData *> *serviceAddrs = sender.addresses;
    if (serviceAddrs.count == 0)
        return;

    NSArray<NSData *> *localAddrs = LocalInterfaceSocketAddresses();
    if (localAddrs.count == 0)
        return;

    for (NSData *sData in serviceAddrs) {
        const struct sockaddr *sSa = (const struct sockaddr *)sData.bytes;
        if (!SocketAddressHasIP(sSa))
            continue;

        for (NSData *lData in localAddrs) {
            const struct sockaddr *lSa = (const struct sockaddr *)lData.bytes;
            if (SockaddrIPEqualIgnoringPort(sSa, lSa)) {
                return;
            }
        }
    }
#endif
    [self.httpParser checkNetserviceForVLCService:sender];
}

- (void)sharedLibraryFound:(NSNotification *)aNotification {
    NSNetService *netService = [aNotification.userInfo objectForKey:@"aNetService"];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self addResolvedLocalNetworkService:[self localServiceForNetService:netService]];
    }];
}

- (VLCLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService {
    return [[VLCLocalNetworkServiceHTTP alloc] initWithNetService:netService serviceName:self.name];
}
@end



@implementation VLCLocalNetworkServiceHTTP

- (UIImage *)icon {
    return [UIImage imageNamed:@"WifiIcon"];
}

- (id<VLCNetworkServerBrowser>)serverBrowser {

    NSNetService *service = self.netService;
    if (service.hostName == nil || service.port == 0) {
        return nil;
    }

    NSString *name = service.name;
    NSString *hostName = service.hostName;
    NSUInteger portNum = service.port;
    VLCNetworkServerBrowserSharedLibrary *serverBrowser = [[VLCNetworkServerBrowserSharedLibrary alloc] initWithName:name host:hostName portNumber:portNum];
    return serverBrowser;
}

@end
