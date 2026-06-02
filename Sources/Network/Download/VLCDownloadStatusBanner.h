/*****************************************************************************
 * VLCDownloadStatusBanner.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Jean-Romain Bouquet <cabbry # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

/**
 * Compact banner shown above the tab bar that surfaces the state of the
 * active download. Tap-to-open is handled via the `onTap` block.
 */
@interface VLCDownloadStatusBanner : UIView

@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *bytesText;

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) BOOL progressKnown;

@property (nonatomic, copy, nullable) void (^onTap)(void);

- (void)applyTheme;

@end
