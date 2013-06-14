//
//  VLCCircularProgressIndicator.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 12.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCCircularProgressIndicator.h"

@implementation VLCCircularProgressIndicator

- (void)drawRect:(CGRect)rect
{
    self.backgroundColor = [UIColor clearColor];
    CGContextClearRect(UIGraphicsGetCurrentContext(), rect);

    CGFloat startAngle, endAngle = 0.;
    startAngle = M_PI * 1.5;
    endAngle = startAngle + (M_PI * 2);

    UIBezierPath* bezierPath = [UIBezierPath bezierPath];

    // Create our arc, with the correct angles
    [bezierPath addArcWithCenter:CGPointMake(rect.size.width / 2, rect.size.height / 2)
                          radius:(rect.size.width / 2) - 6
                      startAngle:startAngle
                        endAngle:(endAngle - startAngle) * self.progress + startAngle
                       clockwise:YES];

    // Set the display for the path, and stroke it
    bezierPath.lineWidth = 6.;
    [[UIColor grayColor] setStroke];
    [bezierPath stroke];
}

@end
