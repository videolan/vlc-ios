/*****************************************************************************
 * VLCNetworkServerBrowserVLCMedia+SFTP.h
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

extern NSString *const VLCNetworkServerProtocolIdentifierSFTP;

@interface VLCNetworkServerBrowserVLCMedia (SFTP)
+ (instancetype)SFTPNetworkServerBrowserWithLogin:(VLCNetworkServerLoginInformation *)login;
+ (instancetype)SFTPNetworkServerBrowserWithURL:(NSURL *)url
                                       username:(nullable NSString *)username
                                       password:(nullable NSString *)password;

@end

NS_ASSUME_NONNULL_END
