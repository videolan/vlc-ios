/*****************************************************************************
 * VLCVolumeView.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCVolumeView.h"

@implementation VLCVolumeView

- (CGRect)volumeSliderRectForBounds:(CGRect)bounds
{
    CGRect rect = [super volumeSliderRectForBounds:bounds];
    // fix height and y origin
    rect.size.height = bounds.size.height;
    rect.origin.y = bounds.origin.y;
    return rect;
}

- (CGRect)routeButtonRectForBounds:(CGRect)bounds
{
    CGRect rect = [super routeButtonRectForBounds:bounds];
    // fix height and y origin
    rect.size.height = bounds.size.height;
    rect.origin.y = bounds.origin.y;
    return rect;
}

@end
