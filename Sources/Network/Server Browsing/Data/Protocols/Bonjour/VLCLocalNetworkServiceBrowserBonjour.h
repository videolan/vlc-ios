/*****************************************************************************
 * VLCLocalNetworkServiceBrowserBonjour.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
#import "VLCLocalNetworkServiceVLCMedia.h"
#import "VLCNetworkServerBrowserVLCMedia.h"
#import "VLCLocalNetworkServiceBrowserMediaDiscoverer.h"
#import "VLCNetworkServerLoginInformation.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLCLocalNetworkServiceBrowserBonjour : VLCLocalNetworkServiceBrowserMediaDiscoverer
- (instancetype)init;
@end

@interface VLCLocalNetworkServiceBonjour: VLCLocalNetworkServiceVLCMedia

@end

@interface VLCNetworkServerBrowserVLCMedia (Bonjour)

@end

NS_ASSUME_NONNULL_END
