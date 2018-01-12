/*****************************************************************************
 * UIBarButtonItem+Theme.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
@interface UIBarButtonItem (ThemedButtons)
+ (UIBarButtonItem *)themedBackButtonWithTarget:(id)target andSelector:(SEL)selector;
+ (UIBarButtonItem *)themedDarkToolbarButtonWithTitle: (NSString*) title target:(id)target andSelector:(SEL)selector;
+ (UIBarButtonItem *)themedPlayAllButtonWithTarget:(id)target andSelector:(SEL)selector;
@end
