/*****************************************************************************
 * UIBarButtonItem+Theme.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Romain Goyet <romain.goyet # applidium.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (Theme)
+ (UIBarButtonItem *)themedDoneButtonWithTarget:(id)target andSelector:(SEL)selector;
+ (UIBarButtonItem *)themedBackButtonWithTarget:(id)target andSelector:(SEL)selector;
+ (UIBarButtonItem *)themedRevealMenuButtonWithTarget:(id)target andSelector:(SEL)selector;
+ (UIBarButtonItem *)themedDarkToolbarButtonWithTitle: (NSString*) title target:(id)target andSelector:(SEL)selector;

@end
