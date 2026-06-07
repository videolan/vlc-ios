/*****************************************************************************
 * VLCDownloadProgressView.h
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
 * Reusable progress strip showing a title, a percentage / spinner area, a
 * progress bar and a subtitle line. Hosted both by the inline download cell
 * and the floating download banner.
 */
@interface VLCDownloadProgressView : UIView

@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *subtitle;

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) BOOL progressKnown;

@property (nonatomic, assign) NSInteger subtitleNumberOfLines;
@property (nonatomic, assign) UIEdgeInsets contentInsets;

- (void)setTitleFontSize:(CGFloat)titleSize subtitleFontSize:(CGFloat)subtitleSize;
- (void)setTitleFont:(nonnull UIFont *)titleFont subtitleFont:(nonnull UIFont *)subtitleFont;
- (void)applyTheme;

@end
