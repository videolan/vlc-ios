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
#import "VLCArtworkTile.h"

@class VLCOnAirRailCell;

NS_ASSUME_NONNULL_BEGIN

@interface VLCOnAirRailItem : NSObject

@property (readonly) NSString *name;
@property (readonly, nullable) NSURL *artworkURL;
@property (nonatomic, copy, nullable) NSString *subtitle;
@property (nonatomic) VLCArtworkTileBadge badge;
@property (nonatomic, copy, nullable) NSString *accessoryGlyphName;
@property (nonatomic, copy, nullable) NSString *accessoryLabel;
@property (nonatomic) BOOL downsamplesArtwork;

- (instancetype)initWithName:(NSString *)name artworkURL:(nullable NSURL *)artworkURL;
- (instancetype)init NS_UNAVAILABLE;

@end

@protocol VLCOnAirRailCellDelegate <NSObject>

- (void)railCell:(VLCOnAirRailCell *)cell didSelectItemAtIndex:(NSInteger)index;

@optional
- (void)railCellDidSelectAddTile:(VLCOnAirRailCell *)cell;

@end

@interface VLCOnAirRailCell : UITableViewCell

@property (class, readonly) NSString *reuseIdentifier;
@property (nonatomic, weak) id<VLCOnAirRailCellDelegate> delegate;
@property (nonatomic) CGFloat tileSide;

+ (CGFloat)heightWithSubtitles:(BOOL)showsSubtitles;
+ (CGFloat)heightWithTileSide:(CGFloat)tileSide subtitles:(BOOL)showsSubtitles;

- (void)configureWithItems:(NSArray<VLCOnAirRailItem *> *)items
            showsSubtitles:(BOOL)showsSubtitles
              showsAddTile:(BOOL)showsAddTile NS_SWIFT_NAME(configure(items:showsSubtitles:showsAddTile:));

@end

NS_ASSUME_NONNULL_END
