/*****************************************************************************
 * VLCBrowseSharingCell.h
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

@class VLCBrowseSharingCell;

NS_ASSUME_NONNULL_BEGIN

@protocol VLCBrowseSharingCellDelegate <NSObject>
- (void)sharingCellDidChangeState:(VLCBrowseSharingCell *)cell;
@end

@interface VLCBrowseSharingCell : UICollectionViewCell

@property (class, readonly) NSString *reuseIdentifier;
@property (nonatomic, weak, nullable) id<VLCBrowseSharingCellDelegate> delegate;
@property (nonatomic, readonly) BOOL isSharingEnabled;

- (void)configureJoinedToBand:(BOOL)joined;
- (void)toggleSharing;

@end

NS_ASSUME_NONNULL_END
