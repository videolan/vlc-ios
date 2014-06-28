/*****************************************************************************
 * UINavigationController+Theme.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Romain Goyet <romain.goyet # applidium.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "UINavigationController+Theme.h"

@implementation UINavigationController (Theme)
- (void)loadTheme
{
    UINavigationBar *navBar = self.navigationBar;
    if (!SYSTEM_RUNS_IOS7_OR_LATER) {
        [navBar setBackgroundImage:[UIImage imageNamed:@"navBarBackground"] forBarMetrics:UIBarMetricsDefault];
        navBar.barStyle = UIBarStyleBlack;
        navBar.translucent = NO;
        navBar.opaque = YES;
    } else {
        navBar.barTintColor = [UIColor VLCOrangeTintColor];
        navBar.tintColor = [UIColor whiteColor];
        navBar.titleTextAttributes = @{ UITextAttributeTextColor : [UIColor whiteColor] };
    }
}
@end
