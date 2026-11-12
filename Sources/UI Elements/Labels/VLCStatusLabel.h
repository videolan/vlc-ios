/*****************************************************************************
 * VLCStatusLabel.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCStatusLabel;

@protocol VLCStatusLabelDelegate <NSObject>

- (void)statusLabelDidHide:(VLCStatusLabel *)statusLabel;

@end

@interface VLCStatusLabel : UILabel

@property (nonatomic, weak, nullable) id<VLCStatusLabelDelegate> delegate;

- (void)showStatusMessage:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
