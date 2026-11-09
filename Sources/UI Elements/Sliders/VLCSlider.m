/*****************************************************************************
 * VLCSlider.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSlider.h"
#import "VLC-Swift.h"

@implementation VLCOBSlider
{
    UITapGestureRecognizer *_seekTapRecognizer;
}

- (void)awakeFromNib
{
    self.accessibilityLabel = NSLocalizedString(@"PLAYBACK_POSITION", nil);
    [self setThumbImage:[UIImage imageNamed:@"sliderKnob"] forState:UIControlStateNormal];
    [super awakeFromNib];
}

- (void)setSeekOnTap:(BOOL)seekOnTap
{
    _seekOnTap = seekOnTap;
    if (!_seekTapRecognizer) {
        _seekTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
        _seekTapRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:_seekTapRecognizer];
    }
    _seekTapRecognizer.enabled = seekOnTap;
}

- (void)didTap:(UITapGestureRecognizer *)recognizer
{
    if (!self.enabled)
        return;

    CGRect bounds = self.bounds;
    CGRect trackRect = [self trackRectForBounds:bounds];
    CGFloat startX = CGRectGetMidX([self thumbRectForBounds:bounds trackRect:trackRect value:self.minimumValue]);
    CGFloat endX = CGRectGetMidX([self thumbRectForBounds:bounds trackRect:trackRect value:self.maximumValue]);
    if (endX <= startX)
        return;

    CGFloat fraction = MIN(MAX(([recognizer locationInView:self].x - startX) / (endX - startX), 0.), 1.);
    self.value = self.minimumValue + fraction * (self.maximumValue - self.minimumValue);
    [self sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
}

@end


@implementation VLCSlider

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        [self setThumbImage:[UIImage imageNamed:@"sliderKnob"] forState:UIControlStateNormal];
    return self;
}

- (void)awakeFromNib
{
    [self setThumbImage:[UIImage imageNamed:@"sliderKnob"] forState:UIControlStateNormal];
    [super awakeFromNib];
}

@end

@interface VLCResettingSlider ()
@property (nonatomic, weak) UITapGestureRecognizer *doubleTapRecognizer;
@end

@implementation VLCResettingSlider
- (void)awakeFromNib
{
    [super awakeFromNib];
    if (self.resetOnDoubleTap) {
        [self setResetOnDoubleTap:YES];
    }
    
}
- (void)setResetOnDoubleTap:(BOOL)resetOnDoubleTap
{
    _resetOnDoubleTap = resetOnDoubleTap;
    if (resetOnDoubleTap && self.doubleTapRecognizer == nil) {
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTap:)];
        recognizer.numberOfTapsRequired = 2;
        [self addGestureRecognizer:recognizer];
        self.doubleTapRecognizer = recognizer;
    } else if (!resetOnDoubleTap) {
        UITapGestureRecognizer *recognizer = self.doubleTapRecognizer;
        [self removeGestureRecognizer:recognizer];
        self.doubleTapRecognizer = nil;
    }
}

- (IBAction)didDoubleTap:(id)sender {
    self.value = self.defaultValue;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
