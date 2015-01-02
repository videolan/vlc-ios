/*****************************************************************************
 * VLCEqualizerView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan dot org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCEqualizerView.h"

@interface VLCEqualizerView ()
{
    UISlider *_preAmp_slider;
    UISlider *_60_slider;
    UISlider *_170_slider;
    UISlider *_310_slider;
    UISlider *_600_slider;
    UISlider *_1K_slider;
    UISlider *_3K_slider;
    UISlider *_6K_slider;
    UISlider *_12K_slider;
    UISlider *_14K_slider;
    UISlider *_16K_slider;
}

@end

@implementation VLCEqualizerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (!self)
        return self;

#define horizontal_padding 6.
#define vertical_padding 8.
#define spacer 8.

    CGFloat sliderHeight = frame.size.height - (vertical_padding * 2.);
    CGFloat sliderWidth = (frame.size.width - (spacer * 10.)) / 11.;
    CGFloat sliderY = (sliderHeight / 2.) - horizontal_padding;

    _preAmp_slider = [[UISlider alloc] initWithFrame:CGRectMake(-sliderWidth + horizontal_padding, sliderY, sliderHeight, sliderWidth)];
    _preAmp_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _preAmp_slider.minimumValue = -20.;
    _preAmp_slider.maximumValue = 20.;
    [_preAmp_slider addTarget:self action:@selector(preampSliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_preAmp_slider];

    _60_slider = [[UISlider alloc] initWithFrame:CGRectMake(horizontal_padding * 2., sliderY, sliderHeight, sliderWidth)];
    _60_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _60_slider.tag = 0;
    _60_slider.minimumValue = -20.;
    _60_slider.maximumValue = 20.;
    [_60_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_60_slider];

    _170_slider = [[UISlider alloc] initWithFrame:CGRectMake(horizontal_padding * 3. + sliderWidth, sliderY, sliderHeight, sliderWidth)];
    _170_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _170_slider.tag = 1;
    _170_slider.minimumValue = -20.;
    _170_slider.maximumValue = 20.;
    [_170_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_170_slider];

    _310_slider = [[UISlider alloc] initWithFrame:CGRectMake(horizontal_padding * 4. + sliderWidth * 2., sliderY, sliderHeight, sliderWidth)];
    _310_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _310_slider.tag = 2;
    _310_slider.minimumValue = -20.;
    _310_slider.maximumValue = 20.;
    [_310_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_310_slider];

    _600_slider = [[UISlider alloc] initWithFrame:CGRectMake(horizontal_padding * 5. + sliderWidth * 3., sliderY, sliderHeight, sliderWidth)];
    _600_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _600_slider.tag = 3;
    _600_slider.minimumValue = -20.;
    _600_slider.maximumValue = 20.;
    [_600_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_600_slider];

    _1K_slider = [[UISlider alloc] initWithFrame:CGRectMake(horizontal_padding * 6. + sliderWidth * 4., sliderY, sliderHeight, sliderWidth)];
    _1K_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _1K_slider.tag = 4;
    _1K_slider.minimumValue = -20.;
    _1K_slider.maximumValue = 20.;
    [_1K_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_1K_slider];

    _3K_slider = [[UISlider alloc] initWithFrame:CGRectMake(horizontal_padding * 7. + sliderWidth * 5., sliderY, sliderHeight, sliderWidth)];
    _3K_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _3K_slider.tag = 5;
    _3K_slider.minimumValue = -20.;
    _3K_slider.maximumValue = 20.;
    [_3K_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_3K_slider];

    _6K_slider = [[UISlider alloc] initWithFrame:CGRectMake(horizontal_padding * 8. + sliderWidth * 6., sliderY, sliderHeight, sliderWidth)];
    _6K_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _6K_slider.tag = 6;
    _6K_slider.minimumValue = -20.;
    _6K_slider.maximumValue = 20.;
    [_6K_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_6K_slider];

    _12K_slider = [[UISlider alloc] initWithFrame:CGRectMake(horizontal_padding * 9. + sliderWidth * 7., sliderY, sliderHeight, sliderWidth)];
    _12K_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _12K_slider.tag = 7;
    _12K_slider.minimumValue = -20.;
    _12K_slider.maximumValue = 20.;
    [_12K_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_12K_slider],

    _14K_slider = [[UISlider alloc] initWithFrame:CGRectMake(horizontal_padding * 10. + sliderWidth * 8., sliderY, sliderHeight, sliderWidth)];
    _14K_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _14K_slider.tag = 8;
    _14K_slider.minimumValue = -20.;
    _14K_slider.maximumValue = 20.;
    [_14K_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_14K_slider];

    _16K_slider = [[UISlider alloc] initWithFrame:CGRectMake(horizontal_padding * 11. + sliderWidth * 9., sliderY, sliderHeight, sliderWidth)];
    _16K_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _16K_slider.tag = 9;
    _16K_slider.minimumValue = -20.;
    _16K_slider.maximumValue = 20.;
    [_16K_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_16K_slider];

    return self;
}

- (IBAction)sliderChangedValue:(UISlider *)sender
{
    if (self.delegate)
        [self.delegate setAmplification:[sender value] forBand:[sender tag]];
}

- (IBAction)preampSliderChangedValue:(UISlider *)sender
{
    if (self.delegate)
        [self.delegate setPreAmplification:sender.value];
}

- (void)reloadData
{
    if (self.delegate) {
        _preAmp_slider.value = [self.delegate preAmplification];
        _60_slider.value = [self.delegate amplificationOfBand:0];
        _170_slider.value = [self.delegate amplificationOfBand:1];
        _310_slider.value = [self.delegate amplificationOfBand:2];
        _600_slider.value = [self.delegate amplificationOfBand:3];
        _1K_slider.value = [self.delegate amplificationOfBand:4];
        _3K_slider.value = [self.delegate amplificationOfBand:5];
        _6K_slider.value = [self.delegate amplificationOfBand:6];
        _12K_slider.value = [self.delegate amplificationOfBand:7];
        _14K_slider.value = [self.delegate amplificationOfBand:8];
        _16K_slider.value = [self.delegate amplificationOfBand:9];
    }
}

@end
