/*****************************************************************************
 * VLCDonationViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDonationViewController.h"
#import <PassKit/PassKit.h>

@interface VLCDonationViewController ()
{
    CGFloat _selectedDonationAmount;
    PKPaymentButton *_applePayButton;
}

@end

@implementation VLCDonationViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = NO;
    }

    _titleLabel.text = NSLocalizedString(@"DONATION_TITLE", nil);
    _descriptionLabel.text = NSLocalizedString(@"DONATION_DESCRIPTION", nil);
    [_frequencySwitch setTitle:NSLocalizedString(@"DONATION_ONE_TIME", nil) forSegmentAtIndex:0];
    [_frequencySwitch setTitle:NSLocalizedString(@"DONATION_MONTHLY", nil) forSegmentAtIndex:1];
    _customAmountField.placeholder = NSLocalizedString(@"DONATION_CUSTOM_AMOUNT", nil);
    [_continueButton setTitle:NSLocalizedString(@"DONATE_CC_DC", nil) forState:UIControlStateNormal];

    _applePayButton = [PKPaymentButton buttonWithType:PKPaymentButtonTypeDonate style:PKPaymentButtonStyleBlack];
    [_contentScrollView addSubview:_applePayButton];
    _applePayButton.translatesAutoresizingMaskIntoConstraints = NO;
    _applePayButton.enabled = NO;

    NSMutableArray<NSLayoutConstraint*> *constraints = [NSMutableArray array];
    [constraints addObject:[_applePayButton.centerXAnchor constraintEqualToAnchor:_continueButton.centerXAnchor]];
    [constraints addObject:[_applePayButton.widthAnchor constraintEqualToAnchor:_continueButton.widthAnchor]];
    [constraints addObject:[_applePayButton.heightAnchor constraintEqualToAnchor:_continueButton.heightAnchor]];
    [constraints addObject:[_applePayButton.topAnchor constraintEqualToAnchor:_continueButton.bottomAnchor constant:17.]];
    [_contentScrollView addConstraints:constraints];
}

- (NSString *)title
{
    return NSLocalizedString(@"DONATION_WINDOW_TITLE", nil);
}

- (void)uncheckNumberButtons
{
    _fiveButton.selected = NO;
    _tenButton.selected = NO;
    _twentyButton.selected = NO;
    _thirtyButton.selected = NO;
    _fiftyButton.selected = NO;
    _hundredButton.selected = NO;
}

- (IBAction)numberButtonAction:(UIButton *)sender
{
    [self uncheckNumberButtons];
    sender.selected = YES;
    _selectedDonationAmount = sender.tag;
    _continueButton.enabled = YES;
    _applePayButton.enabled = YES;
}

- (IBAction)continueButtonAction:(id)sender
{

}

- (IBAction)customAmountFieldAction:(id)sender
{
    _continueButton.enabled = _applePayButton.enabled = _customAmountField.text.floatValue > 0.;
    [self uncheckNumberButtons];
}

@end
