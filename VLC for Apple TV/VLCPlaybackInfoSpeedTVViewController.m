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


#import "VLCPlaybackInfoSpeedTVViewController.h"

@interface VLCPlaybackInfoSpeedTVViewController ()

@end

@implementation VLCPlaybackInfoSpeedTVViewController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"PLAYBACK_SPEED_INFO_VC_TITLE", nil);
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    return self;
}

- (CGSize)preferredContentSize {
    return CGSizeMake(CGRectGetWidth(self.view.bounds), 100);
}
- (BOOL)_tvTabBarShouldAutohide
{
    return NO;
}
@end
