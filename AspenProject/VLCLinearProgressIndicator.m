//
//  VLCLinearProgressIndicator.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 13.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCLinearProgressIndicator.h"

@implementation VLCLinearProgressIndicator

- (void)drawRect:(CGRect)rect
{
    self.backgroundColor = [UIColor clearColor];
    CGContextClearRect(UIGraphicsGetCurrentContext(), rect);

    UIColor *drawingColor = [UIColor colorWithRed:.792 green:.408 blue:.0 alpha:.9];

    UIBezierPath* bezierPath = [UIBezierPath bezierPath];

    float progress_width = self.progress * rect.size.width;

    [bezierPath moveToPoint:CGPointMake(progress_width - rect.size.height + 3., 2.)];

    // Create our triangle
    [bezierPath addLineToPoint:CGPointMake(progress_width - (rect.size.height/2), rect.size.height - 5.)];
    [bezierPath addLineToPoint:CGPointMake(progress_width - 3., 2.)];
    [bezierPath closePath];

    // Set the display for the path, and stroke it
    bezierPath.lineWidth = 6.;
    [drawingColor setStroke];
    [bezierPath stroke];
    [drawingColor setFill];
    [bezierPath fill];
}

@end
