/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "CAAnimation+VLCWiggle.h"

@implementation CAAnimation (VLCWiggle)
+ (instancetype)vlc_wiggleAnimationwithSoftMode:(BOOL)softmode
{
    CAKeyframeAnimation *position = [CAKeyframeAnimation animation];
    position.keyPath = @"position";
    position.values = @[
                        [NSValue valueWithCGPoint:CGPointZero],
                        [NSValue valueWithCGPoint:CGPointMake(-1, 0)],
                        [NSValue valueWithCGPoint:CGPointMake(1, 0)],
                        [NSValue valueWithCGPoint:CGPointMake(-1, 1)],
                        [NSValue valueWithCGPoint:CGPointMake(1, -1)],
                        [NSValue valueWithCGPoint:CGPointZero]
                        ];
    position.timingFunctions = @[
                                 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]
                                 ];
    position.additive = YES;

    CAKeyframeAnimation *rotation = [CAKeyframeAnimation animation];
    rotation.keyPath = @"transform.rotation";
    if (softmode) {
        rotation.values = @[
                            @0,
                            @0.005,
                            @0,
                            [NSNumber numberWithFloat:-0.004]
                            ];
    } else {
        rotation.values = @[
                            @0,
                            @0.03,
                            @0,
                            [NSNumber numberWithFloat:-0.02]
                            ];
    }
    rotation.timingFunctions = @[
                                 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]
                                 ];

    CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
    group.animations = @[position, rotation];
    group.duration = 0.4;
    group.repeatCount = HUGE_VALF;
    return group;
}
@end
