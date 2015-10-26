/*****************************************************************************
 * VLCLocalNetworkServiceBrowserSAP.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceBrowserMediaDiscoverer.h"
#import "VLCLocalNetworkServiceVLCMedia.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLCLocalNetworkServiceBrowserSAP : VLCLocalNetworkServiceBrowserMediaDiscoverer
- (instancetype)init;
@end

@interface VLCLocalNetworkServiceSAP: VLCLocalNetworkServiceVLCMedia

@end

NS_ASSUME_NONNULL_END
