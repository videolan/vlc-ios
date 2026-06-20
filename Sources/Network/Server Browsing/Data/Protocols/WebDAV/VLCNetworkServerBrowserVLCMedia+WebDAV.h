/*****************************************************************************
 * VLCNetworkServerBrowserVLCMedia+WebDAV.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
#import "VLCLocalNetworkServiceVLCMedia.h"
#import "VLCNetworkServerBrowserVLCMedia.h"
#import "VLCLocalNetworkServiceBrowserMediaDiscoverer.h"
#import "VLCNetworkServerLoginInformation.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const VLCNetworkServerProtocolIdentifierWebDAV;

@interface VLCNetworkServerBrowserVLCMedia (WebDAV)
+ (instancetype)WebDAVNetworkServerBrowserWithLogin:(VLCNetworkServerLoginInformation *)login;
+ (instancetype)WebDAVNetworkServerBrowserWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
