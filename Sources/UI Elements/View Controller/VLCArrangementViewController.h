/*****************************************************************************
 * VLCArrangementViewController.h
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

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 270100) || \
    (defined(__VISION_OS_VERSION_MAX_ALLOWED) && __VISION_OS_VERSION_MAX_ALLOWED >= 270100)
#define VLC_HAS_ARRANGEMENT_SDK 1
#endif

NS_ASSUME_NONNULL_BEGIN

@class VLCArrangementViewController;

API_AVAILABLE(ios(27.1), visionos(27.1))
@protocol VLCArrangementViewControllerDelegate <NSObject>

- (void)arrangementViewController:(VLCArrangementViewController *)arrangementViewController
     didChangeSecondaryVisibility:(BOOL)secondaryVisible;

@end

API_AVAILABLE(ios(27.1), visionos(27.1))
#ifdef VLC_HAS_ARRANGEMENT_SDK
@interface VLCArrangementViewController : UIArrangementViewController
#else
@interface VLCArrangementViewController : UIViewController
#endif

- (nullable instancetype)initWithPrimaryViewController:(UIViewController *)primaryViewController
                               secondaryViewController:(UIViewController *)secondaryViewController;

@property (nonatomic, readonly) UIViewController *primaryViewController;
@property (nonatomic, weak, nullable) id<VLCArrangementViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
