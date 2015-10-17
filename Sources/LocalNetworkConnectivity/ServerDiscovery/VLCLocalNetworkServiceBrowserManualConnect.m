/*****************************************************************************
 * VLCLocalNetworkServiceBrowserManualConnect.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceBrowserManualConnect.h"
#import "VLCLocalNetworkService.h"

@interface VLCLocalNetworkServiceBrowserManualConnect ()
@property (nonatomic, readonly) VLCLocalNetworkServiceItemLogin *loginItem;
@end

@implementation VLCLocalNetworkServiceBrowserManualConnect
@synthesize name = _name;
@synthesize delegate = _delegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _name = @"Generic";
        _loginItem = [[VLCLocalNetworkServiceItemLogin alloc] init];;
    }
    return self;
}
- (void)startDiscovery {

}
- (void)stopDiscovery {

}
- (NSUInteger)numberOfItems {
    return 1;
}
- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    return self.loginItem;
}
@end
