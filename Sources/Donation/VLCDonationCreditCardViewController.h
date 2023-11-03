/*****************************************************************************
 * VLCDonationCreditCardViewController.h
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

@interface VLCDonationCreditCardViewController : UIViewController

@property (readwrite, nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *descriptionLabel;

@property (readwrite, nonatomic, weak) IBOutlet UILabel *creditCardNumberLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *expiryDateLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *cvvLabel;

@property (readwrite, nonatomic, weak) IBOutlet UITextField *creditCardNumberField;
@property (readwrite, nonatomic, weak) IBOutlet UITextField *expiryDateField;
@property (readwrite, nonatomic, weak) IBOutlet UITextField *cvvField;

@property (readwrite, nonatomic, weak) IBOutlet UIButton *continueButton;

- (IBAction)fieldAction:(id)sender;

- (void)setDonationAmount:(float)donationAmount;

@end

NS_ASSUME_NONNULL_END
