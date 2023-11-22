/*****************************************************************************
 * VLCOpenNetworkSubtitlesFinder.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCOpenNetworkSubtitlesFinder : NSObject

+ (void)tryToFindSubtitleOnServerForURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
