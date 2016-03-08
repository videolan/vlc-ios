/*****************************************************************************
 * VLCLocalNetworkServiceBrowserDSM.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceBrowserDSM.h"
#import "VLCNetworkServerLoginInformation.h"


@implementation VLCLocalNetworkServiceBrowserDSM

- (instancetype)init {
#if TARGET_OS_TV
    NSString *name = NSLocalizedString(@"SMB_CIFS_FILE_SERVERS_SHORT", nil);
#else
    NSString *name = NSLocalizedString(@"SMB_CIFS_FILE_SERVERS", nil);
#endif

    return [super initWithName:name
            serviceServiceName:@"dsm"];
}
- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    if (media)
        return [[VLCLocalNetworkServiceDSM alloc] initWithMediaItem:media];
    return nil;
}

@end


NSString *const VLCNetworkServerProtocolIdentifierSMB = @"smb";
@implementation VLCLocalNetworkServiceDSM
- (UIImage *)icon {
    return [UIImage imageNamed:@"serverIcon"];
}
- (VLCNetworkServerLoginInformation *)loginInformation {

    VLCMedia *media = self.mediaItem;
    if (media.mediaType != VLCMediaTypeDirectory)
        return nil;

    VLCNetworkServerLoginInformation *login = [[VLCNetworkServerLoginInformation alloc] init];
    login.address = self.mediaItem.url.host;
    login.protocolIdentifier = VLCNetworkServerProtocolIdentifierSMB;

    return login;
}

@end


@implementation VLCNetworkServerBrowserVLCMedia (SMB)

+ (instancetype)SMBNetworkServerBrowserWithLogin:(VLCNetworkServerLoginInformation *)login
{
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = @"smb";
    components.host = login.address;
    components.port = login.port;
    NSURL *url = components.URL;
    return [self SMBNetworkServerBrowserWithURL:url
                                       username:login.username
                                       password:login.password
                                      workgroup:nil];
}


+ (instancetype)SMBNetworkServerBrowserWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password workgroup:(NSString *)workgroup
{
	VLCMedia *media = [VLCMedia mediaWithURL:url];
	NSDictionary *mediaOptions = @{@"smb-user" : username ?: @"",
								   @"smb-pwd" : password ?: @"",
								   @"smb-domain" : workgroup?: @"WORKGROUP"};
	[media addOptions:mediaOptions];
	return [[self alloc] initWithMedia:media options:mediaOptions];
}
@end