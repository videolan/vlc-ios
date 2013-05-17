//
//  VLCStatusLabel.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 17.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCStatusLabel.h"

@implementation VLCStatusLabel

- (void)showStatusMessage:(NSString *)message
{
    self.text = message;
    [self setNeedsDisplay];
    [self _toggleVisibility:NO];

    _displayTimer = [NSTimer scheduledTimerWithTimeInterval:1.5
                                                     target:self
                                                   selector:@selector(_hideAgain)
                                                   userInfo:nil
                                                    repeats:NO];
}

- (void)_hideAgain
{
    [self _toggleVisibility:YES];
    _displayTimer = nil;
}

- (void)_toggleVisibility:(BOOL)hidden
{
    CGFloat alpha = hidden? 0.0f: 1.0f;

    if (!hidden) {
        self.alpha = 0.0f;
        self.hidden = NO;
    }

    void (^animationBlock)() = ^() {
        self.alpha = alpha;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        self.hidden = hidden;
    };

    [UIView animateWithDuration:0.3f animations:animationBlock completion:completionBlock];
}

- (void)drawRect:(CGRect)rect
{
    self.backgroundColor = [UIColor clearColor];
    CGContextClearRect(UIGraphicsGetCurrentContext(), rect);

    UIColor *drawingColor = [UIColor colorWithWhite:.20 alpha:.7];
    [drawingColor setFill];

    UIBezierPath* bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:rect.size.height / 2];
    [bezierPath fill];

    [super drawRect:rect];
}

@end
