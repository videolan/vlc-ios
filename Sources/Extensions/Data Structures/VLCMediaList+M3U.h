/*****************************************************************************
 * VLCMediaList+M3U.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <VLCKit/VLCKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCMediaList (M3U)

- (BOOL)writeM3UToURL:(NSURL *)fileURL
                error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
