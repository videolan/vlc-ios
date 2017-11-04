/*****************************************************************************
 * UIBarButtonItem+Theme.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Fabio Ritrovato <sephiroth87 # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@implementation UIBarButtonItem (ThemedButtons)

+ (UIBarButtonItem *)themedBackButtonWithTarget:(id)target andSelector:(SEL)selector
{
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_BACK", nil)
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:target
                                                                  action:selector];
    backButton.tintColor = [UIColor whiteColor];
    NSShadow *shadow = [[NSShadow alloc] init];
    [backButton setTitleTextAttributes:@{NSShadowAttributeName : shadow, NSForegroundColorAttributeName : [UIColor whiteColor]} forState:UIControlStateNormal];
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
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSUInteger dayOfYear = [gregorian ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitYear forDate:[NSDate date]];
    UIImage *icon;
    if (dayOfYear >= 354)
        icon = [UIImage imageNamed:@"vlc-xmas"];
    else
        icon = [UIImage imageNamed:@"menuCone"];

    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:icon style:UIBarButtonItemStylePlain target:target action:selector];
    menuButton.tintColor = [UIColor whiteColor];
    menuButton.accessibilityLabel = NSLocalizedString(@"OPEN_VLC_MENU", nil);

    return menuButton;
}

+ (UIBarButtonItem *)themedDarkToolbarButtonWithTitle:(NSString*)title target:(id)target andSelector:(SEL)selector
{
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:target action:selector];
    button.tintColor = [UIColor whiteColor];

    return button;
}

+ (UIBarButtonItem *)themedPlayAllButtonWithTarget:(id)target andSelector:(SEL)selector
{
    UIBarButtonItem *playAllButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:target action:selector];
    playAllButton.accessibilityLabel = NSLocalizedString(@"PLAY_ALL_BUTTON", nil);

    return playAllButton;
}

@end
