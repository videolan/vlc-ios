/*  This file is adapted from GTScrollNavigationBar - https://github.com/luugiathuy/GTScrollNavigationBar
 *  3-clause BSD License
 *
 *  Copyright (c) 2013, Luu Gia Thuy
 *
 *  Redistribution and use in source and binary forms, with or without modification,
 *  are permitted provided that the following conditions are met:
 *
 *  * Redistributions of source code must retain the above copyright notice, this
 *  list of conditions and the following disclaimer.
 *
 *  * Redistributions in binary form must reproduce the above copyright notice, this
 *  list of conditions and the following disclaimer in the documentation and/or
 *  other materials provided with the distribution.
 *
 *  * Neither the name of the {organization} nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 *  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 *  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 *  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

#import "GTScrollNavigationBar.h"

#define kNearZero 0.000001f

@interface GTScrollNavigationBar () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIPanGestureRecognizer* panGesture;
@property (assign, nonatomic) CGFloat lastContentOffsetY;

@end

@implementation GTScrollNavigationBar

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(handlePan:)];
    self.panGesture.delegate = self;
    self.panGesture.cancelsTouchesInView = NO;

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter addObserver:self
                   selector:@selector(applicationDidBecomeActive)
                   name:UIApplicationDidBecomeActiveNotification
                   object:nil];

    [defaultCenter addObserver:self
                   selector:@selector(statusBarOrientationDidChange)
                   name:UIApplicationDidChangeStatusBarOrientationNotification
                   object:nil];
}

- (void)dealloc
{
    if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

#pragma mark - Properties
- (void)setScrollView:(UIScrollView*)scrollView
{
    [self resetToDefaultPositionWithAnimation:NO];

    _scrollView = scrollView;

    // remove gesture from current panGesture's view
    if (self.panGesture.view) {
        [self.panGesture.view removeGestureRecognizer:self.panGesture];
    }

    if (scrollView) {
        [scrollView addGestureRecognizer:self.panGesture];
    }
}

#pragma mark - Public methods
- (void)resetToDefaultPositionWithAnimation:(BOOL)animated
{
    self.scrollState = GTScrollNavigationBarStateNone;
    CGRect frame = self.frame;
    frame.origin.y = [self statusBarTopOffset];
    [self setFrame:frame alpha:1.0f animated:animated];
}

#pragma mark - Notifications
- (void)statusBarOrientationDidChange
{
    [self resetToDefaultPositionWithAnimation:NO];
}

- (void)applicationDidBecomeActive
{
    [self resetToDefaultPositionWithAnimation:NO];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - panGesture handler
- (void)handlePan:(UIPanGestureRecognizer*)gesture
{
    if (!self.scrollView || gesture.view != self.scrollView) {
        return;
    }

    // Don't try to scroll navigation bar if there's not enough room
    if (self.scrollView.frame.size.height + (self.bounds.size.height * 2) >=
        self.scrollView.contentSize.height) {
        return;
    }

    CGFloat contentOffsetY = self.scrollView.contentOffset.y;

    // Reset scrollState when the gesture began
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.scrollState = GTScrollNavigationBarStateNone;
        self.lastContentOffsetY = contentOffsetY;
        return;
    }

    CGFloat deltaY = contentOffsetY - self.lastContentOffsetY;
    if (deltaY < 0.0f) {
        self.scrollState = GTScrollNavigationBarStateScrollingDown;
    } else if (deltaY > 0.0f) {
        self.scrollState = GTScrollNavigationBarStateScrollingUp;
    }

    CGRect frame = self.frame;
    CGFloat alpha = 1.0f;
    CGFloat maxY = [self statusBarTopOffset];
    CGFloat minY = maxY - CGRectGetHeight(frame) + 1.0f;
    // NOTE: plus 1px to prevent the navigation bar disappears in iOS < 7

    CGFloat contentInsetTop = self.scrollView.contentInset.top;
    bool isBouncePastTopEdge = contentOffsetY < -contentInsetTop;
    if (isBouncePastTopEdge && CGRectGetMinY(frame) == maxY) {
        self.lastContentOffsetY = contentOffsetY;
        return;
    }

    bool isScrolling = (self.scrollState == GTScrollNavigationBarStateScrollingUp ||
                        self.scrollState == GTScrollNavigationBarStateScrollingDown);

    bool gestureIsActive = (gesture.state != UIGestureRecognizerStateEnded &&
                            gesture.state != UIGestureRecognizerStateCancelled);

    if (isScrolling && !gestureIsActive) {
        // Animate navigation bar to end position
        if (self.scrollState == GTScrollNavigationBarStateScrollingDown) {
            frame.origin.y = maxY;
            alpha = 1.0f;
        }
        else if (self.scrollState == GTScrollNavigationBarStateScrollingUp) {
            frame.origin.y = minY;
            alpha = kNearZero;
        }
        [self setFrame:frame alpha:alpha animated:YES];
    }
    // When panning down at beginning of scrollView and the bar is expanding, do not update lastContentOffsetY
    if (!isBouncePastTopEdge && CGRectGetMinY(frame) == maxY) {
        self.lastContentOffsetY = contentOffsetY;
    }
}

#pragma mark - helper methods
- (CGFloat)statusBarTopOffset
{
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    CGFloat topOffset = MIN(CGRectGetMaxX(statusBarFrame), CGRectGetMaxY(statusBarFrame));
    bool isInCallStatusBar = topOffset == 40.0f;
    if (isInCallStatusBar) {
        topOffset -= 20.0f;
    }
    return topOffset;
}

- (void)setFrame:(CGRect)frame alpha:(CGFloat)alpha animated:(BOOL)animated
{
    if (animated) {
        [UIView beginAnimations:@"GTScrollNavigationBarAnimation" context:nil];
    }

    CGFloat offsetY = CGRectGetMinY(frame) - CGRectGetMinY(self.frame);
    UIView *firstView = [self.subviews firstObject];

    for (UIView *view in self.subviews) {
        bool isBackgroundView = view == firstView;
        bool isViewHidden = view.hidden || view.alpha == 0.0f;
        if (isBackgroundView || isViewHidden)
            continue;
        view.alpha = alpha;
    }
    self.frame = frame;


    if (self.scrollView) {
        CGRect parentViewFrame = self.scrollView.superview.frame;
        parentViewFrame.origin.y += offsetY;
        parentViewFrame.size.height -= offsetY;
        self.scrollView.superview.frame = parentViewFrame;
    }

    if (animated) {
        [UIView commitAnimations];
    }
}

@end

@implementation UINavigationController (GTScrollNavigationBarAdditions)

@dynamic scrollNavigationBar;

- (GTScrollNavigationBar *)scrollNavigationBar
{
    return (GTScrollNavigationBar *)self.navigationBar;
}

@end
