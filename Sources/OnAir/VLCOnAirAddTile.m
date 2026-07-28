/*****************************************************************************
 * VLCOnAirAddTile.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOnAirAddTile.h"

#import "VLC-Swift.h"

static CGFloat const kVLCOnAirAddTileCornerRadius = 18.0;
static CGFloat const kVLCOnAirAddTileLineWidth = 1.5;

@interface VLCOnAirDashedBorderView : UIView

- (void)setStrokeColor:(UIColor *)strokeColor;

@end

@implementation VLCOnAirDashedBorderView

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CAShapeLayer *shapeLayer = (CAShapeLayer *)self.layer;
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        shapeLayer.lineWidth = kVLCOnAirAddTileLineWidth;
        shapeLayer.lineDashPattern = @[@6, @5];
    }
    return self;
}

- (void)setStrokeColor:(UIColor *)strokeColor
{
    ((CAShapeLayer *)self.layer).strokeColor = strokeColor.CGColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect insetBounds = CGRectInset(self.bounds, kVLCOnAirAddTileLineWidth / 2.0, kVLCOnAirAddTileLineWidth / 2.0);
    ((CAShapeLayer *)self.layer).path = [UIBezierPath bezierPathWithRoundedRect:insetBounds
                                                                  cornerRadius:kVLCOnAirAddTileCornerRadius].CGPath;
}

@end

@implementation VLCOnAirAddTile
{
    VLCOnAirDashedBorderView *_outlineContainer;
    UILabel *_plusLabel;
    UILabel *_nameLabel;
}

+ (NSString *)reuseIdentifier
{
    return @"VLCOnAirAddTile";
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
        [self updateTheme];
    }
    return self;
}

- (void)setupViews
{
    _outlineContainer = [[VLCOnAirDashedBorderView alloc] init];
    _outlineContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_outlineContainer];

    _plusLabel = [[UILabel alloc] init];
    _plusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _plusLabel.textAlignment = NSTextAlignmentCenter;
    _plusLabel.font = [UIFont systemFontOfSize:32.0 weight:UIFontWeightLight];
    _plusLabel.text = @"+";
    [_outlineContainer addSubview:_plusLabel];

    _nameLabel = [[UILabel alloc] init];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    _nameLabel.numberOfLines = 1;
    _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    _nameLabel.text = NSLocalizedString(@"ONAIR_ADD", nil);
    [self.contentView addSubview:_nameLabel];

    [NSLayoutConstraint activateConstraints:@[
        [_outlineContainer.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [_outlineContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [_outlineContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [_outlineContainer.heightAnchor constraintEqualToAnchor:_outlineContainer.widthAnchor],

        [_plusLabel.centerXAnchor constraintEqualToAnchor:_outlineContainer.centerXAnchor],
        [_plusLabel.centerYAnchor constraintEqualToAnchor:_outlineContainer.centerYAnchor],

        [_nameLabel.topAnchor constraintEqualToAnchor:_outlineContainer.bottomAnchor constant:8.0],
        [_nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:2.0],
        [_nameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-2.0],
        [_nameLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor]
    ]];
}

- (void)updateTheme
{
    ColorPalette *themeColors = PresentationTheme.current.colors;
    [_outlineContainer setStrokeColor:themeColors.cellDetailTextColor];
    _plusLabel.textColor = themeColors.cellDetailTextColor;
    _nameLabel.textColor = themeColors.cellDetailTextColor;
}

@end
