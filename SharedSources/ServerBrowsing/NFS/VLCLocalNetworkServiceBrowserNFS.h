/*****************************************************************************
 * VLCLocalNetworkServiceBrowserNFS.h
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

@interface VLCLocalNetworkServiceBrowserNFS : VLCLocalNetworkServiceBrowserMediaDiscoverer
- (instancetype)init;
@end

extern NSString *const VLCNetworkServerProtocolIdentifierNFS;
@interface VLCLocalNetworkServiceNFS: VLCLocalNetworkServiceVLCMedia

@end

@interface VLCNetworkServerBrowserVLCMedia (NFS)
+ (instancetype)NFSNetworkServerBrowserWithLogin:(VLCNetworkServerLoginInformation *)login;
+ (instancetype)NFSNetworkServerBrowserWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
