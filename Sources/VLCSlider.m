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
