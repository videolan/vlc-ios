/*****************************************************************************
 * VLCPlaceholderArtworkView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaceholderArtworkView.h"
#import "VLCPlaceholderArtwork.h"

@implementation VLCPlaceholderArtworkView
{
    UILabel *_initialsLabel;
    CGFloat _initialsSide;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        [self setupInitialsLabel];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
        [self setupInitialsLabel];
    return self;
}

- (void)setupInitialsLabel
{
    _initialsLabel = [[UILabel alloc] init];
    _initialsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _initialsLabel.textAlignment = NSTextAlignmentCenter;
    _initialsLabel.isAccessibilityElement = NO;
    [self addSubview:_initialsLabel];

    [NSLayoutConstraint activateConstraints:@[
        [_initialsLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_initialsLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_initialsLabel.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor]
    ]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGSize size = self.bounds.size;
    CGFloat side = MIN(size.width, size.height);
    if (side == _initialsSide)
        return;

    _initialsSide = side;
    _initialsLabel.font = [UIFont systemFontOfSize:[VLCPlaceholderArtwork fontSizeForSide:side] weight:UIFontWeightHeavy];
}

- (void)setName:(NSString *)name
{
    _name = [name copy];
    self.backgroundColor = [VLCPlaceholderArtwork backgroundColorForName:name];
    _initialsLabel.textColor = [VLCPlaceholderArtwork foregroundColorForName:name];
    _initialsLabel.text = [VLCPlaceholderArtwork initialsForName:name];
}

@end
