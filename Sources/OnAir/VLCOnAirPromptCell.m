/*****************************************************************************
 * VLCOnAirPromptCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOnAirPromptCell.h"

#import "VLC-Swift.h"

static CGFloat const kVLCOnAirPromptPadding = 16.0;
static CGFloat const kVLCOnAirPromptSideMargin = 20.0;
static CGFloat const kVLCOnAirPromptWellSide = 38.0;
static CGFloat const kVLCOnAirPromptButtonHeight = 38.0;
static CGFloat const kVLCOnAirPromptButtonSpacing = 10.0;
static CGFloat const kVLCOnAirPromptUnavailableSaturation = 0.25;
static CGFloat const kVLCOnAirPromptUnavailableOpacity = 0.38;

@implementation VLCOnAirPromptCell
{
    UIView *_cardView;
    UIView *_contentLayer;
    UIImageView *_stampView;
    UIView *_glyphWell;
    UIImageView *_glyphView;
    UILabel *_titleLabel;
    UIButton *_primaryButton;
    UIButton *_secondaryButton;
    NSArray<NSLayoutConstraint *> *_inlineButtonConstraints;
    NSArray<NSLayoutConstraint *> *_stackedButtonConstraints;
    BOOL _buttonsStacked;
}

+ (NSString *)reuseIdentifier
{
    return @"VLCOnAirPromptCell";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundView = [[UIView alloc] init];
        self.backgroundView.backgroundColor = [UIColor clearColor];
        self.backgroundConfiguration = [UIBackgroundConfiguration clearConfiguration];
        [self setupViews];
    }
    return self;
}

- (void)setupViews
{
    _cardView = [[UIView alloc] init];
    _cardView.translatesAutoresizingMaskIntoConstraints = NO;
    [_cardView roundCornersWithRadius:16.0];
    [self.contentView addSubview:_cardView];

    _contentLayer = [[UIView alloc] init];
    _contentLayer.translatesAutoresizingMaskIntoConstraints = NO;
    [_cardView addSubview:_contentLayer];

    _glyphWell = [[UIView alloc] init];
    _glyphWell.translatesAutoresizingMaskIntoConstraints = NO;
    [_glyphWell roundCornersWithRadius:10.0];
    [_contentLayer addSubview:_glyphWell];

    _glyphView = [[UIImageView alloc] init];
    _glyphView.translatesAutoresizingMaskIntoConstraints = NO;
    _glyphView.contentMode = UIViewContentModeScaleAspectFit;
    [_glyphWell addSubview:_glyphView];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:15.0];
    _titleLabel.numberOfLines = 0;
    [_contentLayer addSubview:_titleLabel];

    _primaryButton = [self buttonWithTag:0];
    _secondaryButton = [self buttonWithTag:1];
    [_secondaryButton setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh - 1
                                                      forAxis:UILayoutConstraintAxisHorizontal];

    _stampView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ComingSoonStamp"]];
    _stampView.translatesAutoresizingMaskIntoConstraints = NO;
    _stampView.hidden = YES;
    [_cardView addSubview:_stampView];

    [NSLayoutConstraint activateConstraints:@[
        [_cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [_cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [_cardView.leadingAnchor constraintEqualToAnchor:self.contentView.safeAreaLayoutGuide.leadingAnchor constant:kVLCOnAirPromptSideMargin],
        [_cardView.trailingAnchor constraintEqualToAnchor:self.contentView.safeAreaLayoutGuide.trailingAnchor constant:-kVLCOnAirPromptSideMargin],

        [_contentLayer.topAnchor constraintEqualToAnchor:_cardView.topAnchor],
        [_contentLayer.bottomAnchor constraintEqualToAnchor:_cardView.bottomAnchor],
        [_contentLayer.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor],
        [_contentLayer.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor],

        [_stampView.centerXAnchor constraintEqualToAnchor:_cardView.centerXAnchor],
        [_stampView.centerYAnchor constraintEqualToAnchor:_cardView.centerYAnchor],

        [_glyphWell.topAnchor constraintEqualToAnchor:_contentLayer.topAnchor constant:kVLCOnAirPromptPadding],
        [_glyphWell.leadingAnchor constraintEqualToAnchor:_contentLayer.leadingAnchor constant:kVLCOnAirPromptPadding],
        [_glyphWell.widthAnchor constraintEqualToConstant:kVLCOnAirPromptWellSide],
        [_glyphWell.heightAnchor constraintEqualToConstant:kVLCOnAirPromptWellSide],
        [_glyphWell.bottomAnchor constraintLessThanOrEqualToAnchor:_contentLayer.bottomAnchor constant:-kVLCOnAirPromptPadding],

        [_glyphView.centerXAnchor constraintEqualToAnchor:_glyphWell.centerXAnchor],
        [_glyphView.centerYAnchor constraintEqualToAnchor:_glyphWell.centerYAnchor],
        [_glyphView.widthAnchor constraintEqualToConstant:20.0],
        [_glyphView.heightAnchor constraintEqualToConstant:20.0],

        [_titleLabel.topAnchor constraintEqualToAnchor:_contentLayer.topAnchor constant:kVLCOnAirPromptPadding],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:_glyphWell.trailingAnchor constant:14.0],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:_contentLayer.trailingAnchor constant:-kVLCOnAirPromptPadding],

        [_primaryButton.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:12.0],
        [_primaryButton.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
        [_primaryButton.trailingAnchor constraintLessThanOrEqualToAnchor:_titleLabel.trailingAnchor],
        [_primaryButton.heightAnchor constraintEqualToConstant:kVLCOnAirPromptButtonHeight],

        [_secondaryButton.heightAnchor constraintEqualToConstant:kVLCOnAirPromptButtonHeight],
        [_secondaryButton.trailingAnchor constraintLessThanOrEqualToAnchor:_titleLabel.trailingAnchor]
    ]];

    _inlineButtonConstraints = @[
        [_primaryButton.bottomAnchor constraintEqualToAnchor:_contentLayer.bottomAnchor constant:-kVLCOnAirPromptPadding],
        [_secondaryButton.leadingAnchor constraintEqualToAnchor:_primaryButton.trailingAnchor constant:kVLCOnAirPromptButtonSpacing],
        [_secondaryButton.centerYAnchor constraintEqualToAnchor:_primaryButton.centerYAnchor]
    ];
    _stackedButtonConstraints = @[
        [_secondaryButton.topAnchor constraintEqualToAnchor:_primaryButton.bottomAnchor constant:kVLCOnAirPromptButtonSpacing],
        [_secondaryButton.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
        [_secondaryButton.bottomAnchor constraintEqualToAnchor:_contentLayer.bottomAnchor constant:-kVLCOnAirPromptPadding]
    ];
    [NSLayoutConstraint activateConstraints:_inlineButtonConstraints];
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize
        withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority
              verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
    CGRect bounds = self.bounds;
    bounds.size.width = targetSize.width;
    self.bounds = bounds;
    [self layoutIfNeeded];
    [self updateButtonArrangement];

    return [super systemLayoutSizeFittingSize:targetSize
                withHorizontalFittingPriority:horizontalFittingPriority
                      verticalFittingPriority:verticalFittingPriority];
}

- (void)updateButtonArrangement
{
    CGFloat availableWidth = CGRectGetWidth(_titleLabel.bounds);
    if (availableWidth <= 0.0) {
        return;
    }

    CGFloat inlineWidth = _primaryButton.intrinsicContentSize.width + kVLCOnAirPromptButtonSpacing
                        + _secondaryButton.intrinsicContentSize.width;
    BOOL stacked = !_secondaryButton.hidden && inlineWidth > availableWidth;
    if (stacked == _buttonsStacked) {
        return;
    }

    _buttonsStacked = stacked;
    [NSLayoutConstraint deactivateConstraints:stacked ? _inlineButtonConstraints : _stackedButtonConstraints];
    [NSLayoutConstraint activateConstraints:stacked ? _stackedButtonConstraints : _inlineButtonConstraints];
}

- (UIButton *)buttonWithTag:(NSInteger)tag
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.tag = tag;
    [button roundCornersWithRadius:10.0];
    button.contentEdgeInsets = UIEdgeInsetsMake(9.0, 15.0, 9.0, 15.0);
    button.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.8;
    [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_contentLayer addSubview:button];
    return button;
}

- (void)configureWithGlyph:(UIImage *)glyph
                     title:(NSString *)title
              primaryTitle:(NSString *)primaryTitle
            secondaryTitle:(NSString *)secondaryTitle
          actionsAvailable:(BOOL)actionsAvailable
{
    ColorPalette *themeColors = PresentationTheme.current.colors;
    UIColor *accent = actionsAvailable ? themeColors.orangeUI
                                       : [themeColors.orangeUI desaturated:kVLCOnAirPromptUnavailableSaturation];

    _cardView.backgroundColor = themeColors.cardBackground;

    _contentLayer.alpha = actionsAvailable ? 1.0 : kVLCOnAirPromptUnavailableOpacity;
    _contentLayer.userInteractionEnabled = actionsAvailable;
    _stampView.hidden = actionsAvailable;

    _glyphWell.backgroundColor = actionsAvailable ? themeColors.accentTint
                                                  : [themeColors.accentTint desaturated:kVLCOnAirPromptUnavailableSaturation];
    _glyphView.image = [glyph imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _glyphView.tintColor = accent;

    _titleLabel.text = title;
    _titleLabel.textColor = themeColors.cellTextColor;

    [_primaryButton setTitle:primaryTitle forState:UIControlStateNormal];
    _primaryButton.enabled = actionsAvailable;
    [_primaryButton styleAsPrimaryAction];
    _primaryButton.backgroundColor = accent;

    _secondaryButton.hidden = (secondaryTitle == nil);
    if (secondaryTitle) {
        [_secondaryButton setTitle:secondaryTitle forState:UIControlStateNormal];
        _secondaryButton.enabled = actionsAvailable;
        [_secondaryButton styleAsSecondaryAction];
    }
}

- (void)buttonAction:(UIButton *)sender
{
    [self.delegate promptCell:self didTapButtonAtIndex:sender.tag];
}

@end
