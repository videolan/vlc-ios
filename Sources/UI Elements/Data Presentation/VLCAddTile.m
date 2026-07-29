/*****************************************************************************
 * VLCAddTile.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAddTile.h"

#import "VLC-Swift.h"

static CGFloat const kVLCAddTileDefaultCornerRadius = 18.0;
static CGFloat const kVLCAddTileLineWidth = 1.5;

@interface VLCDashedBorderView : UIView

@property (nonatomic) CGFloat cornerRadius;

- (void)setStrokeColor:(UIColor *)strokeColor;

@end

@implementation VLCDashedBorderView

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _cornerRadius = kVLCAddTileDefaultCornerRadius;

        CAShapeLayer *shapeLayer = (CAShapeLayer *)self.layer;
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        shapeLayer.lineWidth = kVLCAddTileLineWidth;
        shapeLayer.lineDashPattern = @[@6, @5];
    }
    return self;
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius == cornerRadius) {
        return;
    }

    _cornerRadius = cornerRadius;
    [self setNeedsLayout];
}

- (void)setStrokeColor:(UIColor *)strokeColor
{
    ((CAShapeLayer *)self.layer).strokeColor = strokeColor.CGColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect insetBounds = CGRectInset(self.bounds, kVLCAddTileLineWidth / 2.0, kVLCAddTileLineWidth / 2.0);
    ((CAShapeLayer *)self.layer).path = [UIBezierPath bezierPathWithRoundedRect:insetBounds
                                                                  cornerRadius:_cornerRadius].CGPath;
}

@end

@implementation VLCAddTile
{
    VLCDashedBorderView *_outlineContainer;
    UILabel *_plusLabel;
    UILabel *_nameLabel;
}

+ (NSString *)reuseIdentifier
{
    return @"VLCAddTile";
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _outlineCornerRadius = kVLCAddTileDefaultCornerRadius;
        [self setupViews];
    }
    return self;
}

- (void)setupViews
{
    _outlineContainer = [[VLCDashedBorderView alloc] init];
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
    _nameLabel.adjustsFontSizeToFitWidth = YES;
    _nameLabel.minimumScaleFactor = 0.8;
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

- (void)setOutlineCornerRadius:(CGFloat)outlineCornerRadius
{
    _outlineCornerRadius = outlineCornerRadius;
    _outlineContainer.cornerRadius = outlineCornerRadius;
}

- (void)configureWithTitle:(NSString *)title
{
    ColorPalette *themeColors = PresentationTheme.current.colors;

    [_outlineContainer setStrokeColor:themeColors.cellDetailTextColor];
    _plusLabel.textColor = themeColors.cellDetailTextColor;
    _nameLabel.textColor = themeColors.cellDetailTextColor;
    _nameLabel.text = title;

    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;
    self.accessibilityLabel = title;
}

@end
