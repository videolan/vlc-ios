/*****************************************************************************
 * VLCOnAirRailCell.h
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

@class VLCFavorite;
@class VLCOnAirRailCell;

NS_ASSUME_NONNULL_BEGIN

@protocol VLCOnAirRailCellDelegate <NSObject>

- (void)railCell:(VLCOnAirRailCell *)cell didSelectItemAtIndex:(NSInteger)index;
- (void)railCellDidSelectAddTile:(VLCOnAirRailCell *)cell;

@end

@interface VLCOnAirRailCell : UITableViewCell

@property (class, readonly) NSString *reuseIdentifier;
@property (nonatomic, weak) id<VLCOnAirRailCellDelegate> delegate;

- (void)configureWithFavorites:(NSArray<VLCFavorite *> *)favorites
                  showsAddTile:(BOOL)showsAddTile
                referenceWidth:(CGFloat)referenceWidth;

+ (CGFloat)tileSideForWidth:(CGFloat)width;
+ (CGFloat)heightForWidth:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
