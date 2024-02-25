/*****************************************************************************
 * VLCLocalNetworkServiceBrowserFavorites.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceBrowser-Protocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLCLocalNetworkServiceBrowserFavorites : NSObject <VLCLocalNetworkServiceBrowser>
- (instancetype)init;
@end


@interface VLCLocalNetworkServiceItemFavorite : NSObject <VLCLocalNetworkService>
- (instancetype)initWithServiceName:(NSString *)serviceName;
@end

NS_ASSUME_NONNULL_END
