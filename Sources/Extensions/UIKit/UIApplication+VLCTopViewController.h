/*****************************************************************************
 * UIApplication+VLCTopViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (VLCTopViewController)

@property (nonatomic, readonly, nullable) UIWindow *activeKeyWindow;
@property (nonatomic, readonly, nullable) UIViewController *topViewController;

@end

NS_ASSUME_NONNULL_END
