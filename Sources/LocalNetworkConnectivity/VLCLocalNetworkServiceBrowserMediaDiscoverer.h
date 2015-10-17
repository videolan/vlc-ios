/*****************************************************************************
 * VLCLocalNetworkServiceBrowserMediaDiscoverer.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import "VLCLocalNetworkServiceBrowser-Protocol.h"
@interface VLCLocalNetworkServiceBrowserMediaDiscoverer : NSObject <VLCLocalNetworkServiceBrowser>

- (instancetype)initWithName:(NSString *)name serviceServiceName:(NSString *)serviceName NS_DESIGNATED_INITIALIZER;
@end

@interface VLCLocalNetworkServiceBrowserSAP : VLCLocalNetworkServiceBrowserMediaDiscoverer
- (instancetype)init;
@end

@interface VLCLocalNetworkServiceBrowserDSM : VLCLocalNetworkServiceBrowserMediaDiscoverer
- (instancetype)init;
@end