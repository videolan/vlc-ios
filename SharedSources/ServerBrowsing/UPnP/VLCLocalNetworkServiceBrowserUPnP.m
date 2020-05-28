/*****************************************************************************
 * VLCLocalNetworkServiceBrowserUPnP.m
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

#import "VLCLocalNetworkServiceBrowserUPnP.h"
#import "VLCNetworkServerLoginInformation.h"

@interface VLCLocalNetworkServiceUPnP ()
+ (void)registerLoginInformation;
@end

@implementation VLCLocalNetworkServiceBrowserUPnP

- (instancetype)init {
#if TARGET_OS_TV
    NSString *name = NSLocalizedString(@"UPNP_SHORT", nil);
#else
    NSString *name = NSLocalizedString(@"UPNP_LONG", nil);
#endif

    return [super initWithName:name
            serviceServiceName:@"upnp"];
}
- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    if (media)
        return [[VLCLocalNetworkServiceUPnP alloc] initWithMediaItem:media serviceName:self.name];
    return nil;
}

+ (void)initialize
{
    [super initialize];
    [VLCLocalNetworkServiceUPnP registerLoginInformation];
}

@end


NSString *const VLCNetworkServerProtocolIdentifierUPnP = @"upnp";

@implementation VLCLocalNetworkServiceUPnP

+ (void)registerLoginInformation
{
    VLCNetworkServerLoginInformation *login = [[VLCNetworkServerLoginInformation alloc] init];
    login.protocolIdentifier = VLCNetworkServerProtocolIdentifierUPnP;

    [VLCNetworkServerLoginInformation registerTemplateLoginInformation:login];
}

- (UIImage *)icon {
    return [UIImage imageNamed:@"serverIcon"];
}

- (VLCNetworkServerLoginInformation *)loginInformation {

    VLCMedia *media = self.mediaItem;
    if (media.mediaType != VLCMediaTypeDirectory)
        return nil;

    VLCNetworkServerLoginInformation *login = [VLCNetworkServerLoginInformation newLoginInformationForProtocol:VLCNetworkServerProtocolIdentifierUPnP];
    login.address = self.mediaItem.url.absoluteString;
    return login;
}

@end


@implementation VLCNetworkServerBrowserVLCMedia (UPnP)

+ (instancetype)UPnPNetworkServerBrowserWithLogin:(VLCNetworkServerLoginInformation *)login
{
    NSURL *url = [NSURL URLWithString:login.address];
    return [self UPnPNetworkServerBrowserWithURL:url];
}

+ (instancetype)UPnPNetworkServerBrowserWithURL:(NSURL *)url
{
	VLCMedia *media = [VLCMedia mediaWithURL:url];
	NSDictionary *mediaOptions = @{};
	return [[self alloc] initWithMedia:media options:mediaOptions];
}
@end
