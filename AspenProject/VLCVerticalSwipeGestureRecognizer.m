//
//  VLCVerticalSwipeGestureRecognizer.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 26.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCVerticalSwipeGestureRecognizer.h"

@interface VLCVerticalSwipeGestureRecognizer ()
{
    CGFloat _yOrigin;
}
@end

@implementation VLCVerticalSwipeGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _yOrigin = [touches.anyObject locationInView:self.view].y;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint locationInView = [touches.anyObject locationInView:self.view];
    CGFloat currentY = locationInView.y;
    CGFloat currentX = locationInView.x;
    CGSize viewSize = self.view.bounds.size;

    if ([self.delegate respondsToSelector:@selector(verticalSwipePercentage:inView:half:)])
        [self.delegate verticalSwipePercentage:(currentY - _yOrigin)/viewSize.height inView:self.view half:(currentX < (viewSize.width/2)) ? 0 : 1];
}

@end
