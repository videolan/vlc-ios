//
//  VLCLinearProgressIndicator.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 13.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCLinearProgressIndicator.h"

@implementation VLCLinearProgressIndicator

- (void)drawRect:(CGRect)rect
{
    self.backgroundColor = [UIColor clearColor];
    CGContextClearRect(UIGraphicsGetCurrentContext(), rect);

    UIColor *drawingColor = [UIColor colorWithWhite:.67 alpha:.9];

    UIBezierPath* bezierPath = [UIBezierPath bezierPath];

    [bezierPath moveToPoint:CGPointMake((self.progress * rect.size.width) - rect.size.height + 3., 2.)];

    // Create our triangle
    [bezierPath addLineToPoint:CGPointMake((self.progress * rect.size.width) - (rect.size.height/2), rect.size.height - 5.)];
    [bezierPath addLineToPoint:CGPointMake((self.progress * rect.size.width) - 3., 2.)];
    [bezierPath closePath];

    // Set the display for the path, and stroke it
    bezierPath.lineWidth = 6.;
    [drawingColor setStroke];
    [bezierPath stroke];
    [drawingColor setFill];
    [bezierPath fill];
}

@end
