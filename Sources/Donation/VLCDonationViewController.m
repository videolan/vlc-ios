/*****************************************************************************
 * VLCDonationViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023-2024 VideoLAN. All rights reserved.
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

@interface VLCDonationViewController () <VLCActionSheetDelegate, VLCActionSheetDataSource, PKPaymentAuthorizationViewControllerDelegate>
{
    CGFloat _selectedDonationAmount;
    VLCActionSheet *_actionSheet;
    PKPaymentButton *_applePayButton;
    UIImageView *_payPalImageView;
    NSArray *_paymentProviders;
    NSString *_selectedPaymentProvider;
    UIColor *_blueColor;
    UIColor *_lightBlueColor;
    BOOL _donationSuccess;
}

@end

@implementation VLCDonationViewController

- (void)viewWillAppear:(BOOL)animated
{
    [self hidePurchaseInterface:NO];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = NO;
    }
    if (@available(iOS 14.0, *)) {
        self.continueButton.role = UIButtonRolePrimary;
    }

    _titleLabel.text = NSLocalizedString(@"DONATION_TITLE", nil);
    _descriptionLabel.text = NSLocalizedString(@"DONATION_DESCRIPTION", nil);
    [_frequencySwitch setTitle:NSLocalizedString(@"DONATION_ONE_TIME", nil) forSegmentAtIndex:0];
    [_frequencySwitch setTitle:NSLocalizedString(@"DONATION_MONTHLY", nil) forSegmentAtIndex:1];
    _customAmountField.placeholder = NSLocalizedString(@"DONATION_CUSTOM_AMOUNT", nil);
    [_continueButton setTitle:NSLocalizedString(@"BUTTON_CONTINUE", nil) forState:UIControlStateNormal];

    _continueButton.layer.cornerRadius = 5.;
    _fiveButton.layer.cornerRadius = 5.;
    _tenButton.layer.cornerRadius = 5.;
    _twentyButton.layer.cornerRadius = 5.;
    _thirtyButton.layer.cornerRadius = 5.;
    _fiftyButton.layer.cornerRadius = 5.;
    _hundredButton.layer.cornerRadius = 5.;

    // Check if Apple Pay is available
    NSMutableArray *mutableProviders = [NSMutableArray arrayWithObject:@"PayPal"];
    if ([PKPaymentAuthorizationViewController canMakePayments]) {
        [mutableProviders addObject:@"Apple Pay"];
    }
    /* we need to support credit card authentication via 3D Secure for which we depend on
     * ASWebAuthenticationSession that was introduced in iOS 12 */
    if (@available(iOS 12.0, *)) {
        [mutableProviders addObject:NSLocalizedString(@"DONATE_CC_DC", nil)];
    }
    _paymentProviders = [mutableProviders copy];

    _actionSheet = [[VLCActionSheet alloc] init];
    _actionSheet.dataSource = self;
    _actionSheet.delegate = self;
    _actionSheet.modalPresentationStyle = UIModalPresentationCustom;
    [_actionSheet.collectionView registerClass:[VLCActionSheetCell class]
                    forCellWithReuseIdentifier:VLCActionSheetCell.identifier];

    [self updateColors];
}

- (void)updateColors
{
    ColorPalette *colors = PresentationTheme.current.colors;

    _blueColor = [UIColor colorWithRed:0.0392 green:0.5176 blue:1. alpha:1.0];
    _lightBlueColor = [UIColor colorWithRed:0.0392 green:0.5176 blue:1. alpha:.5];
    UIColor *whileColor = [UIColor whiteColor];

    _continueButton.backgroundColor = colors.orangeUI;
    [_continueButton setTitleColor:whileColor forState:UIControlStateNormal];
    _customAmountField.backgroundColor = colors.background;
    _customAmountField.layer.borderColor = colors.textfieldBorderColor.CGColor;

    _fiveButton.backgroundColor = _lightBlueColor;
    [_fiveButton setTitleColor:whileColor forState:UIControlStateNormal];
    _tenButton.backgroundColor = _lightBlueColor;
    [_tenButton setTitleColor:whileColor forState:UIControlStateNormal];
    _twentyButton.backgroundColor = _lightBlueColor;
    [_twentyButton setTitleColor:whileColor forState:UIControlStateNormal];
    _thirtyButton.backgroundColor = _lightBlueColor;
    [_thirtyButton setTitleColor:whileColor forState:UIControlStateNormal];
    _fiftyButton.backgroundColor = _lightBlueColor;
    [_fiftyButton setTitleColor:whileColor forState:UIControlStateNormal];
    _hundredButton.backgroundColor = _lightBlueColor;
    [_hundredButton setTitleColor:whileColor forState:UIControlStateNormal];
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

    _fiveButton.backgroundColor = _lightBlueColor;
    _tenButton.backgroundColor = _lightBlueColor;
    _twentyButton.backgroundColor = _lightBlueColor;
    _thirtyButton.backgroundColor = _lightBlueColor;
    _fiftyButton.backgroundColor = _lightBlueColor;
    _hundredButton.backgroundColor = _lightBlueColor;
}

- (void)hidePurchaseInterface:(BOOL)bValue
{
    self.frequencySwitch.hidden = bValue;
    self.fiveButton.hidden = bValue;
    self.tenButton.hidden = bValue;
    self.twentyButton.hidden = bValue;
    self.thirtyButton.hidden = bValue;
    self.fiftyButton.hidden = bValue;
    self.hundredButton.hidden = bValue;
    self.customAmountField.hidden = bValue;
    self.continueButton.hidden = bValue;
}

- (IBAction)numberButtonAction:(UIButton *)sender
{
    [self uncheckNumberButtons];
    sender.selected = YES;
    _selectedDonationAmount = sender.tag;
    _continueButton.enabled = YES;
    _applePayButton.enabled = YES;
    sender.backgroundColor = _blueColor;
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
        [self initiateApplePayPayment];
    } else if ([_selectedPaymentProvider isEqualToString:NSLocalizedString(@"DONATE_CC_DC", nil)]) {
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
        /* This is a fake button, the action is handled by the containing collection view */
        _applePayButton.userInteractionEnabled = NO;

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

#pragma mark - payment view controller delegate

- (void)initiateApplePayPayment {
    PKPaymentRequest *paymentRequest = [[PKPaymentRequest alloc] init];
    paymentRequest.countryCode = [[NSLocale currentLocale] countryCode];
    paymentRequest.merchantIdentifier = @"merchant.org.videolan.vlc";
    paymentRequest.merchantCapabilities = PKMerchantCapability3DS;
    paymentRequest.paymentSummaryItems = @[
        [PKPaymentSummaryItem summaryItemWithLabel:@"VideoLAN" amount:[NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithFloat:_selectedDonationAmount] decimalValue]]]
    ];
    paymentRequest.currencyCode = @"EUR";
    if (@available(iOS 12.0, *)) {
        paymentRequest.supportedNetworks = @[PKPaymentNetworkVisa, PKPaymentNetworkMasterCard, PKPaymentNetworkDiscover, PKPaymentNetworkAmex, PKPaymentNetworkMaestro];
    } else {
        paymentRequest.supportedNetworks = @[PKPaymentNetworkVisa, PKPaymentNetworkMasterCard, PKPaymentNetworkDiscover, PKPaymentNetworkAmex];
    }

    PKPaymentAuthorizationViewController *paymentAuthorizationViewController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];

    if (paymentAuthorizationViewController) {
        paymentAuthorizationViewController.delegate = self;
        [self presentViewController:paymentAuthorizationViewController animated:YES completion:nil];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DONATION_APPLE_PAY_NOT_POSSIBLE", nil)
                                                                                 message:NSLocalizedString(@"DONATION_APPLE_PAY_NOT_POSSIBLE_LONG", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CONTINUE", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
    // Complete the payment authorization
    _donationSuccess = YES;
    completion(PKPaymentAuthorizationStatusSuccess);
}

- (void)paymentAuthorizationViewControllerDidFinish:(nonnull PKPaymentAuthorizationViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
        if (self->_donationSuccess) {
            [self donationReceived];
        }
    }];
}

- (void)donationReceived
{
    _donationSuccess = NO;
    [self hidePurchaseInterface:YES];
    [self.confettiView startConfetti];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"PURCHASE_SUCESS_TITLE",
                                                                                                       comment: "")
                                                                             message:NSLocalizedString(@"PURCHASE_SUCESS_DESCRIPTION",
                                                                                                       comment: "")
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action){
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];

    [self presentViewController:alertController animated:YES completion:nil];
}

@end
