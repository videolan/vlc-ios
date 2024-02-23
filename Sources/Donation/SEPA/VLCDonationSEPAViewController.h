/*****************************************************************************
 * VLCDonationCreditCardViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023-2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCConfettiView;
@class VLCCurrency;
@class VLCPrice;

@interface VLCDonationSEPAViewController : UIViewController

@property (readwrite, nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *descriptionLabel;

@property (readwrite, nonatomic, weak) IBOutlet UILabel *bankAccountNumberLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *emailLabel;

@property (readwrite, nonatomic, weak) IBOutlet UITextField *bankAccountNumberField;
@property (readwrite, nonatomic, weak) IBOutlet UITextField *nameField;
@property (readwrite, nonatomic, weak) IBOutlet UITextField *emailField;

@property (readwrite, nonatomic, weak) IBOutlet UIButton *continueButton;
@property (readwrite, nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (readwrite, nonatomic, weak) IBOutlet UIScrollView *contentScrollView;
@property (readwrite, nonatomic, weak) IBOutlet VLCConfettiView *confettiView;

- (IBAction)fieldAction:(id)sender;
- (IBAction)continueButtonAction:(id)sender;

- (void)setDonationAmount:(NSNumber *)donationAmount withCurrency:(VLCCurrency *)currency;
- (void)setPrice:(VLCPrice *)selectedPrice withCurrency:(VLCCurrency *)currency recurring:(BOOL)recurring;

@end

NS_ASSUME_NONNULL_END
