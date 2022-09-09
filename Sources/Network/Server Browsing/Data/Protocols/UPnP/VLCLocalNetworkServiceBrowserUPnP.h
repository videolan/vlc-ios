/*****************************************************************************
 * VLCLocalNetworkServiceBrowserUPnP.h
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
#import "VLCLocalNetworkServiceVLCMedia.h"
#import "VLCNetworkServerBrowserVLCMedia.h"
#import "VLCLocalNetworkServiceBrowserMediaDiscoverer.h"
#import "VLCNetworkServerLoginInformation.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLCLocalNetworkServiceBrowserUPnP : VLCLocalNetworkServiceBrowserMediaDiscoverer
- (instancetype)init;
@end

extern NSString *const VLCMediaDiscovererServiceNameUPnP;
extern NSString *const VLCNetworkServerProtocolIdentifierUPnP;
@interface VLCLocalNetworkServiceUPnP : VLCLocalNetworkServiceVLCMedia

@end

@interface VLCNetworkServerBrowserVLCMedia (UPnP)
+ (instancetype)UPnPNetworkServerBrowserWithLogin:(VLCNetworkServerLoginInformation *)login;
+ (instancetype)UPnPNetworkServerBrowserWithURL:(NSURL *)url options:(NSDictionary *)mediaOptions;

@end

NS_ASSUME_NONNULL_END
