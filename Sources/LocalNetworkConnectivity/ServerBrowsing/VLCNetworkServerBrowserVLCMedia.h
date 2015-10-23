/*****************************************************************************
 * VLCNetworkServerBrowserVLCMedia.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowser-Protocol.h"

NS_ASSUME_NONNULL_BEGIN
@interface VLCNetworkServerBrowserVLCMedia : NSObject <VLCNetworkServerBrowser>
- (instancetype)initWithMedia:(VLCMedia *)media NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end


@interface VLCNetworkServerBrowserItemVLCMedia : NSObject <VLCNetworkServerBrowserItem>
- (instancetype)initWithMedia:(VLCMedia *)media;
@end

@interface VLCNetworkServerBrowserVLCMedia (SMB)
+ (instancetype)SMBNetworkServerBrowserWithURL:(NSURL *)url
                                      username:(nullable NSString *)username
                                      password:(nullable NSString *)password
                                     workgroup:(nullable NSString *)workgroup;

@end

NS_ASSUME_NONNULL_END