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
    [doneButton setBackgroundImage:[UIImage imageNamed:@"doneButton"]
                          forState:UIControlStateNormal
                        barMetrics:UIBarMetricsDefault];
    [doneButton setBackgroundImage:[UIImage imageNamed:@"doneButtonHighlight"]
                          forState:UIControlStateHighlighted
                        barMetrics:UIBarMetricsDefault];
    [doneButton setTitleTextAttributes:@{UITextAttributeTextShadowColor : [UIColor whiteColor], UITextAttributeTextColor : [UIColor blackColor]}
                              forState:UIControlStateNormal];
    return doneButton;
}
@end
