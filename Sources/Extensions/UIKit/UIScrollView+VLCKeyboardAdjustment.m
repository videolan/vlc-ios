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

- (void)adjustForKeyboardNotification:(NSNotification *)aNotification revealingView:(UIView *)view
{
    CGRect keyboardFrame = [aNotification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect ownFrame = [self convertRect:self.bounds toView:nil];
    CGFloat overlap = MAX(0., CGRectGetMaxY(ownFrame) - CGRectGetMinY(keyboardFrame));

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
