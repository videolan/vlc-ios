/*****************************************************************************
 * UITextField+VLCKeyboardDismissal.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "UITextField+VLCKeyboardDismissal.h"
#import "VLC-Swift.h"

@implementation UITextField (VLCKeyboardDismissal)

- (void)addKeyboardDismissAccessory
{
#if !TARGET_OS_VISION
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0., 0., 0., 44.)];
    toolbar.barStyle = PresentationTheme.current.colors.toolBarStyle;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                  target:nil
                                                                                  action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", nil)
                                                                  style:UIBarButtonItemStyleDone
                                                                 target:self
                                                                 action:@selector(resignFirstResponder)];
    toolbar.items = @[flexibleSpace, doneButton];
    [toolbar sizeToFit];
    self.inputAccessoryView = toolbar;
#endif
}

@end
