/*****************************************************************************
 * VLCSlider.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSlider.h"

@implementation VLCOBSlider

- (void)awakeFromNib
{
    self.accessibilityLabel = NSLocalizedString(@"PLAYBACK_POSITION", nil);
    self.isAccessibilityElement = YES;

    if (SYSTEM_RUNS_IOS7_OR_LATER)
        [self setThumbImage:[UIImage imageNamed:@"modernSliderKnob"] forState:UIControlStateNormal];
    else {
        self.minimumValueImage = [UIImage imageNamed:@"sliderminiValue"];
        self.maximumValueImage = [UIImage imageNamed:@"slidermaxValue"];
        [self setMinimumTrackImage:[UIImage imageNamed:@"sliderminimumTrack"] forState:UIControlStateNormal];
        [self setMaximumTrackImage:[UIImage imageNamed:@"slidermaximumTrack"] forState:UIControlStateNormal];
        [self setThumbImage:[UIImage imageNamed:@"ballSlider"] forState:UIControlStateNormal];
        [self setThumbImage:[UIImage imageNamed:@"knobSlider"] forState:UIControlStateHighlighted];
    }
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    CGRect returnValue = [super trackRectForBounds:bounds];
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        return returnValue;

    returnValue.origin.x = 5.;
    returnValue.origin.y = 7.;
    returnValue.size.width = bounds.size.width - 10.;
    return returnValue;
}

@end


@implementation VLCSlider

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        [self setThumbImage:[UIImage imageNamed:@"modernSliderKnob"] forState:UIControlStateNormal];
    return self;
}

- (void)awakeFromNib
{
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        [self setThumbImage:[UIImage imageNamed:@"modernSliderKnob"] forState:UIControlStateNormal];
    else {
        self.minimumValueImage = [UIImage imageNamed:@"sliderminiValue"];
        self.maximumValueImage = [UIImage imageNamed:@"slidermaxValue"];
        [self setMinimumTrackImage:[UIImage imageNamed:@"sliderminimumTrack"] forState:UIControlStateNormal];
        [self setMaximumTrackImage:[UIImage imageNamed:@"slidermaximumTrack"] forState:UIControlStateNormal];
        [self setThumbImage:[UIImage imageNamed:@"ballSlider"] forState:UIControlStateNormal];
    }
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    CGRect returnValue = [super trackRectForBounds:bounds];
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        return returnValue;

    returnValue.origin.x = 5.;
    if (!SYSTEM_RUNS_IOS7_OR_LATER)
        returnValue.origin.y = 7.;
    returnValue.size.width = bounds.size.width - 10.;
    return returnValue;
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
