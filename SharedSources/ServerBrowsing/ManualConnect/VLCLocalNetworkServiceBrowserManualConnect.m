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
#import "VLCNetworkServerLoginInformation.h"

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


@interface VLCLocalNetworkServiceItemLogin ()
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong, nullable) UIImage *icon;
@end

@implementation VLCLocalNetworkServiceItemLogin
- (instancetype)initWithTile:(NSString *)title icon:(UIImage *)icon
{
    self = [super init];
    if (self) {
        _title = title;
        _icon = icon;
    }
    return self;
}

- (instancetype)init
{
    self = [self initWithTile:NSLocalizedString(@"CONNECT_TO_SERVER", nil)
                         icon:[UIImage imageNamed:@"vlc-sharing"]];
    if (self) {

    }
    return self;
}

- (VLCNetworkServerLoginInformation *)loginInformation
{
    return [[VLCNetworkServerLoginInformation alloc] init];
}

@end
