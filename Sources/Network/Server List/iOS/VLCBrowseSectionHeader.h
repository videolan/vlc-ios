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

@class VLCBrowseSectionHeader;

NS_ASSUME_NONNULL_BEGIN

@protocol VLCBrowseSectionHeaderDelegate <NSObject>
- (void)sectionHeaderDidTriggerAction:(VLCBrowseSectionHeader *)header;
@end

@interface VLCBrowseSectionHeader : UICollectionReusableView

@property (class, readonly) NSString *reuseIdentifier;
@property (class, readonly) CGFloat height;
@property (nonatomic, weak, nullable) id<VLCBrowseSectionHeaderDelegate> delegate;

- (void)configureWithTitle:(nullable NSString *)title showsAddButton:(BOOL)showsAddButton;

@end

NS_ASSUME_NONNULL_END
