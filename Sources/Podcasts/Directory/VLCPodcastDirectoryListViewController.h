/*****************************************************************************
 * VLCPodcastDirectoryListViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkListViewController.h"

@class VLCPodcastIndexService;
@class VLCPodcastIndexShelf;

NS_ASSUME_NONNULL_BEGIN

@interface VLCPodcastDirectoryListViewController : VLCNetworkListViewController

- (instancetype)initWithService:(VLCPodcastIndexService *)service
                          shelf:(nullable VLCPodcastIndexShelf *)shelf;

@end

NS_ASSUME_NONNULL_END
