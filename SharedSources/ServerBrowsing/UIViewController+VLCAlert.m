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
#import "VLC_iOS-Swift.h"
@implementation UIViewController (UIViewController_VLCAlert)
#if TARGET_OS_TV
- (void)vlc_showAlertWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:buttonTitle style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}
#else
- (void)vlc_showAlertWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle
    {
        NSMutableArray<ButtonAction *> *buttonsAction = [[NSMutableArray alloc] init];
        ButtonAction *cancelAction = [[ButtonAction alloc] initWithButtonTitle: buttonTitle
                                                                  buttonAction: ^(UIAlertAction* action){}];
        [buttonsAction addObject: cancelAction];
        [VLCAlertViewController alertViewManagerWithTitle:title
                                             errorMessage:message
                                           viewController:self
                                            buttonsAction:buttonsAction];
}
#endif
@end
