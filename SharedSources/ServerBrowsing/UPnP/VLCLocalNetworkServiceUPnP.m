/*****************************************************************************
 * VLCLocalNetworkServiceUPnP.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceUPnP.h"

#pragma mark - UPnP
#import "UPnPManager.h"
#import "VLCNetworkServerBrowserUPnP.h"

@interface VLCLocalNetworkServiceUPnP ()
@property (nonatomic, strong) BasicUPnPDevice *device;
@end

@implementation VLCLocalNetworkServiceUPnP
@synthesize serviceName = _serviceName;
- (instancetype)initWithUPnPDevice:(BasicUPnPDevice *)device serviceName:(NSString *)serviceName
{
    self = [super init];
    if (self) {
        _device = device;
        _serviceName = serviceName;
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

