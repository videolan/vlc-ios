/*****************************************************************************
 * VLCLocalNetworkServiceBrowserFTP.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceBrowserFTP.h"
#import "VLCNetworkServerLoginInformation.h"


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


NSString *const VLCNetworkServerProtocolIdentifierFTP = @"ftp";

@implementation VLCLocalNetworkServiceFTP
- (UIImage *)icon {
    return [UIImage imageNamed:@"serverIcon"];
}

- (nullable id<VLCNetworkServerLoginInformation>)loginInformation
{
    VLCNetworkServerLoginInformation *login = [[VLCNetworkServerLoginInformation alloc] init];
    login.address = self.netService.hostName;
    login.protocolIdentifier = VLCNetworkServerProtocolIdentifierFTP;
    return login;
}
@end