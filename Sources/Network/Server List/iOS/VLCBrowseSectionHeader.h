/*****************************************************************************
 * VLCBrowseSectionHeader.h
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

NS_ASSUME_NONNULL_BEGIN

@interface VLCBrowseSectionHeader : UICollectionReusableView

@property (class, readonly) NSString *reuseIdentifier;
@property (class, readonly) CGFloat height;

- (void)configureWithTitle:(nullable NSString *)title;

@end

NS_ASSUME_NONNULL_END
