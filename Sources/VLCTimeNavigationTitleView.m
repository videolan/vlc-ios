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

@implementation VLCTimeNavigationTitleView

- (void)awakeFromNib {

    self.minimizePlaybackButton.accessibilityLabel = NSLocalizedString(@"MINIMIZE_PLAYBACK_VIEW", nil);
    self.aspectRatioButton.accessibilityLabel = NSLocalizedString(@"VIDEO_ASPECT_RATIO_BUTTON", nil);
    [self.aspectRatioButton setImage:[UIImage imageNamed:@"ratioIcon"] forState:UIControlStateNormal];

    [super awakeFromNib];
}
@end
