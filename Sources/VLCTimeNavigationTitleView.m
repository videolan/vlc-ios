/*****************************************************************************
 * VLCTimeNavigationTitleView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import "VLCTimeNavigationTitleView.h"
#import "VLCSlider.h"

@implementation VLCTimeNavigationTitleView

-(void)awakeFromNib {

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self.positionSlider.scrubbingSpeedChangePositions = @[@(0.), @(100.), @(200.), @(300)];

    self.timeDisplayButton.isAccessibilityElement = YES;

    self.aspectRatioButton.accessibilityLabel = NSLocalizedString(@"VIDEO_ASPECT_RATIO_BUTTON", nil);
    self.aspectRatioButton.isAccessibilityElement = YES;

    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        [self.aspectRatioButton setImage:[UIImage imageNamed:@"ratioIcon"] forState:UIControlStateNormal];
    } else {
        [self.aspectRatioButton setBackgroundImage:[UIImage imageNamed:@"ratioButton"] forState:UIControlStateNormal];
        [self.aspectRatioButton setBackgroundImage:[UIImage imageNamed:@"ratioButtonHighlight"] forState:UIControlStateHighlighted];
    }

    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect remainder = self.bounds;
    CGRect slice;
    if (!self.aspectRatioButton.hidden) {
        [self.aspectRatioButton sizeToFit];
        CGRectDivide(remainder, &slice, &remainder, CGRectGetWidth(self.aspectRatioButton.frame), CGRectMaxXEdge);
        self.aspectRatioButton.frame = slice;
    }

    [self.timeDisplayButton sizeToFit];
    CGRectDivide(remainder, &slice, &remainder, CGRectGetWidth(self.timeDisplayButton.frame), CGRectMaxXEdge);
    self.timeDisplayButton.frame = slice;

    self.positionSlider.frame = remainder;
}

- (void)setHideAspectRatio:(BOOL)hideAspectRatio
{
    _hideAspectRatio = hideAspectRatio;
    self.aspectRatioButton.hidden = hideAspectRatio;
    [self setNeedsLayout];
}


@end
