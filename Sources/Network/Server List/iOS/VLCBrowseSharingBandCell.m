/*****************************************************************************
 * VLCBrowseSharingBandCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCBrowseSharingBandCell.h"

#import "VLC-Swift.h"

static CGFloat const kVLCBrowseBandCornerRadius = 9.0;
static CGFloat const kVLCBrowseBandPadding = 8.0;
static CGFloat const kVLCBrowseBandRowHeight = 34.0;
static CGFloat const kVLCBrowseBandRowGap = 6.0;
static CGFloat const kVLCBrowseBandRowRadius = 7.0;
static CGFloat const kVLCBrowseBandChipOverlap = 7.0;
static CGFloat const kVLCBrowseBandGlyphSide = 18.0;

@implementation VLCBrowseSharingBandCell
{
    UIView *_bandView;
    NSLayoutConstraint *_bandTopConstraint;
    NSArray<NSString *> *_addresses;
    NSMutableArray<UIControl *> *_rowViews;
}

+ (NSString *)reuseIdentifier
{
    return @"VLCBrowseSharingBandCell";
}

+ (CGFloat)heightForAddressCount:(NSInteger)count joinedToChip:(BOOL)joined
{
    if (count <= 0) {
        return 0.0;
    }

    CGFloat bandHeight = 2 * kVLCBrowseBandPadding + count * kVLCBrowseBandRowHeight
                         + (count - 1) * kVLCBrowseBandRowGap;
    return joined ? bandHeight - kVLCBrowseBandChipOverlap : bandHeight;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _rowViews = [NSMutableArray array];
        [self setupViews];
    }
    return self;
}

- (void)setupViews
{
    self.clipsToBounds = NO;
    self.contentView.clipsToBounds = NO;

    _bandView = [[UIView alloc] init];
    _bandView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_bandView];

    _bandTopConstraint = [_bandView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor];

    [NSLayoutConstraint activateConstraints:@[
        _bandTopConstraint,
        [_bandView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [_bandView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [_bandView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
    ]];
}

- (void)configureWithAddresses:(NSArray<NSString *> *)addresses joinedToChip:(BOOL)joined
{
    ColorPalette *themeColors = PresentationTheme.current.colors;

    _addresses = [addresses copy];
    _bandView.backgroundColor = themeColors.accentTint;
    _bandTopConstraint.constant = joined ? -kVLCBrowseBandChipOverlap : 0.0;

    /* the top right corner joins the sharing chip above, so it stays square */
    CACornerMask maskedCorners = joined ? kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner
                                        : kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner |
                                          kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    [_bandView roundCornersWithRadius:kVLCBrowseBandCornerRadius maskedCorners:maskedCorners];

    [self rebuildRows];
}

- (void)rebuildRows
{
    for (UIControl *row in _rowViews) {
        [row removeFromSuperview];
    }
    [_rowViews removeAllObjects];

    ColorPalette *themeColors = PresentationTheme.current.colors;
    NSUInteger count = _addresses.count;
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray array];

    for (NSUInteger i = 0; i < count; i++) {
        UIControl *row = [[UIControl alloc] init];
        row.translatesAutoresizingMaskIntoConstraints = NO;
        row.backgroundColor = themeColors.cardBackground;
        row.tag = i;
        [row roundCornersWithRadius:kVLCBrowseBandRowRadius];
        [row addTarget:self action:@selector(copyAddress:) forControlEvents:UIControlEventTouchUpInside];
        [_bandView addSubview:row];

        UILabel *valueLabel = [[UILabel alloc] init];
        valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
        valueLabel.font = [self addressFont];
        valueLabel.textColor = themeColors.cellTextColor;
        valueLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        valueLabel.text = [self displayStringForAddress:_addresses[i]];
        [row addSubview:valueLabel];

        UIImageView *copyGlyph = [[UIImageView alloc] init];
        copyGlyph.translatesAutoresizingMaskIntoConstraints = NO;
        copyGlyph.contentMode = UIViewContentModeScaleAspectFit;
        copyGlyph.tintColor = themeColors.orangeUI;
        if (@available(iOS 13.0, *)) {
            copyGlyph.image = [UIImage systemImageNamed:@"doc.on.doc"];
        }
        [row addSubview:copyGlyph];

        row.isAccessibilityElement = YES;
        row.accessibilityTraits = UIAccessibilityTraitButton;
        row.accessibilityLabel = valueLabel.text;

        [constraints addObjectsFromArray:@[
            [row.leadingAnchor constraintEqualToAnchor:_bandView.leadingAnchor constant:kVLCBrowseBandPadding],
            [row.trailingAnchor constraintEqualToAnchor:_bandView.trailingAnchor constant:-kVLCBrowseBandPadding],
            [row.heightAnchor constraintEqualToConstant:kVLCBrowseBandRowHeight],

            [valueLabel.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:12.0],
            [valueLabel.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],

            [copyGlyph.leadingAnchor constraintGreaterThanOrEqualToAnchor:valueLabel.trailingAnchor constant:8.0],
            [copyGlyph.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-12.0],
            [copyGlyph.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
            [copyGlyph.widthAnchor constraintEqualToConstant:kVLCBrowseBandGlyphSide],
            [copyGlyph.heightAnchor constraintEqualToConstant:kVLCBrowseBandGlyphSide]
        ]];

        if (i == 0) {
            [constraints addObject:[row.topAnchor constraintEqualToAnchor:_bandView.topAnchor
                                                                 constant:kVLCBrowseBandPadding]];
        } else {
            [constraints addObject:[row.topAnchor constraintEqualToAnchor:_rowViews.lastObject.bottomAnchor
                                                                 constant:kVLCBrowseBandRowGap]];
        }

        [_rowViews addObject:row];
    }

    [NSLayoutConstraint activateConstraints:constraints];
}

- (UIFont *)addressFont
{
    if (@available(iOS 13.0, *)) {
        return [UIFont monospacedSystemFontOfSize:14.0 weight:UIFontWeightSemibold];
    }

    return [UIFont fontWithName:@"Menlo-Bold" size:14.0];
}

- (NSString *)displayStringForAddress:(NSString *)address
{
    NSURLComponents *components = [NSURLComponents componentsWithString:address];
    if (!components.host) {
        return address;
    }

    if (components.port) {
        return [NSString stringWithFormat:@"%@:%@", components.host, components.port];
    }

    return components.host;
}

- (void)copyAddress:(UIControl *)sender
{
    NSUInteger index = sender.tag;
    if (index >= _addresses.count) {
        return;
    }

    [UIPasteboard generalPasteboard].string = _addresses[index];
    [UIAlertController autoDismissableWithTitle:NSLocalizedString(@"WEBINTF_TITLE", nil)
                                        message:NSLocalizedString(@"WEBINTF_ADDRESS_COPIED", nil)
                                   dismissDelay:3.0];
}

@end
