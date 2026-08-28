/*****************************************************************************
 * UIScrollView+VLCKeyboardAdjustment.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "UIScrollView+VLCKeyboardAdjustment.h"

@implementation UIScrollView (VLCKeyboardAdjustment)

- (CGFloat)keyboardOverlapForNotification:(NSNotification *)aNotification
{
    CGRect keyboardFrame = [aNotification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect ownFrame = [self convertRect:self.bounds toView:nil];
    return MAX(0., CGRectGetMaxY(ownFrame) - CGRectGetMinY(keyboardFrame));
}

- (void)adjustBottomInsetForKeyboardNotification:(NSNotification *)aNotification baseInset:(CGFloat)baseInset
{
    CGFloat overlap = MAX(baseInset, [self keyboardOverlapForNotification:aNotification]);
    /* the safe area is already part of the adjusted inset, so it must not be added twice */
    CGFloat automaticInset = self.adjustedContentInset.bottom - self.contentInset.bottom;

    UIEdgeInsets insets = self.contentInset;
    insets.bottom = MAX(0., overlap - automaticInset);
    self.contentInset = insets;
    self.verticalScrollIndicatorInsets = insets;
}

- (void)adjustForKeyboardNotification:(NSNotification *)aNotification revealingView:(UIView *)view
{
    CGFloat overlap = [self keyboardOverlapForNotification:aNotification];

    UIEdgeInsets insets = self.contentInset;
    insets.bottom = overlap;
    self.contentInset = insets;
    self.scrollIndicatorInsets = insets;

    if (overlap == 0.) {
        return;
    }

    CGRect target = [self convertRect:view.bounds fromView:view];
    CGFloat visibleHeight = CGRectGetHeight(self.bounds) - overlap;
    CGFloat targetOffset = CGRectGetMaxY(target) + 8. - visibleHeight;
    if (targetOffset > self.contentOffset.y) {
        [self setContentOffset:CGPointMake(self.contentOffset.x, targetOffset) animated:YES];
    }
}

@end
