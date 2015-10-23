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

#import "VLCNetworkLoginViewController.h"

@implementation VLCLocalNetworkServiceItemLogin

- (instancetype)init
{
    self = [super initWithTile:NSLocalizedString(@"CONNECT_TO_SERVER", nil)
                          icon:[UIImage imageNamed:@"menuCone"]];
    if (self) {

    }
    return self;
}

- (UIViewController *)detailViewController {
    VLCNetworkLoginViewController *loginViewController = [[VLCNetworkLoginViewController alloc] initWithNibName:@"VLCNetworkLoginViewController" bundle:nil];
    loginViewController.serverProtocol = VLCServerProtocolUndefined;
    return loginViewController;
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
- (UIViewController *)detailViewController {
    return nil;
}
@end

#import "VLCLocalPlexFolderListViewController.h"
@implementation VLCLocalNetworkServicePlex
- (UIImage *)icon {
    return [UIImage imageNamed:@"PlexServerIcon"];
}
- (UIViewController *)detailViewController {

    NSNetService *service = self.netService;
    if (service.hostName == nil || service.port == 0) {
        return nil;
    }

    NSString *name = service.name;
    NSString *hostName = service.hostName;
    NSString *portNum = [[NSString alloc] initWithFormat:@":%ld", (long)service.port];
    VLCLocalPlexFolderListViewController *targetViewController = [[VLCLocalPlexFolderListViewController alloc] initWithPlexServer:name serverAddress:hostName portNumber:portNum atPath:@"" authentification:@""];
    return targetViewController;
}
@end

@implementation VLCLocalNetworkServiceFTP
- (UIImage *)icon {
    return [UIImage imageNamed:@"serverIcon"];
}
- (UIViewController *)detailViewController {
    VLCNetworkLoginViewController *loginViewController = [[VLCNetworkLoginViewController alloc] initWithNibName:@"VLCNetworkLoginViewController" bundle:nil];
    loginViewController.serverProtocol = VLCServerProtocolFTP;
    loginViewController.hostname = self.netService.hostName;
    return loginViewController;
}
@end

#import "VLCSharedLibraryListViewController.h"
@implementation VLCLocalNetworkServiceHTTP
- (UIImage *)icon {
    return [UIImage imageNamed:@"menuCone"];
}
- (UIViewController *)detailViewController {

    NSNetService *service = self.netService;
    if (service.hostName == nil || service.port == 0) {
        return nil;
    }

    NSString *name = service.name;
    NSString *hostName = service.hostName;
    NSUInteger portNum = service.port;
    VLCSharedLibraryListViewController *targetViewController = [[VLCSharedLibraryListViewController alloc]
                                                                initWithHttpServer:name
                                                                serverAddress:hostName
                                                                portNumber:portNum];
    return targetViewController;
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

@implementation VLCLocalNetworkServiceDSM
- (UIImage *)icon {
    return [UIImage imageNamed:@"serverIcon"];
}
- (UIViewController *)detailViewController {
    VLCMedia *media = self.mediaItem;
    if (media.mediaType != VLCMediaTypeDirectory)
        return nil;

    VLCNetworkLoginViewController *loginViewController = [[VLCNetworkLoginViewController alloc] initWithNibName:@"VLCNetworkLoginViewController" bundle:nil];
    loginViewController.serverProtocol = VLCServerProtocolSMB;
    loginViewController.hostname = self.mediaItem.url.host;
    return loginViewController;
}

@end

#import "VLCPlaybackController.h"
@implementation VLCLocalNetworkServiceSAP
- (UIImage *)icon {
    return [UIImage imageNamed:@"TVBroadcastIcon"];
}
- (VLCLocalNetworkServiceActionBlock)action {
    __weak typeof(self) weakSelf = self;
    return ^{
        VLCMedia *cellMedia = weakSelf.mediaItem;

        VLCMediaType mediaType = cellMedia.mediaType;
        if (cellMedia && mediaType != VLCMediaTypeDirectory && mediaType != VLCMediaTypeDisc) {
            VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
            [vpc playURL:[cellMedia url] successCallback:nil errorCallback:nil];
        }
    };
}

@end

#pragma mark - UPnP
#import "UPnPManager.h"
#import "VLCUPnPServerListViewController.h"

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
- (UIViewController *)detailViewController {

    BasicUPnPDevice *device = self.device;
    if (device != nil) {
        if ([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"]) {
            MediaServer1Device *server = (MediaServer1Device*)device;
            VLCUPnPServerListViewController *targetViewController = [[VLCUPnPServerListViewController alloc] initWithUPNPDevice:server header:[device friendlyName] andRootID:@"0"];
            return targetViewController;
        }
    }
    return nil;
}

@end

