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
    [self setThumbImage:[UIImage imageNamed:@"sliderKnob"] forState:UIControlStateNormal];
    [super awakeFromNib];
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
