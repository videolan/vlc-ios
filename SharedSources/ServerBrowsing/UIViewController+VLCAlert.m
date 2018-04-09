/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "UIViewController+VLCAlert.h"

@implementation UIViewController (UIViewController_VLCAlert)

- (void)vlc_showAlertWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle
{
    [UIAlertController showAlertInViewController:self
                                           title:title
                                         message:message
                               cancelButtonTitle:buttonTitle
                               otherButtonTitles:nil
                          destructiveButtonTitle:nil
                                        tapBlock:^(UIAlertController *alertController, NSInteger buttonIndex) {
                                            [alertController dismissViewControllerAnimated:YES completion:nil];
                                        }];
}

@end
