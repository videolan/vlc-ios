//
//  UIBarButtonItem+Theme.m
//  VLC for iOS
//
//  Created by Romain Goyet on 14/06/13.
//  Copyright (c) 2013 Applidium. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "UIBarButtonItem+Theme.h"

@implementation UIBarButtonItem (Theme)
+ (UIBarButtonItem *)themedDoneButtonWithTarget:(id)target andSelector:(SEL)selector
{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", @"")
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:target
                                                                     action:selector];
    if (SYSTEM_RUNS_IN_THE_FUTURE)
        doneButton.tintColor = [UIColor whiteColor];
    else {
        [doneButton setBackgroundImage:[UIImage imageNamed:@"doneButton"]
                              forState:UIControlStateNormal
                            barMetrics:UIBarMetricsDefault];
        [doneButton setBackgroundImage:[UIImage imageNamed:@"doneButtonHighlight"]
                              forState:UIControlStateHighlighted
                            barMetrics:UIBarMetricsDefault];
    }
    [doneButton setTitleTextAttributes:@{UITextAttributeTextShadowColor : [UIColor whiteColor], UITextAttributeTextColor : [UIColor blackColor]}
                              forState:UIControlStateNormal];
    return doneButton;
}

+ (UIBarButtonItem *)themedBackButtonWithTarget:(id)target andSelector:(SEL)selector
{
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_BACK", @"")
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:target
                                                                  action:selector];
    if (SYSTEM_RUNS_IN_THE_FUTURE)
        backButton.tintColor = [UIColor whiteColor];
    else {
        [backButton setBackgroundImage:[[UIImage imageNamed:@"backButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 12, 0, 6)]
                              forState:UIControlStateNormal
                            barMetrics:UIBarMetricsDefault];
        [backButton setBackgroundImage:[[UIImage imageNamed:@"backButtonHighlight"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 12, 0, 6)]
                              forState:UIControlStateHighlighted
                            barMetrics:UIBarMetricsDefault];
    }
    [backButton setTitleTextAttributes:@{UITextAttributeTextShadowColor : [UIColor colorWithWhite:0. alpha:.37], UITextAttributeTextColor : [UIColor whiteColor]} forState:UIControlStateNormal];
    [backButton setTitlePositionAdjustment:UIOffsetMake(3, 0) forBarMetrics:UIBarMetricsDefault];
    return backButton;
}

+ (UIBarButtonItem *)themedRevealMenuButtonWithTarget:(id)target andSelector:(SEL)selector
{
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menuCone"] style:UIBarButtonItemStyleBordered target:target action:selector];
    if (SYSTEM_RUNS_IN_THE_FUTURE)
        menuButton.tintColor = [UIColor whiteColor];
    else {
        [menuButton setBackgroundImage:[UIImage imageNamed:@"button"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [menuButton setBackgroundImage:[UIImage imageNamed:@"buttonHighlight"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    }
    menuButton.accessibilityLabel = NSLocalizedString(@"OPEN_VLC_MENU", @"");
    menuButton.isAccessibilityElement = YES;

    return menuButton;
}

@end
