/*****************************************************************************
 * VLCDonationCreditCardViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDonationCreditCardViewController.h"

@interface VLCDonationCreditCardViewController ()
{
    float _donationAmount;
}

@end

@implementation VLCDonationCreditCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.descriptionLabel.text = NSLocalizedString(@"DONATION_CC_INFO_NOT_STORED", nil);
    self.creditCardNumberLabel.text = NSLocalizedString(@"DONATION_CC_NUM", nil);
    self.expiryDateLabel.text = NSLocalizedString(@"DONATION_CC_EXPIRY_DATE", nil);
    self.expiryDateField.placeholder = NSLocalizedString(@"DONATION_CC_EXPIRY_DATE_FORMAT", nil);
    self.cvvLabel.text = NSLocalizedString(@"DONATION_CC_CVV", nil);
    if (@available(iOS 15.0, *)) {
        self.expiryDateField.textContentType = UITextContentTypeDateTime;
    }
    if (@available(iOS 17.0, *)) {
        self.creditCardNumberField.textContentType = UITextContentTypeCreditCardNumber;
        self.expiryDateField.textContentType = UITextContentTypeCreditCardExpiration;
        self.cvvField.textContentType = UITextContentTypeCreditCardSecurityCode;
    }

    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelDonation:)]];
}

- (NSString *)title
{
    return NSLocalizedString(@"DONATION_WINDOW_TITLE", nil);
}

- (void)cancelDonation:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setDonationAmount:(float)donationAmount
{
    _donationAmount = donationAmount;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"DONATION_AMOUNT", nil), _donationAmount];
}

- (IBAction)fieldAction:(id)sender
{
    _continueButton.enabled = _cvvField.text.floatValue > 0. && _expiryDateField.text.length == 5 && _creditCardNumberField.text.length == 16;
}


@end
