/*****************************************************************************
 * VLCServiceBrowserRadio.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceBrowserMediaDiscoverer.h"
#import "VLCLocalNetworkServiceVLCMedia.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLCServiceBrowserRadio : VLCLocalNetworkServiceBrowserMediaDiscoverer
- (instancetype)init;
@end

@interface VLCServiceRadio : VLCLocalNetworkServiceVLCMedia
@end

NS_ASSUME_NONNULL_END
