/*****************************************************************************
 * VLCLocalNetworkServiceBrowserDSM.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
#import "VLCLocalNetworkServiceVLCMedia.h"
#import "VLCNetworkServerBrowserVLCMedia.h"
#import "VLCLocalNetworkServiceBrowserMediaDiscoverer.h"
#import "VLCNetworkServerLoginInformation.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLCLocalNetworkServiceBrowserDSM : VLCLocalNetworkServiceBrowserMediaDiscoverer
- (instancetype)init;
@end

extern NSString *const VLCNetworkServerProtocolIdentifierSMB;
@interface VLCLocalNetworkServiceDSM: VLCLocalNetworkServiceVLCMedia

@end

@interface VLCNetworkServerBrowserVLCMedia (SMB)
+ (instancetype)SMBNetworkServerBrowserWithLogin:(VLCNetworkServerLoginInformation *)login;
+ (instancetype)SMBNetworkServerBrowserWithURL:(NSURL *)url
									  username:(nullable NSString *)username
									  password:(nullable NSString *)password
									 workgroup:(nullable NSString *)workgroup;

@end

NS_ASSUME_NONNULL_END
