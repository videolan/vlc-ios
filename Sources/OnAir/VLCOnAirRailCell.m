/*****************************************************************************
 * VLCOnAirRailCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOnAirRailCell.h"
#import "VLCOnAirAddTile.h"
#import "VLCRadioFavoriteTile.h"
#import "VLCFavoriteService.h"

static CGFloat const kVLCOnAirRailGap = 12.0;
static CGFloat const kVLCOnAirRailSideMargin = 20.0;
static CGFloat const kVLCOnAirRailNameArea = 28.0;
static CGFloat const kVLCOnAirRailCompactTileSide = 96.0;
static CGFloat const kVLCOnAirRailRegularTileSide = 140.0;
static CGFloat const kVLCOnAirRailRegularWidthThreshold = 600.0;

@interface VLCOnAirRailCell () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@end

@implementation VLCOnAirRailCell
{
    UICollectionView *_collectionView;
    NSArray<VLCFavorite *> *_favorites;
    NSUInteger _favoriteCount;
    BOOL _showsAddTile;
    CGFloat _tileSide;
}

+ (NSString *)reuseIdentifier
{
    return @"VLCOnAirRailCell";
}

+ (CGFloat)tileSideForWidth:(CGFloat)width
{
    return width >= kVLCOnAirRailRegularWidthThreshold ? kVLCOnAirRailRegularTileSide
                                                       : kVLCOnAirRailCompactTileSide;
}

+ (CGFloat)heightForWidth:(CGFloat)width
{
    return [self tileSideForWidth:width] + kVLCOnAirRailNameArea;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundView = [[UIView alloc] init];
        self.backgroundView.backgroundColor = [UIColor clearColor];
        if (@available(iOS 14.0, *)) {
            self.backgroundConfiguration = [UIBackgroundConfiguration clearConfiguration];
        }
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumInteritemSpacing = kVLCOnAirRailGap;
        layout.minimumLineSpacing = kVLCOnAirRailGap;
        layout.sectionInset = UIEdgeInsetsMake(0.0, kVLCOnAirRailSideMargin, 0.0, kVLCOnAirRailSideMargin);

        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:[VLCRadioFavoriteTile class]
            forCellWithReuseIdentifier:VLCRadioFavoriteTile.reuseIdentifier];
        [_collectionView registerClass:[VLCOnAirAddTile class]
            forCellWithReuseIdentifier:VLCOnAirAddTile.reuseIdentifier];
        [self.contentView addSubview:_collectionView];

        [NSLayoutConstraint activateConstraints:@[
            [_collectionView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [_collectionView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_collectionView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_collectionView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
        ]];
    }
    return self;
}

- (void)configureWithFavorites:(NSArray<VLCFavorite *> *)favorites
                  showsAddTile:(BOOL)showsAddTile
                referenceWidth:(CGFloat)referenceWidth
{
    _favorites = favorites;
    _favoriteCount = favorites.count;
    _showsAddTile = showsAddTile;
    _tileSide = [VLCOnAirRailCell tileSideForWidth:referenceWidth];
    [_collectionView setContentOffset:CGPointZero animated:NO];
    [_collectionView reloadData];
}

#pragma mark - collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _favoriteCount + (_showsAddTile ? 1 : 0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ((NSUInteger)indexPath.item >= _favoriteCount) {
        VLCOnAirAddTile *addTile = [collectionView dequeueReusableCellWithReuseIdentifier:VLCOnAirAddTile.reuseIdentifier
                                                                            forIndexPath:indexPath];
        [addTile updateTheme];
        return addTile;
    }

    VLCRadioFavoriteTile *tile = [collectionView dequeueReusableCellWithReuseIdentifier:VLCRadioFavoriteTile.reuseIdentifier
                                                                          forIndexPath:indexPath];
    VLCFavorite *favorite = _favorites[indexPath.item];
    [tile configureWithName:favorite.userVisibleName artworkURL:favorite.artworkURL];
    return tile;
}

#pragma mark - collection view delegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(_tileSide, _tileSide + kVLCOnAirRailNameArea);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ((NSUInteger)indexPath.item >= _favoriteCount) {
        [self.delegate railCellDidSelectAddTile:self];
        return;
    }

    [self.delegate railCell:self didSelectItemAtIndex:indexPath.item];
}

@end
