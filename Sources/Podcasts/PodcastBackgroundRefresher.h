/*****************************************************************************
 * PodcastBackgroundRefresher.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface PodcastBackgroundRefresher : NSObject

+ (instancetype)sharedInstance;

- (void)registerTasks;
- (void)scheduleDownloadTask;

@end

NS_ASSUME_NONNULL_END
