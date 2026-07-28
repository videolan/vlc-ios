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

@implementation VLCOnAirPromptCell
{
    UIView *_cardView;
    UIView *_glyphWell;
    UIImageView *_glyphView;
    UILabel *_titleLabel;
    UILabel *_bodyLabel;
    UIButton *_primaryButton;
    UIButton *_secondaryButton;
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
        if (@available(iOS 14.0, *)) {
            self.backgroundConfiguration = [UIBackgroundConfiguration clearConfiguration];
        }
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

    _glyphWell = [[UIView alloc] init];
    _glyphWell.translatesAutoresizingMaskIntoConstraints = NO;
    [_glyphWell roundCornersWithRadius:10.0];
    [_cardView addSubview:_glyphWell];

    _glyphView = [[UIImageView alloc] init];
    _glyphView.translatesAutoresizingMaskIntoConstraints = NO;
    _glyphView.contentMode = UIViewContentModeScaleAspectFit;
    [_glyphWell addSubview:_glyphView];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    _titleLabel.numberOfLines = 0;
    [_cardView addSubview:_titleLabel];

    _bodyLabel = [[UILabel alloc] init];
    _bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _bodyLabel.font = [UIFont systemFontOfSize:14.0];
    _bodyLabel.numberOfLines = 0;
    [_cardView addSubview:_bodyLabel];

    _primaryButton = [self buttonWithTag:0];
    _secondaryButton = [self buttonWithTag:1];

    [NSLayoutConstraint activateConstraints:@[
        [_cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [_cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [_cardView.leadingAnchor constraintEqualToAnchor:self.contentView.safeAreaLayoutGuide.leadingAnchor constant:kVLCOnAirPromptSideMargin],
        [_cardView.trailingAnchor constraintEqualToAnchor:self.contentView.safeAreaLayoutGuide.trailingAnchor constant:-kVLCOnAirPromptSideMargin],

        [_glyphWell.topAnchor constraintEqualToAnchor:_cardView.topAnchor constant:kVLCOnAirPromptPadding],
        [_glyphWell.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:kVLCOnAirPromptPadding],
        [_glyphWell.widthAnchor constraintEqualToConstant:kVLCOnAirPromptWellSide],
        [_glyphWell.heightAnchor constraintEqualToConstant:kVLCOnAirPromptWellSide],
        [_glyphWell.bottomAnchor constraintLessThanOrEqualToAnchor:_cardView.bottomAnchor constant:-kVLCOnAirPromptPadding],

        [_glyphView.centerXAnchor constraintEqualToAnchor:_glyphWell.centerXAnchor],
        [_glyphView.centerYAnchor constraintEqualToAnchor:_glyphWell.centerYAnchor],
        [_glyphView.widthAnchor constraintEqualToConstant:20.0],
        [_glyphView.heightAnchor constraintEqualToConstant:20.0],

        [_titleLabel.topAnchor constraintEqualToAnchor:_cardView.topAnchor constant:kVLCOnAirPromptPadding],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:_glyphWell.trailingAnchor constant:14.0],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-kVLCOnAirPromptPadding],

        [_bodyLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:2.0],
        [_bodyLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
        [_bodyLabel.trailingAnchor constraintEqualToAnchor:_titleLabel.trailingAnchor],

        [_primaryButton.topAnchor constraintEqualToAnchor:_bodyLabel.bottomAnchor constant:12.0],
        [_primaryButton.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
        [_primaryButton.heightAnchor constraintEqualToConstant:kVLCOnAirPromptButtonHeight],
        [_primaryButton.bottomAnchor constraintEqualToAnchor:_cardView.bottomAnchor constant:-kVLCOnAirPromptPadding],

        [_secondaryButton.leadingAnchor constraintEqualToAnchor:_primaryButton.trailingAnchor constant:10.0],
        [_secondaryButton.centerYAnchor constraintEqualToAnchor:_primaryButton.centerYAnchor],
        [_secondaryButton.heightAnchor constraintEqualToConstant:kVLCOnAirPromptButtonHeight],
        [_secondaryButton.trailingAnchor constraintLessThanOrEqualToAnchor:_titleLabel.trailingAnchor]
    ]];
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
    [_cardView addSubview:button];
    return button;
}

- (void)configureWithGlyph:(UIImage *)glyph
                     title:(NSString *)title
                      body:(NSString *)body
              primaryTitle:(NSString *)primaryTitle
            secondaryTitle:(NSString *)secondaryTitle
{
    ColorPalette *themeColors = PresentationTheme.current.colors;
    UIColor *accent = themeColors.orangeUI;

    if (@available(iOS 13.0, *)) {
        _cardView.backgroundColor = UIColor.tertiarySystemBackgroundColor;
    } else {
        _cardView.backgroundColor = themeColors.cellBackgroundA;
    }

    _glyphWell.backgroundColor = [accent colorWithAlphaComponent:0.13];
    _glyphView.image = [glyph imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _glyphView.tintColor = accent;

    _titleLabel.text = title;
    _titleLabel.textColor = themeColors.cellTextColor;

    _bodyLabel.text = body;
    _bodyLabel.textColor = themeColors.cellDetailTextColor;

    [_primaryButton setTitle:primaryTitle forState:UIControlStateNormal];
    [_primaryButton styleAsPrimaryAction];

    _secondaryButton.hidden = (secondaryTitle == nil);
    if (secondaryTitle) {
        [_secondaryButton setTitle:secondaryTitle forState:UIControlStateNormal];
        [_secondaryButton styleAsSecondaryAction];
    }
}

- (void)buttonAction:(UIButton *)sender
{
    [self.delegate promptCell:self didTapButtonAtIndex:sender.tag];
}

@end
