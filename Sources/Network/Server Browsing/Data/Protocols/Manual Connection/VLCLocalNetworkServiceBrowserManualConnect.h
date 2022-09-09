/*****************************************************************************
 * VLCLocalNetworkServiceBrowserManualConnect.h
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

NS_ASSUME_NONNULL_BEGIN

@interface VLCLocalNetworkServiceBrowserManualConnect : NSObject <VLCLocalNetworkServiceBrowser>
- (instancetype)init;
@end


@interface VLCLocalNetworkServiceItemLogin : NSObject <VLCLocalNetworkService>
- (instancetype)initWithServiceName:(NSString *)serviceName;
@end

NS_ASSUME_NONNULL_END
