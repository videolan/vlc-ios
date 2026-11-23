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

@implementation VLCBrowseSectionHeader
{
    UILabel *_titleLabel;
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

    [NSLayoutConstraint activateConstraints:@[
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor
                                                  constant:kVLCBrowseHeaderSideMargin],
        [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor
                                                             constant:-kVLCBrowseHeaderSideMargin],
        [_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
    ]];
}

- (void)configureWithTitle:(NSString *)title
{
    _titleLabel.text = title;
    _titleLabel.textColor = PresentationTheme.current.colors.cellTextColor;
}

@end
