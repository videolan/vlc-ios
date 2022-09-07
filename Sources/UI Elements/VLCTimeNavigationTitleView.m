/*****************************************************************************
 * VLCTimeNavigationTitleView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
           Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import "VLCTimeNavigationTitleView.h"
@import CoreText.SFNTLayoutTypes;

@implementation VLCTimeNavigationTitleView

- (void)awakeFromNib {

    self.minimizePlaybackButton.accessibilityLabel = NSLocalizedString(@"MINIMIZE_PLAYBACK_VIEW", nil);
    self.aspectRatioButton.accessibilityLabel = NSLocalizedString(@"VIDEO_ASPECT_RATIO_BUTTON", nil);
    [self.aspectRatioButton setImage:[UIImage imageNamed:@"ratioIcon"] forState:UIControlStateNormal];
    [self setupTimeDisplayFont];

    [super awakeFromNib];
}

/**
 Use a monospace variant for the digits so the label's width does not jitter as the numbers change.
 */
- (void)setupTimeDisplayFont
{
    UIFontDescriptor *descriptor = self.timeDisplayButton.titleLabel.font.fontDescriptor;
    NSDictionary *featureSettings = @{
                                      UIFontFeatureTypeIdentifierKey: @(kNumberSpacingType),
                                      UIFontFeatureSelectorIdentifierKey: @(kMonospacedNumbersSelector)
                                      };
    NSDictionary *attributes = @{ UIFontDescriptorFeatureSettingsAttribute: @[featureSettings] };
    UIFontDescriptor *newDescriptor = [descriptor fontDescriptorByAddingAttributes: attributes];
    UIFont *newFont = [UIFont fontWithDescriptor:newDescriptor size:0];
    self.timeDisplayButton.titleLabel.font = newFont;
}

@end
