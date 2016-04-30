/*****************************************************************************
 * VLCLocalNetworkServiceNetService.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceNetService.h"


#pragma mark - NetService based services
@interface VLCLocalNetworkServiceNetService()
@property (nonatomic, strong) NSNetService *netService;
@end
@implementation VLCLocalNetworkServiceNetService
@synthesize serviceName = _serviceName;
- (instancetype)initWithNetService:(NSNetService *)service serviceName:(nonnull NSString *)serviceName
{
    self = [super init];
    if (self) {
        _netService = service;
        _serviceName = serviceName;
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
