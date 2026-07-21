/*****************************************************************************
 * VLCRadioFavoritesGridCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRadioFavoritesGridCell.h"
#import "VLCRadioFavoriteTile.h"
#import "VLCFavoriteService.h"

static CGFloat const kVLCRadioGridSideMargin = 20.0;
static CGFloat const kVLCRadioGridGap = 14.0;
static CGFloat const kVLCRadioGridNameArea = 28.0;
static CGFloat const kVLCRadioGridMinTileWidth = 165.0;
static CGFloat const kVLCRadioGridTopPadding = 0.0;
static CGFloat const kVLCRadioGridBottomPadding = 4.0;

@interface VLCRadioFavoritesGridCell () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@end

@implementation VLCRadioFavoritesGridCell
{
    UICollectionView *_collectionView;
    NSArray<VLCFavorite *> *_favorites;
}

+ (NSString *)reuseIdentifier
{
    return @"VLCRadioFavoritesGridCell";
}

#pragma mark - layout math (shared with the hosting view controller)

+ (NSInteger)columnsForWidth:(CGFloat)width
{
    CGFloat available = width - 2 * kVLCRadioGridSideMargin;
    NSInteger columns = (NSInteger)floor((available + kVLCRadioGridGap) / (kVLCRadioGridMinTileWidth + kVLCRadioGridGap));
    return MAX(2, columns);
}

+ (NSInteger)visibleFavoriteCapForWidth:(CGFloat)width
{
    return [self columnsForWidth:width] * 2;
}

+ (CGFloat)tileWidthForWidth:(CGFloat)width columns:(NSInteger)columns
{
    CGFloat available = width - 2 * kVLCRadioGridSideMargin;
    return floor((available - kVLCRadioGridGap * (columns - 1)) / columns);
}

+ (CGFloat)heightForFavoriteCount:(NSInteger)count width:(CGFloat)width
{
    if (count == 0 || width <= 0)
        return 0.0;

    NSInteger columns = [self columnsForWidth:width];
    CGFloat tileWidth = [self tileWidthForWidth:width columns:columns];
    NSInteger rows = (count + columns - 1) / columns;
    CGFloat itemHeight = tileWidth + kVLCRadioGridNameArea;

    return kVLCRadioGridTopPadding + rows * itemHeight + (rows - 1) * kVLCRadioGridGap + kVLCRadioGridBottomPadding;
}

#pragma mark - lifecycle

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
        layout.minimumInteritemSpacing = kVLCRadioGridGap;
        layout.minimumLineSpacing = kVLCRadioGridGap;
        layout.sectionInset = UIEdgeInsetsMake(kVLCRadioGridTopPadding, kVLCRadioGridSideMargin,
                                               kVLCRadioGridBottomPadding, kVLCRadioGridSideMargin);

        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.scrollEnabled = NO;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:[VLCRadioFavoriteTile class]
            forCellWithReuseIdentifier:VLCRadioFavoriteTile.reuseIdentifier];
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
{
    _favorites = favorites;
    [_collectionView reloadData];
}

#pragma mark - collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _favorites.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
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
    CGFloat width = collectionView.bounds.size.width;
    NSInteger columns = [VLCRadioFavoritesGridCell columnsForWidth:width];
    CGFloat tileWidth = [VLCRadioFavoritesGridCell tileWidthForWidth:width columns:columns];
    return CGSizeMake(tileWidth, tileWidth + kVLCRadioGridNameArea);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate favoritesGridCell:self didSelectFavoriteAtIndex:indexPath.item];
}

@end
