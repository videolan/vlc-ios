//
//  VLCMaskView.m
//  VLC for iOS
//
//  Created by Tobias Conradi on 07.11.15.
//  Copyright © 2015 VideoLAN. All rights reserved.
//

#import "VLCMaskView.h"
#import <QuartzCore/QuartzCore.h>

@interface VLCMaskView()
@property (nonatomic) CAGradientLayer *gradientLayer;
@end

@implementation VLCMaskView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.layer addSublayer:self.gradientLayer];
        [self updateGradientLayer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self.layer addSublayer:self.gradientLayer];
        [self updateGradientLayer];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateGradientLayer];
}

- (void)updateGradientLayer
{
    CGSize size = self.bounds.size;
    CGFloat height = size.height;

    self.gradientLayer.frame = CGRectMake(0, 0, size.width, height);
    self.gradientLayer.locations = @[@(self.maskEnd / height), @(self.maskStart / height)];
}


#pragma mark - Properties

- (CAGradientLayer *)gradientLayer
{
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor, (id)[UIColor colorWithWhite:0.0 alpha:1.0].CGColor];
    }
    return _gradientLayer;
}

- (void)setMaskStart:(CGFloat)maskStart
{
    _maskStart = maskStart;
    [self updateGradientLayer];
}

- (void)setMaskEnd:(CGFloat)maskEnd
{
    _maskEnd = maskEnd;
    [self updateGradientLayer];
}
@end
