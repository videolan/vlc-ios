/*****************************************************************************
 * VLCOnAirContinueCell.h
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

@class VLCOnAirContinueCell;

NS_ASSUME_NONNULL_BEGIN

@protocol VLCOnAirContinueCellDelegate <NSObject>

- (void)continueCellDidTapPlay:(VLCOnAirContinueCell *)cell;

@end

@interface VLCOnAirContinueCell : UITableViewCell

@property (class, readonly) NSString *reuseIdentifier;
@property (nonatomic, weak) id<VLCOnAirContinueCellDelegate> delegate;

- (void)configureWithName:(nullable NSString *)name
               artworkURL:(nullable NSURL *)artworkURL
                     meta:(nullable NSString *)meta
                 progress:(float)progress;

@end

NS_ASSUME_NONNULL_END
