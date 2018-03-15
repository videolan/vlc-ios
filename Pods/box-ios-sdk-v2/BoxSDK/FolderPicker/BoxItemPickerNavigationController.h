//
//  BoxItemPickerNavigationController.h
//  BoxSDK
//
//  Created on 5/31/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * BoxFolderPickerNavigationController is a UINavigationController subclass that
 * overrides disablesAutomaticKeyboardDismissal to always return `NO`.
 *
 * If you ever wish to present a BoxAuthorizationViewController in a modal with a
 * navigation controller, you should use this subclass to ensure that the keyboard
 * is automatically dismissed during the authorization flow.
 *
 * Since the folder picker also uses a BoxAuthorizationViewController, you should also
 * use this navigation controller for presenting a BoxFolderPickerViewController.
 */
@interface BoxItemPickerNavigationController : UINavigationController

@end
