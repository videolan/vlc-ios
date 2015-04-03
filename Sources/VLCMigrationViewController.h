/*****************************************************************************
 * VLCMigrationViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCMigrationViewController : UIViewController

@property(nonatomic) IBOutlet UILabel *statusLabel;
@property(nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property(nonatomic, copy) void (^completionHandler)();
@end
