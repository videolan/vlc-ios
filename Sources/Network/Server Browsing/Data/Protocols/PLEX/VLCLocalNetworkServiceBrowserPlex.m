/*****************************************************************************
 * VLCLocalNetworkServiceBrowserPlex.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2019, 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceBrowserPlex.h"
#import "VLCNetworkServerBrowserPlex.h"
#import <arpa/inet.h>

@implementation VLCLocalNetworkServiceBrowserPlex

- (instancetype)init
{
#if TARGET_OS_TV
    NSString *name = NSLocalizedString(@"PLEX_SHORT",nil);
#else
    NSString *name = NSLocalizedString(@"PLEX_LONG",nil);
#endif
    return [super initWithName:name
                   serviceType:@"_plexmediasvr._tcp."
                        domain:@""];
}

- (VLCLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService
{
    return [[VLCLocalNetworkServicePlex alloc] initWithNetService:netService serviceName:self.name];
}
@end

NSString *const VLCNetworkServerProtocolIdentifierPlex = @"plex";

@implementation VLCLocalNetworkServicePlex
- (UIImage *)icon
{
    return [UIImage imageNamed:@"PlexServerIcon"];
}
#if TARGET_OS_TV
- (nullable id<VLCNetworkServerLoginInformation>)loginInformation
{
    VLCNetworkServerLoginInformation *login = [[VLCNetworkServerLoginInformation alloc] init];
    login.address = self.netService.hostName;
    login.port = [NSNumber numberWithInteger:self.netService.port];
    login.protocolIdentifier = VLCNetworkServerProtocolIdentifierPlex;

    return login;
}
#else

static NSString * ipAddressAsStringForData(NSData * data)
{
    char addressBuffer[INET6_ADDRSTRLEN] = { 0 };
    NSString *returnValue = nil;

    if (data == nil) {
        return returnValue;
    }

    typedef union {
        struct sockaddr sa;
        struct sockaddr_in ipv4;
        struct sockaddr_in6 ipv6;
    } ip_socket_address;

    ip_socket_address *socketAddress = (ip_socket_address *)[data bytes];

    if (socketAddress) {
        const char *addressStr = NULL;
        if (socketAddress->sa.sa_family == AF_INET) {
            addressStr = inet_ntop(socketAddress->sa.sa_family,
                                           (void *)&(socketAddress->ipv4.sin_addr),
                                           addressBuffer,
                                           sizeof(addressBuffer));
        } else if (socketAddress->sa.sa_family == AF_INET6) {
            addressStr = inet_ntop(socketAddress->sa.sa_family,
                                           (void *)&(socketAddress->ipv6.sin6_addr),
                                           addressBuffer,
                                           sizeof(addressBuffer));
        }
        if (addressStr != NULL) {
            returnValue = [NSString stringWithUTF8String:addressStr];
        }
    }
    return returnValue;
}

- (id<VLCNetworkServerBrowser>)serverBrowser
{
    NSNetService *service = self.netService;
    if (service.hostName == nil || service.port == 0) {
        return nil;
    }

    NSString *name = service.name;
    NSUInteger portNum = service.port;

    VLCNetworkServerBrowserPlex *serverBrowser = [[VLCNetworkServerBrowserPlex alloc] initWithName:name host:ipAddressAsStringForData(service.addresses.firstObject)
                                                                                        portNumber:@(portNum)
                                                                                              path:@""
                                                                                authentificication:@""];

    return serverBrowser;
}
#endif

@end
