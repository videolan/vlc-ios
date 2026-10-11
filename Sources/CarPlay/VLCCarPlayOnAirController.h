/*****************************************************************************
 * VLCCarPlayOnAirController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCarPlayBrowserController.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLCCarPlayOnAirController : VLCCarPlayBrowserController

- (CPGridTemplate *)onAirTemplate;
- (void)radioListNeedsUpdate;
- (void)podcastsNeedUpdate;

@end

NS_ASSUME_NONNULL_END
