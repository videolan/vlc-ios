/*****************************************************************************
 * VLCLocalNetworkServiceBrowserUPnP.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2020, 2026 VideoLAN. All rights reserved.
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
@property (nonatomic) VLCLibrary *libraryInstance;
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
    if (media) {
        VLCLocalNetworkServiceUPnP *service = [[VLCLocalNetworkServiceUPnP alloc] initWithMediaItem:media
                                                                                        serviceName:[self.name uppercaseString]];
        service.libraryInstance = self.mediaDiscoverer.libraryInstance;
        return service;
    }
    return nil;
}

+ (void)initialize
{
    [super initialize];
    [VLCLocalNetworkServiceUPnP registerLoginInformation];
}

@end


NSString *const VLCNetworkServerProtocolIdentifierUPnP = @"UPNP";

@implementation VLCLocalNetworkServiceUPnP

+ (void)registerLoginInformation
{
    VLCNetworkServerLoginInformation *login = [[VLCNetworkServerLoginInformation alloc] init];
    login.protocolIdentifier = VLCNetworkServerProtocolIdentifierUPnP;

    [VLCNetworkServerLoginInformation registerTemplateLoginInformation:login];
}

- (VLCNetworkServerLoginInformation *)loginInformation {

    VLCMedia *media = self.mediaItem;
    if (media.mediaType != VLCMediaTypeDirectory)
        return nil;

    VLCNetworkServerLoginInformation *login = [VLCNetworkServerLoginInformation newLoginInformationForProtocol:VLCNetworkServerProtocolIdentifierUPnP];
    login.address = self.mediaItem.url.absoluteString;
    login.rootMedia = media;

    /* SAT>IP needs the host address of the UPnP server set as an option as
     * when using a generic playlist, the host address will be 'sat.ip' and
     * playback will fail.
     * According to section 3.4.1 of the SAT>IP specification, it is
     * required to provide an icon for a SAT>IP server via UPnP, so it is
     * safe to query for the actual host address as the media's URL will
     * point to the generic playlist. */
    NSURL *url = media.metaData.artworkURL;

    NSString *host = url.host;

    if (host) {
        NSDictionary *dict = @{ @"satip-host" : host };
        login.options = dict;
    }

    return login;
}

- (id<VLCNetworkServerBrowser>)serverBrowser
{
    VLCMedia *media = self.mediaItem;
    if (media.mediaType != VLCMediaTypeDirectory)
        return nil;

    NSDictionary *options = @{};
    NSString *host = media.metaData.artworkURL.host;
    if (host) {
        options = @{ @"satip-host" : host };
    }

    /* the discovered media belongs to the discoverer's library instance, so it
     * needs to be parsed by a parser bound to that same instance */
    VLCMediaParser *parser = self.libraryInstance ? [[VLCMediaParser alloc] initWithLibrary:self.libraryInstance timeout:-1] : nil;
    return [[VLCNetworkServerBrowserVLCMedia alloc] initWithMedia:media options:options mediaParser:parser];
}

@end


@implementation VLCNetworkServerBrowserVLCMedia (UPnP)

+ (instancetype)UPnPNetworkServerBrowserWithLogin:(VLCNetworkServerLoginInformation *)login
{
    NSURL *url = [NSURL URLWithString:login.address];
    NSDictionary *options = login.options;
    if (!options) {
        options = @{};
    }
    return [self UPnPNetworkServerBrowserWithURL:url options:options];
}

+ (instancetype)UPnPNetworkServerBrowserWithURL:(NSURL *)url options:(NSDictionary *)mediaOptions
{
	VLCMedia *media = [VLCMedia mediaWithURL:url];
	return [[self alloc] initWithMedia:media options:mediaOptions];
}
@end
