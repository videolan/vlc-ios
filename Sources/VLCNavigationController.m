/*****************************************************************************
 * VLCNavigationController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNavigationController.h"

@interface VLCNavigationController ()
{
    BOOL _setup;
}
@end

@implementation VLCNavigationController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_setup)
        return;

    UINavigationBar *navigationBar = self.navigationBar;
    if (!SYSTEM_RUNS_IOS7_OR_LATER) {
        [navigationBar setBackgroundImage:[UIImage imageNamed:@"navBarBackground"] forBarMetrics:UIBarMetricsDefault];
        navigationBar.barStyle = UIBarStyleBlack;
        navigationBar.translucent = NO;
        navigationBar.opaque = YES;
    } else {
        navigationBar.barTintColor = [UIColor VLCOrangeTintColor];
        navigationBar.tintColor = [UIColor whiteColor];
        navigationBar.titleTextAttributes = @{ UITextAttributeTextColor : [UIColor whiteColor] };
    }

    _setup = YES;
}

@end
