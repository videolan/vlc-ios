/*****************************************************************************
 * UIBarButtonItem+Theme.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Romain Goyet <romain.goyet # applidium.com>
 *          Fabio Ritrovato <sephiroth87 # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "UIBarButtonItem+Theme.h"

@implementation UIBarButtonItem (Theme)
+ (UIBarButtonItem *)themedDoneButtonWithTarget:(id)target andSelector:(SEL)selector
{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", @"")
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:target
                                                                     action:selector];
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        doneButton.tintColor = [UIColor whiteColor];
    else {
        [doneButton setBackgroundImage:[UIImage imageNamed:@"doneButton"]
                              forState:UIControlStateNormal
                            barMetrics:UIBarMetricsDefault];
        [doneButton setBackgroundImage:[UIImage imageNamed:@"doneButtonHighlight"]
                              forState:UIControlStateHighlighted
                            barMetrics:UIBarMetricsDefault];
        [doneButton setTitleTextAttributes:@{UITextAttributeTextShadowColor : [UIColor whiteColor], UITextAttributeTextColor : [UIColor blackColor]}
                                  forState:UIControlStateNormal];
    }
    return doneButton;
}

+ (UIBarButtonItem *)themedBackButtonWithTarget:(id)target andSelector:(SEL)selector
{
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_BACK", @"")
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:target
                                                                  action:selector];
    if (SYSTEM_RUNS_IOS7_OR_LATER)
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
    /* After day 354 of the year, the usual VLC cone is replaced by another cone
     * wearing a Father Xmas hat.
     * Note: this icon doesn't represent an endorsement of The Coca-Cola Company
     * and should not be confused with the idea of religious statements or propagation there off
     */
    NSCalendar *gregorian =
    [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSUInteger dayOfYear = [gregorian ordinalityOfUnit:NSDayCalendarUnit inUnit:NSYearCalendarUnit forDate:[NSDate date]];
    UIImage *icon;
    if (dayOfYear >= 354)
        icon = [UIImage imageNamed:@"vlc-xmas"];
    else
        icon = [UIImage imageNamed:@"menuCone"];

    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:icon style:UIBarButtonItemStyleBordered target:target action:selector];
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        menuButton.tintColor = [UIColor whiteColor];
    else {
        [menuButton setBackgroundImage:[UIImage imageNamed:@"button"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [menuButton setBackgroundImage:[UIImage imageNamed:@"buttonHighlight"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    }
    menuButton.accessibilityLabel = NSLocalizedString(@"OPEN_VLC_MENU", @"");
    menuButton.isAccessibilityElement = YES;

    return menuButton;
}

+ (UIBarButtonItem *)themedDarkToolbarButtonWithTitle:(NSString*)title target:(id)target andSelector:(SEL)selector
{
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleBordered target:target action:selector];
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        button.tintColor = [UIColor whiteColor];
    else {
        [button setBackgroundImage:[[UIImage imageNamed:@"darkButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [button setBackgroundImage:[[UIImage imageNamed:@"darkButtonHighlight"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    }

    return button;
}
@end
