/*****************************************************************************
 * VLCNetworkServerBrowserFactory.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "VLCNetworkServerBrowser-Protocol.h"

@class VLCNetworkServerLoginInformation;

NS_ASSUME_NONNULL_BEGIN

@interface VLCNetworkServerBrowserFactory : NSObject

+ (nullable id<VLCNetworkServerBrowser>)browserForLogin:(VLCNetworkServerLoginInformation *)login;

@end

NS_ASSUME_NONNULL_END
