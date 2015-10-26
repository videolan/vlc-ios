/*****************************************************************************
 * VLCLocalNetworkServiceBrowserPlex.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceBrowserNetService.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLCLocalNetworkServiceBrowserPlex : VLCLocalNetworkServiceBrowserNetService
- (instancetype)initWithName:(NSString *)name serviceType:(NSString *)serviceType domain:(NSString *)domain NS_UNAVAILABLE;
- (instancetype)init NS_DESIGNATED_INITIALIZER;
@end


extern NSString *const VLCNetworkServerProtocolIdentifierPlex;
@interface VLCLocalNetworkServicePlex : VLCLocalNetworkServiceNetService
@end

NS_ASSUME_NONNULL_END