//
//  VLCHorizontalSwipeGestureRecognizer.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 26.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCHorizontalSwipeGestureRecognizer.h"

@interface VLCHorizontalSwipeGestureRecognizer ()
{
    CGFloat _xOrigin;
}
@end

@implementation VLCHorizontalSwipeGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _xOrigin = [touches.anyObject locationInView:self.view].x;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGFloat currentX = [touches.anyObject locationInView:self.view].x;
    CGFloat viewWidth = self.view.bounds.size.width;

    if ([self.delegate respondsToSelector:@selector(horizontalSwipePercentage:inView:)])
        [self.delegate horizontalSwipePercentage:(currentX - _xOrigin)/viewWidth inView:self.view];
}

@end
