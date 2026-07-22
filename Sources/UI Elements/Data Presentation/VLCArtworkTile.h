/*****************************************************************************
 * VLCArtworkTile.h
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

@class VLCArtworkTile;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VLCArtworkTileBadge) {
    VLCArtworkTileBadgeNone,
    VLCArtworkTileBadgePlay
};

@protocol VLCArtworkTileDelegate <NSObject>
- (void)artworkTileDidRequestRemoval:(VLCArtworkTile *)tile;
@optional
- (nullable NSArray<UIMenuElement *> *)menuElementsForArtworkTile:(VLCArtworkTile *)tile API_AVAILABLE(ios(14.0));
@end

@interface VLCArtworkTile : UICollectionViewCell

@property (class, readonly) NSString *reuseIdentifier;
@property (nonatomic, weak, nullable) id<VLCArtworkTileDelegate> delegate;
@property (nonatomic) CGFloat artworkCornerRadius;
@property (nonatomic) VLCArtworkTileBadge badge;
@property (nonatomic, copy, nullable) NSString *pillText;
@property (nonatomic, copy, nullable) NSString *accessoryGlyphName;
@property (nonatomic, copy, nullable) NSString *removalActionTitle;

- (void)configureWithName:(nullable NSString *)name artworkURL:(nullable NSURL *)artworkURL;
- (void)configureWithName:(nullable NSString *)name
                    glyph:(nullable UIImage *)glyph
                tintColor:(UIColor *)tintColor;

@end

NS_ASSUME_NONNULL_END
