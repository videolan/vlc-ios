/*****************************************************************************
 * VLCLocalNetworkServiceBrowserBonjour.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
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

    self.mediaDiscoverer.libraryInstance.debugLogging = YES;

    return [super initWithName:name serviceServiceName:@"bonjour"];
}

- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index
{
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    NSString *serviceName = media.url.scheme;
    if (media)
        return [[VLCLocalNetworkServiceBonjour alloc] initWithMediaItem:media serviceName:serviceName];
    return nil;
}

@end

NSString *const VLCNetworkServerProtocolIdentifierBonjour = @"Bonjour";

@implementation VLCLocalNetworkServiceBonjour

- (UIImage *)icon
{
    return [UIImage imageNamed:@"serverIcon"];
}

@end
