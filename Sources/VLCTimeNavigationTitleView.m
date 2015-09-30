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

    [self.aspectRatioButton setImage:[UIImage imageNamed:@"ratioIcon"] forState:UIControlStateNormal];

    self.minimizePlaybackButton.accessibilityLabel = NSLocalizedString(@"MINIMIZE_PLAYBACK_VIEW", nil);
    self.minimizePlaybackButton.isAccessibilityElement = YES;

    // workaround for radar://22897614 ( http://www.openradar.me/22897614 )
    UISlider *slider = self.positionSlider;
    if ([slider respondsToSelector:@selector(semanticContentAttribute)]) {
        UISemanticContentAttribute attribute = slider.semanticContentAttribute;
        slider.semanticContentAttribute = UISemanticContentAttributeUnspecified;
        slider.semanticContentAttribute = attribute;
    }

    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect remainder = self.bounds;
    CGRect slice;

    CGRectDivide(remainder, &slice, &remainder, CGRectGetWidth(self.minimizePlaybackButton.frame), CGRectMinXEdge);
    self.minimizePlaybackButton.frame = slice;

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
