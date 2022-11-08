/*****************************************************************************
 * VLCLocalNetworkServiceBrowserBonjour.m
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

#import "VLCLocalNetworkServiceBrowserBonjour.h"
#import "VLCNetworkServerLoginInformation.h"


@implementation VLCLocalNetworkServiceBrowserBonjour

- (instancetype)init
{
    NSString *name = NSLocalizedString(@"BONJOUR_FILE_SERVERS", nil);
    return [super initWithName:name serviceServiceName:@"bonjour"];
}

- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index
{
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    NSString *serviceName = [media.url.scheme uppercaseString];
    if (media)
        return [[VLCLocalNetworkServiceBonjour alloc] initWithMediaItem:media serviceName:serviceName];
    return nil;
}

@end

@implementation VLCLocalNetworkServiceBonjour

- (VLCNetworkServerLoginInformation *)loginInformation {
    VLCMedia *media = self.mediaItem;
    if (media.mediaType != VLCMediaTypeDirectory) {
        return nil;
    }

    VLCNetworkServerLoginInformation *login = [VLCNetworkServerLoginInformation newLoginInformationForProtocol:self.serviceName];
    login.address = self.mediaItem.url.host;
    return login;
}

@end
