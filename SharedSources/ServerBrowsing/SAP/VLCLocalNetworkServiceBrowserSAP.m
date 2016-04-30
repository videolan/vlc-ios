/*****************************************************************************
 * VLCLocalNetworkServiceBrowserMediaDiscoverer.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import "VLCLocalNetworkServiceBrowserSAP.h"
#import "VLCLocalNetworkServiceVLCMedia.h"
@implementation VLCLocalNetworkServiceBrowserSAP

- (instancetype)init {
    return [super initWithName:@"SAP"
            serviceServiceName:@"sap"];
}

- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    if (media)
        return [[VLCLocalNetworkServiceSAP alloc] initWithMediaItem:media serviceName:self.name];
    return nil;
}

@end


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
