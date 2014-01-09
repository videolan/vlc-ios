/*****************************************************************************
 * VLCFirstStepsFourthPageViewController
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCFirstStepsFourthPageViewController : UIViewController

@property (readonly) NSString *pageTitle;
@property (readonly) NSUInteger page;

@property (nonatomic, strong) IBOutlet UILabel *uploadDescriptionLabel;
@property (nonatomic, strong) IBOutlet UILabel *accessDescriptionLabel;
@property (nonatomic, strong) IBOutlet UIView *actualContentView;

@end
