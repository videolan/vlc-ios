/*****************************************************************************
 * VLCStatusLabel.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCStatusLabel.h"

@interface VLCStatusLabel ()
{
    NSTimer *_displayTimer;
    UIEdgeInsets _insets;
}
@end

@implementation VLCStatusLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        [self initialize];

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
        [self initialize];

    return self;
}

- (void)initialize
{
    _insets = UIEdgeInsetsMake(5, 10, 5, 10);
    self.backgroundColor = [UIColor clearColor];
    self.textAlignment = NSTextAlignmentCenter;
}

#pragma mark -

- (void)showStatusMessage:(NSString *)message
{
    self.text = message;

    /* layout and horizontal center in super view */
    [self sizeToFit];
    CGRect selfFrame = self.frame;
    CGRect parentFrame = [self superview].bounds;
    selfFrame.origin.x = (parentFrame.size.width - selfFrame.size.width) / 2.;
    [self setFrame:selfFrame];

    [self setNeedsDisplay];

    if (_displayTimer)
        [_displayTimer invalidate];
    else
        [self setHidden:NO animated:YES];

    _displayTimer = [NSTimer scheduledTimerWithTimeInterval:1.5
                                                     target:self
                                                   selector:@selector(_hideAgain)
                                                   userInfo:nil
                                                    repeats:NO];
}

- (void)_hideAgain
{
    [self setHidden:YES animated:YES];
    _displayTimer = nil;
}

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated
{
    CGFloat alpha = hidden? 0.0f: 1.0f;

    if (!hidden) {
        self.alpha = 0.0f;
        self.hidden = NO;
    }

    void (^animationBlock)(void) = ^() {
        self.alpha = alpha;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        self.hidden = hidden;
    };

    NSTimeInterval duration = animated? 0.3: 0.0;
    [UIView animateWithDuration:duration animations:animationBlock completion:completionBlock];
}

#pragma mark - sizing

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize textSize = [self.text sizeWithAttributes:self.font.fontDescriptor.fontAttributes];
    textSize.width += size.height * 4.; // take extra width into account for our custom drawing
    return textSize;
}

#pragma mark -

- (void)drawRect:(CGRect)rect
{
    UIColor *drawingColor = [UIColor VLCTransparentDarkBackgroundColor];
    [drawingColor setFill];

    UIBezierPath* bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:rect.size.height / 2];
    [bezierPath fill];


    [super drawRect:UIEdgeInsetsInsetRect(rect, _insets)];
}

- (void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _insets)];
}

- (CGSize)intrinsicContentSize {
    CGSize intrinsicSuperViewContentSize = [super intrinsicContentSize];
    intrinsicSuperViewContentSize.height += _insets.top + _insets.bottom;
    intrinsicSuperViewContentSize.width += _insets.left + _insets.right;
    return intrinsicSuperViewContentSize;
}

@end
