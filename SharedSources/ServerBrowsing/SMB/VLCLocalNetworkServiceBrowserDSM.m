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
    return [super initWithName:NSLocalizedString(@"SMB_CIFS_FILE_SERVERS", nil)
            serviceServiceName:@"dsm"];
}
- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    return [[VLCLocalNetworkServiceDSM alloc] initWithMediaItem:media];
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
+ (instancetype)SMBNetworkServerBrowserWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password workgroup:(NSString *)workgroup {

	VLCMedia *media = [VLCMedia mediaWithURL:url];
	NSDictionary *mediaOptions = @{@"smb-user" : username ?: @"",
								   @"smb-pwd" : password ?: @"",
								   @"smb-domain" : workgroup?: @"WORKGROUP"};
	[media addOptions:mediaOptions];
	return [[self alloc] initWithMedia:media options:mediaOptions];
}
@end