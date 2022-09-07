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

#import "VLCPlaybackInfoPanelTVViewController.h"

@interface VLCPlaybackInfoPanelTVViewController ()

@end

@implementation VLCPlaybackInfoPanelTVViewController

static inline void sharedSetup(VLCPlaybackInfoPanelTVViewController *self)
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        sharedSetup(self);
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    sharedSetup(self);
}

- (CGSize)preferredContentSize
{
    return CGSizeMake(CGRectGetWidth(self.view.bounds), 100);
}

// private API to prevent tab bar from hiding
- (BOOL)_tvTabBarShouldAutohide
{
    return NO;
}

+ (BOOL)shouldBeVisibleForPlaybackController:(VLCPlaybackService *)vpc
{
    return YES;
}

@end
