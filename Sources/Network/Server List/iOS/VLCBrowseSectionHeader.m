/*****************************************************************************
 * VLCBrowseSectionHeader.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCBrowseSectionHeader.h"

#import "VLC-Swift.h"

static CGFloat const kVLCBrowseHeaderSideMargin = 20.0;
static CGFloat const kVLCBrowseHeaderHeight = 44.0;
static CGFloat const kVLCBrowseHeaderButtonSide = 44.0;

@implementation VLCBrowseSectionHeader
{
    UILabel *_titleLabel;
    UIButton *_addButton;
}

+ (NSString *)reuseIdentifier
{
    return @"VLCBrowseSectionHeader";
}

+ (CGFloat)height
{
    return kVLCBrowseHeaderHeight;
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
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightBold];
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.minimumScaleFactor = 0.8;
    [self addSubview:_titleLabel];

    _addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _addButton.translatesAutoresizingMaskIntoConstraints = NO;
    _addButton.hidden = YES;
    _addButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *symbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:20.0
                                                                                                         weight:UIImageSymbolWeightSemibold];
        [_addButton setPreferredSymbolConfiguration:symbolConfiguration forImageInState:UIControlStateNormal];
        [_addButton setImage:[UIImage systemImageNamed:@"plus"] forState:UIControlStateNormal];
    } else {
        [_addButton setTitle:@"+" forState:UIControlStateNormal];
        _addButton.titleLabel.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightMedium];
    }
    _addButton.accessibilityLabel = NSLocalizedString(@"CONNECT_TO_SERVER", nil);
    [_addButton addTarget:self action:@selector(addAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_addButton];

    [NSLayoutConstraint activateConstraints:@[
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor
                                                  constant:kVLCBrowseHeaderSideMargin],
        [_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

        [_addButton.leadingAnchor constraintGreaterThanOrEqualToAnchor:_titleLabel.trailingAnchor constant:8.0],
        [_addButton.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor
                                                  constant:-kVLCBrowseHeaderSideMargin],
        [_addButton.centerYAnchor constraintEqualToAnchor:_titleLabel.centerYAnchor],
        [_addButton.widthAnchor constraintEqualToConstant:kVLCBrowseHeaderButtonSide],
        [_addButton.heightAnchor constraintEqualToConstant:kVLCBrowseHeaderButtonSide]
    ]];
}

- (void)configureWithTitle:(NSString *)title showsAddButton:(BOOL)showsAddButton
{
    ColorPalette *themeColors = PresentationTheme.current.colors;

    _titleLabel.text = title;
    _titleLabel.textColor = themeColors.cellTextColor;

    _addButton.hidden = !showsAddButton;
    _addButton.tintColor = themeColors.orangeUI;
    [_addButton setTitleColor:themeColors.orangeUI forState:UIControlStateNormal];
}

- (void)addAction
{
    [self.delegate sectionHeaderDidTriggerAction:self];
}

@end
