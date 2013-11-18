/*****************************************************************************
 * VLCStatusLabel.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCStatusLabel.h"

@implementation VLCStatusLabel

- (void)showStatusMessage:(NSString *)message
{
    self.text = message;

    /* layout and horizontal center in super view */
    [self sizeToFit];
    CGRect selfFrame = self.frame;
    CGRect parentFrame = [self superview].bounds;
    selfFrame.size.width += 15.; // take extra width into account for our custom drawing
    selfFrame.origin.x = (parentFrame.size.width - selfFrame.size.width) / 2.;
    [self setFrame:selfFrame];

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
