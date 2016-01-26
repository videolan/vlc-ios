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
#import "SSKeychain.h"

@implementation VLCLocalNetworkServiceBrowserFTP
- (instancetype)init {
#if TARGET_OS_TV
    NSString *name = NSLocalizedString(@"FTP_SHORT",nil);
#else
    NSString *name = NSLocalizedString(@"FTP_LONG",nil);
#endif
    return [super initWithName:name
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
    login.port = [NSNumber numberWithInteger:self.netService.port];
    login.protocolIdentifier = VLCNetworkServerProtocolIdentifierFTP;

    NSString *serviceString = [NSString stringWithFormat:@"ftp://%@", login.address];
    NSArray *accounts = [SSKeychain accountsForService:serviceString];
    if (!accounts) {
        login.username = login.password = @"";
        return login;
    }

    NSDictionary *account = [accounts firstObject];
    NSString *username = [account objectForKey:@"acct"];
    login.username = username;
    login.password = [SSKeychain passwordForService:serviceString account:username];

    return login;
}
@end
