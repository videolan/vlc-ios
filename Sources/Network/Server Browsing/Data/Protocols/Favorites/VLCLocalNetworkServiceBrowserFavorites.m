/*****************************************************************************
 * VLCLocalNetworkServiceBrowserFavorites.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceBrowserFavorites.h"
#import "VLCNetworkServerLoginInformation.h"

@interface VLCLocalNetworkServiceBrowserFavorites ()
@property (nonatomic, readonly) VLCLocalNetworkServiceItemFavorite *loginItem;
@end

@implementation VLCLocalNetworkServiceBrowserFavorites
@synthesize name = _name;
@synthesize delegate = _delegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _name = @"";
        _loginItem = [[VLCLocalNetworkServiceItemFavorite alloc] initWithServiceName:_name];
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


@interface VLCLocalNetworkServiceItemFavorite ()
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong, nullable) UIImage *icon;
@end

@implementation VLCLocalNetworkServiceItemFavorite
@synthesize serviceName = _serviceName;
- (instancetype)initWithTile:(NSString *)title icon:(UIImage *)icon serviceName:(NSString *)serviceName
{
    self = [super init];
    if (self) {
        _title = title;
        _icon = icon;
        _serviceName = serviceName;
    }
    return self;
}

- (instancetype)initWithServiceName:(NSString *)serviceName
{
    self = [self initWithTile:NSLocalizedString(@"FAVORITES", nil)
                         icon:[UIImage imageNamed:@"heart"]
                  serviceName:serviceName];
    if (self) {

    }
    return self;
}

- (VLCNetworkServerLoginInformation *)loginInformation
{
    VLCNetworkServerLoginInformation *login = [[VLCNetworkServerLoginInformation alloc] init];
    login.protocolIdentifier = @"favorites";
    return login;

}

@end
