/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCAboutViewController : UIViewController

@property (readwrite, weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (readwrite, weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (readwrite, weak, nonatomic) IBOutlet UILabel *basedOnLabel;
@property (readwrite, weak, nonatomic) IBOutlet UITextView *blablaTextView;

@end
