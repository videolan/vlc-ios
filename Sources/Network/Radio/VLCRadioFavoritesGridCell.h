/*****************************************************************************
 * VLCRadioFavoritesGridCell.h
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
@class VLCRadioFavoritesGridCell;

NS_ASSUME_NONNULL_BEGIN

@protocol VLCRadioFavoritesGridCellDelegate <NSObject>
- (void)favoritesGridCell:(VLCRadioFavoritesGridCell *)cell didSelectFavoriteAtIndex:(NSInteger)index;
@end

@interface VLCRadioFavoritesGridCell : UITableViewCell

@property (class, readonly) NSString *reuseIdentifier;
@property (nonatomic, weak) id<VLCRadioFavoritesGridCellDelegate> delegate;

- (void)configureWithFavorites:(NSArray<VLCFavorite *> *)favorites;

+ (CGFloat)heightForFavoriteCount:(NSInteger)count width:(CGFloat)width;
+ (NSInteger)columnsForWidth:(CGFloat)width;
+ (NSInteger)visibleFavoriteCapForWidth:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
