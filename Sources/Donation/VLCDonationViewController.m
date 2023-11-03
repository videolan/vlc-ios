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
#import "VLC-Swift.h"
#import "VLCDonationPayPalViewController.h"
#import "VLCDonationCreditCardViewController.h"

@interface VLCDonationViewController () <VLCActionSheetDelegate, VLCActionSheetDataSource>
{
    CGFloat _selectedDonationAmount;
    VLCActionSheet *_actionSheet;
    PKPaymentButton *_applePayButton;
    UIImageView *_payPalImageView;
    NSArray *_paymentProviders;
    NSString *_selectedPaymentProvider;
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
    [_continueButton setTitle:NSLocalizedString(@"BUTTON_CONTINUE", nil) forState:UIControlStateNormal];

    _paymentProviders = @[NSLocalizedString(@"DONATE_CC_DC", nil), @"PayPal", @"Apple Pay"];

    _actionSheet = [[VLCActionSheet alloc] init];
    _actionSheet.dataSource = self;
    _actionSheet.delegate = self;
    _actionSheet.modalPresentationStyle = UIModalPresentationCustom;
    [_actionSheet.collectionView registerClass:[VLCActionSheetCell class]
                    forCellWithReuseIdentifier:VLCActionSheetCell.identifier];
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
    [_applePayButton removeFromSuperview];
    _applePayButton = nil;
    [_payPalImageView removeFromSuperview];
    _payPalImageView = nil;

    [self presentViewController:_actionSheet animated:YES completion:nil];
}

- (IBAction)customAmountFieldAction:(id)sender
{
    _continueButton.enabled = _customAmountField.text.floatValue > 0.;
    [self uncheckNumberButtons];
}

#pragma mark - action sheet delegate

- (NSString *)headerViewTitle
{
    return NSLocalizedString(@"DONATION_CHOOSE_PP", nil);
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return _paymentProviders[indexPath.row];
}

- (void)actionSheetWithCollectionView:(UICollectionView *)collectionView didSelectItem:(id)item At:(NSIndexPath *)indexPath
{
    /* Apple Pay is handled by the button directly so no selection will be made */
    _selectedPaymentProvider = _paymentProviders[indexPath.row];
}

- (void)actionSheetDidFinishClosingAnimation:(VLCActionSheet *)actionSheet
{
    if ([_selectedPaymentProvider isEqualToString:@"PayPal"]) {
        VLCDonationPayPalViewController *payPalVC = [[VLCDonationPayPalViewController alloc] initWithNibName:nil bundle:nil];
        [payPalVC setDonationAmount:_selectedDonationAmount];
        [self.navigationController pushViewController:payPalVC animated:YES];
    } else if ([_selectedPaymentProvider isEqualToString:@"Apple Pay"]) {
        APLog(@"Donation done via Apple Pay");
    } else {
        VLCDonationCreditCardViewController *ccVC = [[VLCDonationCreditCardViewController alloc] initWithNibName:nil bundle:nil];
        [ccVC setDonationAmount:_selectedDonationAmount];
        [self.navigationController pushViewController:ccVC animated:YES];
    }
    _selectedPaymentProvider = nil;
}

#pragma mark - action sheet data source

- (UICollectionViewCell *)actionSheetWithCollectionView:(UICollectionView *)collectionView cellForItemAt:(NSIndexPath *)indexPath
{
    VLCActionSheetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:VLCActionSheetCell.identifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[VLCActionSheetCell alloc] init];
    }
    NSString *paymentProviderName = _paymentProviders[indexPath.row];
    cell.name.text = @"";

    if ([paymentProviderName isEqualToString:@"Apple Pay"]) {
        _applePayButton = [PKPaymentButton buttonWithType:PKPaymentButtonTypeDonate style:PKPaymentButtonStyleBlack];
        [cell addSubview:_applePayButton];
        _applePayButton.translatesAutoresizingMaskIntoConstraints = NO;

        NSMutableArray<NSLayoutConstraint*> *constraints = [NSMutableArray array];
        [constraints addObject:[_applePayButton.centerXAnchor constraintEqualToAnchor:cell.centerXAnchor]];
        [constraints addObject:[_applePayButton.widthAnchor constraintEqualToAnchor:cell.widthAnchor multiplier:0.8]];
        [constraints addObject:[_applePayButton.heightAnchor constraintEqualToAnchor:cell.heightAnchor multiplier:0.8]];
        [constraints addObject:[_applePayButton.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor]];
        [cell addConstraints:constraints];
    } else if ([paymentProviderName isEqualToString:@"PayPal"]) {
        UIImage *paypalLogo = [UIImage imageNamed:@"paypal-color"];
        UIImageView *_payPalImageView = [[UIImageView alloc] initWithImage:paypalLogo];
        _payPalImageView.contentMode = UIViewContentModeScaleAspectFit;
        [cell addSubview:_payPalImageView];
        _payPalImageView.translatesAutoresizingMaskIntoConstraints = NO;

        NSMutableArray<NSLayoutConstraint*> *constraints = [NSMutableArray array];
        [constraints addObject:[_payPalImageView.centerXAnchor constraintEqualToAnchor:cell.centerXAnchor]];
        [constraints addObject:[_payPalImageView.widthAnchor constraintEqualToAnchor:cell.widthAnchor]];
        [constraints addObject:[_payPalImageView.heightAnchor constraintEqualToAnchor:cell.heightAnchor multiplier:0.8]];
        [constraints addObject:[_payPalImageView.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor]];
        [cell addConstraints:constraints];
    } else {
        cell.name.text = paymentProviderName;
        cell.name.textAlignment = NSTextAlignmentCenter;
    }

    return cell;
}

- (NSInteger)numberOfRows
{
    return _paymentProviders.count;
}

@end
