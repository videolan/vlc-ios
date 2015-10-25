/*****************************************************************************
 * VLCLocalNetworkService.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkService.h"

@implementation VLCNetworkServerLoginInformation

@end

@interface VLCLocalNetworkServiceItem ()
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong, nullable) UIImage *icon;
@end

@implementation VLCLocalNetworkServiceItem
- (instancetype)initWithTile:(NSString *)title icon:(UIImage *)icon
{
    self = [super init];
    if (self) {
        _title = title;
        _icon = icon;
    }
    return self;
}
@end

@implementation VLCLocalNetworkServiceItemLogin

- (instancetype)init
{
    self = [super initWithTile:NSLocalizedString(@"CONNECT_TO_SERVER", nil)
                          icon:[UIImage imageNamed:@"menuCone"]];
    if (self) {

    }
    return self;
}


- (VLCNetworkServerLoginInformation *)loginInformation {
    return [[VLCNetworkServerLoginInformation alloc] init];
}

@end


#pragma mark - NetService based services
@interface VLCLocalNetworkServiceNetService()
@property (nonatomic, strong) NSNetService *netService;
@end
@implementation VLCLocalNetworkServiceNetService

- (instancetype)initWithNetService:(NSNetService *)service
{
    self = [super init];
    if (self) {
        _netService = service;
    }
    return self;
}

- (NSString *)title {
    return self.netService.name;
}
- (UIImage *)icon {
    return nil;
}
- (id<VLCNetworkServerBrowser>)serverBrowser {
    return nil;
}
@end

#import "VLCNetworkServerBrowserPlex.h"
NSString *const VLCNetworkServerProtocolIdentifierPlex = @"plex";

@implementation VLCLocalNetworkServicePlex
- (UIImage *)icon {
    return [UIImage imageNamed:@"PlexServerIcon"];
}
- (id<VLCNetworkServerBrowser>)serverBrowser {

    NSNetService *service = self.netService;
    if (service.hostName == nil || service.port == 0) {
        return nil;
    }

    NSString *name = service.name;
    NSString *hostName = service.hostName;
    NSUInteger portNum = service.port;
    VLCNetworkServerBrowserPlex *serverBrowser = [[VLCNetworkServerBrowserPlex alloc] initWithName:name host:hostName portNumber:@(portNum) path:@"" authentificication:@""];

    return serverBrowser;
}
@end

NSString *const VLCNetworkServerProtocolIdentifierFTP = @"ftp";

@implementation VLCLocalNetworkServiceFTP
- (UIImage *)icon {
    return [UIImage imageNamed:@"serverIcon"];
}

- (VLCNetworkServerLoginInformation *)loginInformation
{
    VLCNetworkServerLoginInformation *login = [[VLCNetworkServerLoginInformation alloc] init];
    login.address = self.netService.hostName;
    login.protocolIdentifier = VLCNetworkServerProtocolIdentifierFTP;
    return login;
}
@end

#import "VLCNetworkServerBrowserSharedLibrary.h"
@implementation VLCLocalNetworkServiceHTTP
- (UIImage *)icon {
    return [UIImage imageNamed:@"menuCone"];
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

#pragma mark - VLCMedia based services
@interface VLCLocalNetworkServiceVLCMedia()
@property (nonatomic, strong) VLCMedia *mediaItem;
@end
@implementation VLCLocalNetworkServiceVLCMedia
- (instancetype)initWithMediaItem:(VLCMedia *)mediaItem
{
    self = [super init];
    if (self) {
        _mediaItem = mediaItem;
    }
    return self;
}
- (NSString *)title {
    return [self.mediaItem metadataForKey:VLCMetaInformationTitle];
}
- (UIImage *)icon {
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

#import "VLCPlaybackController.h"
@implementation VLCLocalNetworkServiceSAP
- (UIImage *)icon {
    return [UIImage imageNamed:@"TVBroadcastIcon"];
}
- (NSURL *)directPlaybackURL {

    VLCMediaType mediaType = self.mediaItem.mediaType;
    if (mediaType != VLCMediaTypeDirectory && mediaType != VLCMediaTypeDisc) {
        return [self.mediaItem url];
    }
    return nil;
}

@end

#pragma mark - UPnP
#import "UPnPManager.h"
#import "VLCNetworkServerBrowserUPnP.h"

@interface VLCLocalNetworkServiceUPnP ()
@property (nonatomic, strong) BasicUPnPDevice *device;
@end

@implementation VLCLocalNetworkServiceUPnP

- (instancetype)initWithUPnPDevice:(BasicUPnPDevice *)device
{
    self = [super init];
    if (self) {
        _device = device;
    }
    return self;
}

- (NSString *)title {
    return [self.device friendlyName];
}
- (UIImage *)icon {
    return [self.device smallIcon] ?: [UIImage imageNamed:@"serverIcon"];
}
- (id<VLCNetworkServerBrowser>)serverBrowser {

    BasicUPnPDevice *device = self.device;
    if ([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"]) {
        MediaServer1Device *server = (MediaServer1Device*)device;
        VLCNetworkServerBrowserUPnP *serverBrowser = [[VLCNetworkServerBrowserUPnP alloc] initWithUPNPDevice:server header:[device friendlyName] andRootID:@"0"];

        return serverBrowser;
    }
    return nil;
}
@end

