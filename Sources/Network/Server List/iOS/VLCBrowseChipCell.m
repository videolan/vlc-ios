/*****************************************************************************
 * VLCBrowseChipCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCBrowseChipCell.h"

#import "VLC-Swift.h"

static CGFloat const kVLCBrowseChipCornerRadius = 9.0;
static CGFloat const kVLCBrowseChipWellSide = 30.0;
static CGFloat const kVLCBrowseChipWellRadius = 4.0;
static CGFloat const kVLCBrowseChipGlyphSide = 19.0;

@implementation VLCBrowseChipCell
{
    UIView *_glyphWell;
    UIImageView *_glyphView;
    UILabel *_titleLabel;
}

+ (NSString *)reuseIdentifier
{
    return @"VLCBrowseChipCell";
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews
{
    [self.contentView roundCornersWithRadius:kVLCBrowseChipCornerRadius];

    _glyphWell = [[UIView alloc] init];
    _glyphWell.translatesAutoresizingMaskIntoConstraints = NO;
    [_glyphWell roundCornersWithRadius:kVLCBrowseChipWellRadius];
    _glyphWell.clipsToBounds = YES;
    [self.contentView addSubview:_glyphWell];

    _glyphView = [[UIImageView alloc] init];
    _glyphView.translatesAutoresizingMaskIntoConstraints = NO;
    _glyphView.contentMode = UIViewContentModeScaleAspectFit;
    [_glyphWell addSubview:_glyphView];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    _titleLabel.numberOfLines = 2;
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.minimumScaleFactor = 0.8;
    [self.contentView addSubview:_titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [_glyphWell.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:6.0],
        [_glyphWell.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [_glyphWell.widthAnchor constraintEqualToConstant:kVLCBrowseChipWellSide],
        [_glyphWell.heightAnchor constraintEqualToConstant:kVLCBrowseChipWellSide],

        [_glyphView.centerXAnchor constraintEqualToAnchor:_glyphWell.centerXAnchor],
        [_glyphView.centerYAnchor constraintEqualToAnchor:_glyphWell.centerYAnchor],
        [_glyphView.widthAnchor constraintEqualToConstant:kVLCBrowseChipGlyphSide],
        [_glyphView.heightAnchor constraintEqualToConstant:kVLCBrowseChipGlyphSide],

        [_titleLabel.leadingAnchor constraintEqualToAnchor:_glyphWell.trailingAnchor constant:10.0],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-11.0],
        [_titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [_titleLabel.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor constant:6.0],
        [_titleLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-6.0]
    ]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowRadius = 3.0;
    self.layer.shadowOpacity = 0.07;
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                       cornerRadius:kVLCBrowseChipCornerRadius].CGPath;
}

- (void)configureWithTitle:(NSString *)title image:(UIImage *)image
{
    ColorPalette *themeColors = PresentationTheme.current.colors;

    self.contentView.backgroundColor = themeColors.cardBackground;

    _glyphWell.backgroundColor = themeColors.accentTint;
    _glyphView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _glyphView.tintColor = themeColors.orangeUI;

    _titleLabel.text = title;
    _titleLabel.textColor = themeColors.cellTextColor;

    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;
    self.accessibilityLabel = title;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.contentView.alpha = highlighted ? 0.6 : 1.0;
}

@end
