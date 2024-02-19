/*****************************************************************************
 * VLCDonationNagScreenViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCDonationNagScreenViewController : UIViewController

@property (readwrite, nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *notnowButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *donateButton;
@property (readwrite, nonatomic, weak) IBOutlet UIView *coloredBackgroundView;
@property (readwrite, nonatomic, weak) IBOutlet UIView *buttonSeparatorView;

- (IBAction)dismiss:(id)sender;
- (IBAction)donate:(id)sender;

@end

NS_ASSUME_NONNULL_END
