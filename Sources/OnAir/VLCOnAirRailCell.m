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
#import "VLCAddTile.h"

static CGFloat const kVLCOnAirRailGap = 12.0;
static CGFloat const kVLCOnAirRailSideMargin = 20.0;
static CGFloat const kVLCOnAirRailNameArea = 22.0;
static CGFloat const kVLCOnAirRailSubtitleArea = 15.0;
static CGFloat const kVLCOnAirRailTileSide = 72.0;
static CGFloat const kVLCOnAirRailTileCornerRadius = 9.0;

@implementation VLCOnAirRailItem

- (instancetype)initWithName:(NSString *)name artworkURL:(NSURL *)artworkURL
{
    self = [super init];
    if (self) {
        _name = name;
        _artworkURL = artworkURL;
    }
    return self;
}

@end

@interface VLCOnAirRailCell () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@end

@implementation VLCOnAirRailCell
{
    UICollectionView *_collectionView;
    NSArray<VLCOnAirRailItem *> *_items;
    NSUInteger _itemCount;
    BOOL _showsSubtitles;
    BOOL _showsAddTile;
}

+ (NSString *)reuseIdentifier
{
    return @"VLCOnAirRailCell";
}

+ (CGFloat)heightWithSubtitles:(BOOL)showsSubtitles
{
    return [self heightWithTileSide:kVLCOnAirRailTileSide subtitles:showsSubtitles];
}

+ (CGFloat)heightWithTileSide:(CGFloat)tileSide subtitles:(BOOL)showsSubtitles
{
    return tileSide + kVLCOnAirRailNameArea + (showsSubtitles ? kVLCOnAirRailSubtitleArea : 0.0);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _tileSide = kVLCOnAirRailTileSide;
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
        [_collectionView registerClass:[VLCArtworkTile class]
            forCellWithReuseIdentifier:VLCArtworkTile.reuseIdentifier];
        [_collectionView registerClass:[VLCAddTile class]
            forCellWithReuseIdentifier:VLCAddTile.reuseIdentifier];
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

- (void)prepareForReuse
{
    [super prepareForReuse];
    [_collectionView setContentOffset:CGPointZero animated:NO];
}

- (void)configureWithItems:(NSArray<VLCOnAirRailItem *> *)items
            showsSubtitles:(BOOL)showsSubtitles
              showsAddTile:(BOOL)showsAddTile
{
    _items = items;
    _itemCount = items.count;
    _showsSubtitles = showsSubtitles;
    _showsAddTile = showsAddTile;
    [_collectionView reloadData];
}

#pragma mark - collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _itemCount + (_showsAddTile ? 1 : 0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ((NSUInteger)indexPath.item >= _itemCount) {
        VLCAddTile *addTile = [collectionView dequeueReusableCellWithReuseIdentifier:VLCAddTile.reuseIdentifier
                                                                       forIndexPath:indexPath];
        addTile.outlineCornerRadius = kVLCOnAirRailTileCornerRadius;
        [addTile configureWithTitle:NSLocalizedString(@"ONAIR_ADD", nil)];
        return addTile;
    }

    VLCArtworkTile *tile = [collectionView dequeueReusableCellWithReuseIdentifier:VLCArtworkTile.reuseIdentifier
                                                                     forIndexPath:indexPath];
    VLCOnAirRailItem *item = _items[indexPath.item];
    tile.artworkCornerRadius = kVLCOnAirRailTileCornerRadius;
    tile.badge = item.badge;
    tile.subtitle = _showsSubtitles ? item.subtitle : nil;
    tile.accessoryGlyphName = item.accessoryGlyphName;
    tile.accessibilityLabel = item.accessoryLabel ? [NSString stringWithFormat:@"%@, %@", item.name, item.accessoryLabel]
                                                  : item.name;

    CGFloat maxPixelSize = 0.0;
    if (item.downsamplesArtwork) {
        CGFloat scale = collectionView.traitCollection.displayScale;
        maxPixelSize = _tileSide * (scale > 0.0 ? scale : 2.0);
    }
    [tile configureWithName:item.name artworkURL:item.artworkURL maxPixelSize:maxPixelSize];
    return tile;
}

#pragma mark - collection view delegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(_tileSide, [VLCOnAirRailCell heightWithTileSide:_tileSide subtitles:_showsSubtitles]);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ((NSUInteger)indexPath.item < _itemCount) {
        [self.delegate railCell:self didSelectItemAtIndex:indexPath.item];
        return;
    }

    if ([self.delegate respondsToSelector:@selector(railCellDidSelectAddTile:)]) {
        [self.delegate railCellDidSelectAddTile:self];
    }
}

@end
