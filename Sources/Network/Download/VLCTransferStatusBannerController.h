/*****************************************************************************
 * VLCTransferStatusBannerController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@class VLCTransferStatusBannerController;

@protocol VLCTransferStatusBannerControllerDelegate <NSObject>
@optional
- (void)transferStatusBannerWasTapped:(VLCTransferStatusBannerController *)controller;
- (NSLayoutYAxisAnchor *)bottomAnchorForTransferStatusBanner:(VLCTransferStatusBannerController *)controller;
@end

@interface VLCTransferStatusBannerController : NSObject

- (instancetype)initWithContainerView:(UIView *)containerView
                             delegate:(id<VLCTransferStatusBannerControllerDelegate>)delegate;

- (void)refreshBottomAnchor;

@end
