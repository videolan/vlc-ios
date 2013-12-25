/*****************************************************************************
 * VLCFirstStepsSixthPageViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCFirstStepsSixthPageViewController : UIViewController

@property (readonly) NSString *pageTitle;
@property (readonly) NSUInteger page;

@property (nonatomic, strong) IBOutlet UILabel *flossDescriptionLabel;
@property (nonatomic, strong) IBOutlet UIButton *learnMoreButton;

- (IBAction)learnMore:(id)sender;

@end
