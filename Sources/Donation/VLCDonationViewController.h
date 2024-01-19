/*****************************************************************************
 * VLCDonationViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCConfettiView;

@interface VLCDonationViewController : UIViewController

@property (readwrite, nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (readwrite, nonatomic, weak) IBOutlet UISegmentedControl *frequencySwitch;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *fiveButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *tenButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *twentyButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *thirtyButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *fiftyButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *hundredButton;
@property (readwrite, nonatomic, weak) IBOutlet UITextField *customAmountField;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *continueButton;
@property (readwrite, nonatomic, weak) IBOutlet UIScrollView *contentScrollView;
@property (readwrite, nonatomic, weak) IBOutlet VLCConfettiView *confettiView;

- (IBAction)numberButtonAction:(id)sender;
- (IBAction)continueButtonAction:(id)sender;
- (IBAction)customAmountFieldAction:(id)sender;

@end

NS_ASSUME_NONNULL_END
