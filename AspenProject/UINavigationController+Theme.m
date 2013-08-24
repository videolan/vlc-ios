//
//  UINavigationController+Theme.m
//  VLC for iOS
//
//  Created by Romain Goyet on 14/06/13.
//  Copyright (c) 2013 Applidium. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "UINavigationController+Theme.h"

@implementation UINavigationController (Theme)
- (void)loadTheme
{
    UINavigationBar *navBar = self.navigationBar;
    if (!SYSTEM_RUNS_IN_THE_FUTURE) {
        [navBar setBackgroundImage:[UIImage imageNamed:@"navBarBackground"]
                     forBarMetrics:UIBarMetricsDefault];
        navBar.barStyle = UIBarStyleBlack;
    } else {
        navBar.barTintColor = [UIColor colorWithRed:1.0f green:(132.0f/255.0f) blue:0.0f alpha:1.f];
        navBar.tintColor = [UIColor whiteColor];
        navBar.titleTextAttributes = @{ UITextAttributeTextColor : [UIColor whiteColor] };
    }
}
@end
