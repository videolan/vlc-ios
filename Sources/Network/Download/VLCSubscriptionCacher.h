/*****************************************************************************
 * VLCSubscriptionCacher.h
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
#import <VLCMediaLibraryKit/VLCMediaLibraryKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Bridges the media library's caching contract to VLCKit's downloader.
 *
 * The media library owns all caching policy (which subscription media to cache,
 * quota, eviction, destination path); this object only fetches an MRL and writes
 * it to the path the library dictates. Assign an instance to
 * VLCMediaLibrary.cacherDelegate. Its methods are invoked on a media library
 * background thread and cacheMRL:toPath: blocks until the download completes,
 * fails, or is interrupted.
 *
 * The library does not tell the delegate whether a download was requested by the
 * user or started by the automatic subscription pass, so the distinction is
 * reconstructed here: anything announced through
 * addManualRequestForMediaWithIdentifier: counts as manual, everything else as
 * automatic. Automatic downloads are restricted to Wi-Fi and are abandoned when
 * Wi-Fi goes away; manual ones run on any network.
 */
@interface VLCSubscriptionCacher : NSObject <VLCMLCacherDelegate>

@property (nonatomic, readonly) BOOL automaticCachingAllowed;

/* Must be called before the matching cacheMedia:, as the library may enter
 * cacheMRL:toPath: on its worker thread before that call returns. */
- (void)addManualRequestForMediaWithIdentifier:(VLCMLIdentifier)identifier;
- (void)removeManualRequestForMediaWithIdentifier:(VLCMLIdentifier)identifier;

@end

NS_ASSUME_NONNULL_END
