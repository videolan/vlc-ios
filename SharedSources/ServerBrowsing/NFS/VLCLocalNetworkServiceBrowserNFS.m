/*****************************************************************************
 * VLCLocalNetworkServiceBrowserNFS.m
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

#import "VLCLocalNetworkServiceBrowserNFS.h"
#import "VLCNetworkServerLoginInformation.h"

@interface VLCLocalNetworkServiceNFS ()
+ (void)registerLoginInformation;
@end

@implementation VLCLocalNetworkServiceBrowserNFS

- (instancetype)init {
#if TARGET_OS_TV
    NSString *name = NSLocalizedString(@"NFS_SHORT", nil);
#else
    NSString *name = NSLocalizedString(@"NFS_LONG", nil);
#endif

    return [super initWithName:name
            serviceServiceName:@"nfs"];
}
- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    if (media)
        return [[VLCLocalNetworkServiceNFS alloc] initWithMediaItem:media serviceName:self.name];
    return nil;
}

+ (void)initialize
{
    [super initialize];
    [VLCLocalNetworkServiceNFS registerLoginInformation];
}

@end


NSString *const VLCNetworkServerProtocolIdentifierNFS = @"nfs";

@implementation VLCLocalNetworkServiceNFS

+ (void)registerLoginInformation
{
    VLCNetworkServerLoginInformation *login = [[VLCNetworkServerLoginInformation alloc] init];
    login.protocolIdentifier = VLCNetworkServerProtocolIdentifierNFS;

    [VLCNetworkServerLoginInformation registerTemplateLoginInformation:login];
}

- (VLCNetworkServerLoginInformation *)loginInformation {
    VLCMedia *media = self.mediaItem;
    if (media.mediaType != VLCMediaTypeDirectory) {
        return nil;
    }

    VLCNetworkServerLoginInformation *login = [VLCNetworkServerLoginInformation newLoginInformationForProtocol:VLCNetworkServerProtocolIdentifierNFS];
    login.address = self.mediaItem.url.host;
    return login;
}

@end


@implementation VLCNetworkServerBrowserVLCMedia (NFS)

+ (instancetype)NFSNetworkServerBrowserWithLogin:(VLCNetworkServerLoginInformation *)login
{
    NSString *path = [NSString stringWithFormat:@"//%@", login.address];
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:path];
    components.scheme = @"nfs";
    components.port = login.port;
    NSURL *url = components.URL;

    return [self NFSNetworkServerBrowserWithURL:url];
}

+ (instancetype)NFSNetworkServerBrowserWithURL:(NSURL *)url
{
	VLCMedia *media = [VLCMedia mediaWithURL:url];
	return [[self alloc] initWithMedia:media options:[NSDictionary dictionary]];
}
@end
