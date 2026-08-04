/*****************************************************************************
 * VLCOnAirPromptCell.h
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

@class VLCOnAirPromptCell;

NS_ASSUME_NONNULL_BEGIN

@protocol VLCOnAirPromptCellDelegate <NSObject>

- (void)promptCell:(VLCOnAirPromptCell *)cell didTapButtonAtIndex:(NSInteger)index;

@end

@interface VLCOnAirPromptCell : UITableViewCell

@property (class, readonly) NSString *reuseIdentifier;
@property (nonatomic, weak) id<VLCOnAirPromptCellDelegate> delegate;

- (void)configureWithGlyph:(nullable UIImage *)glyph
                     title:(NSString *)title
                      body:(NSString *)body
              primaryTitle:(NSString *)primaryTitle
            secondaryTitle:(nullable NSString *)secondaryTitle
          actionsAvailable:(BOOL)actionsAvailable;

@end

NS_ASSUME_NONNULL_END
