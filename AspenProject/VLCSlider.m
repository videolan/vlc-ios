//
//  VLCSlider.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 06.06.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCSlider.h"

@implementation VLCOBSlider

- (void)awakeFromNib
{
    self.minimumValueImage = [UIImage imageNamed:@"sliderminiValue"];
    self.maximumValueImage = [UIImage imageNamed:@"slidermaxValue"];
    [self setMinimumTrackImage:[UIImage imageNamed:@"sliderminimumTrack"] forState:UIControlStateNormal];
    [self setMaximumTrackImage:[UIImage imageNamed:@"slidermaximumTrack"] forState:UIControlStateNormal];
    [self setThumbImage:[UIImage imageNamed:@"ballSlider"] forState:UIControlStateNormal];
    [self setThumbImage:[UIImage imageNamed:@"knobSlider"] forState:UIControlStateHighlighted];
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    CGRect returnValue = [super trackRectForBounds:bounds];
    returnValue.origin.x = 5.;
    returnValue.origin.y = 7.;
    returnValue.size.width = bounds.size.width - 10.;
    return returnValue;
}

@end


@implementation VLCSlider

- (void)awakeFromNib
{
    self.minimumValueImage = [UIImage imageNamed:@"sliderminiValue"];
    self.maximumValueImage = [UIImage imageNamed:@"slidermaxValue"];
    [self setMinimumTrackImage:[UIImage imageNamed:@"sliderminimumTrack"] forState:UIControlStateNormal];
    [self setMaximumTrackImage:[UIImage imageNamed:@"slidermaximumTrack"] forState:UIControlStateNormal];
    [self setThumbImage:[UIImage imageNamed:@"ballSlider"] forState:UIControlStateNormal];
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    CGRect returnValue = [super trackRectForBounds:bounds];
    returnValue.origin.x = 5.;
    returnValue.origin.y = 7.;
    returnValue.size.width = bounds.size.width - 10.;
    return returnValue;
}

@end
