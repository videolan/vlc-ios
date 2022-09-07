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
