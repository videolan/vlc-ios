/*****************************************************************************
 * VLCBrowseSharingBandCell.h
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

@interface VLCBrowseSharingBandCell : UICollectionViewCell

@property (class, readonly) NSString *reuseIdentifier;

+ (CGFloat)heightForAddressCount:(NSInteger)count;

- (void)configureWithAddresses:(NSArray<NSString *> *)addresses
                  joinedToChip:(BOOL)joined
                     chipWidth:(CGFloat)chipWidth;

@end

NS_ASSUME_NONNULL_END
