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
#import "VLCStripeController.h"
#import "VLCCurrency.h"
#import "VLCDonationPreviousChargesViewController.h"

typedef void (^CompletionHandler)(PKPaymentAuthorizationStatus);

@interface VLCDonationViewController () <VLCActionSheetDelegate, VLCActionSheetDataSource, PKPaymentAuthorizationViewControllerDelegate, VLCStripeControllerDelegate>
{
    NSNumber *_selectedDonationAmount;
    NSArray *_availableCurrencies;
    VLCCurrency *_selectedCurrency;
    BOOL _presentingCurrencySelector;
    VLCActionSheet *_actionSheet;
    PKPaymentButton *_applePayButton;
    UIImageView *_payPalImageView;
    NSMutableArray *_paymentProviders;
    NSString *_selectedPaymentProvider;
    UIColor *_blueColor;
    UIColor *_lightBlueColor;
    BOOL _donationSuccess;
    NSString *_donationErrorMessage;
    NSString *_receiptURLString;
    VLCStripeController *_stripeController;
    CompletionHandler _successCompletionHandler;
    BOOL _recurring;
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

    _stripeController = [[VLCStripeController alloc] init];
    _stripeController.delegate = self;

    /* use Euro as default currency and switch to a supported locale if available */
    NSLocale *locale = [NSLocale currentLocale];
    NSString *currentLocaleCurrency = [locale objectForKey:NSLocaleCurrencyCode];
    _selectedCurrency = [[VLCCurrency alloc] initEUR];
    _availableCurrencies = [VLCCurrency availableCurrencies];
    for (VLCCurrency *currency in _availableCurrencies) {
        if ([currency.isoCode isEqualToString:currentLocaleCurrency]) {
            _selectedCurrency = currency;
            break;
        }
    }
    [self showSelectedCurrency];

    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = NO;
    }
    if (@available(iOS 14.0, *)) {
        self.continueButton.role = UIButtonRolePrimary;
        self.monthlyUpdateButton.role = UIButtonRolePrimary;
        self.monthlyCancelButton.role = UIButtonRoleCancel;
    }

    _titleLabel.text = NSLocalizedString(@"DONATION_TITLE", nil);
    _descriptionLabel.text = NSLocalizedString(@"DONATION_DESCRIPTION", nil);
    _customAmountField.placeholder = NSLocalizedString(@"DONATION_CUSTOM_AMOUNT", nil);
    [_continueButton setTitle:NSLocalizedString(@"DONATION_CONTINUE", nil) forState:UIControlStateNormal];
    [_previousDonationsButton setTitle:NSLocalizedString(@"DONATIONS_PREVIOUS", nil) forState:UIControlStateNormal];
    [_monthlyUpdateButton setTitle:NSLocalizedString(@"DONATION_UPDATE_MONTHLY", nil) forState:UIControlStateNormal];
    [_monthlyCancelButton setTitle:NSLocalizedString(@"DONATION_CANCEL_MONTHLY", nil) forState:UIControlStateNormal];
    [_intervalSelectorControl setTitle:NSLocalizedString(@"DONATION_ONCE", nil) forSegmentAtIndex:0];
    [_intervalSelectorControl setTitle:NSLocalizedString(@"DONATION_MONTHLY", nil) forSegmentAtIndex:1];

    _selectedCurrencyButton.layer.cornerRadius = 5.;
    _continueButton.layer.cornerRadius = 5.;
    _fiveButton.layer.cornerRadius = 5.;
    _tenButton.layer.cornerRadius = 5.;
    _twentyButton.layer.cornerRadius = 5.;
    _thirtyButton.layer.cornerRadius = 5.;
    _fiftyButton.layer.cornerRadius = 5.;
    _hundredButton.layer.cornerRadius = 5.;
    _previousDonationsButton.layer.cornerRadius = 5.;
    _monthlyFirstOptionButton.layer.cornerRadius = 5.;
    _monthlySecondOptionButton.layer.cornerRadius = 5.;
    _monthlyThirdOptionButton.layer.cornerRadius = 5.;
    _monthlyUpdateButton.layer.cornerRadius = 5.;
    _monthlyCancelButton.layer.cornerRadius = 5.;

    self.monthlyPaymentView.hidden = YES;

    _actionSheet = [[VLCActionSheet alloc] init];
    _actionSheet.dataSource = self;
    _actionSheet.delegate = self;
    _actionSheet.modalPresentationStyle = UIModalPresentationCustom;
    [_actionSheet.collectionView registerClass:[VLCActionSheetCell class]
                    forCellWithReuseIdentifier:VLCActionSheetCell.identifier];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(adjustForKeyboard:)
                               name:UIKeyboardWillHideNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(adjustForKeyboard:)
                               name:UIKeyboardWillShowNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(adjustForKeyboard:)
                               name:UIKeyboardWillChangeFrameNotification
                             object:nil];

    [self updateColors];
}

- (void)updateColors
{
    ColorPalette *colors = PresentationTheme.current.colors;

    _blueColor = [UIColor colorWithRed:0.0392 green:0.5176 blue:1. alpha:1.0];
    _lightBlueColor = [UIColor colorWithRed:0.0392 green:0.5176 blue:1. alpha:.5];
    UIColor *whiteColor = [UIColor whiteColor];

    _selectedCurrencyButton.backgroundColor = colors.orangeUI;
    [_selectedCurrencyButton setTitleColor:whiteColor forState:UIControlStateNormal];
    _continueButton.backgroundColor = [UIColor grayColor];
    [_continueButton setTitleColor:whiteColor forState:UIControlStateNormal];
    _customAmountField.backgroundColor = colors.background;
    _customAmountField.layer.borderColor = colors.textfieldBorderColor.CGColor;
    _previousDonationsButton.backgroundColor = colors.orangeDarkAccent;
    [_previousDonationsButton setTitleColor:whiteColor forState:UIControlStateNormal];

    _fiveButton.backgroundColor = _lightBlueColor;
    [_fiveButton setTitleColor:whiteColor forState:UIControlStateNormal];
    _tenButton.backgroundColor = _lightBlueColor;
    [_tenButton setTitleColor:whiteColor forState:UIControlStateNormal];
    _twentyButton.backgroundColor = _lightBlueColor;
    [_twentyButton setTitleColor:whiteColor forState:UIControlStateNormal];
    _thirtyButton.backgroundColor = _lightBlueColor;
    [_thirtyButton setTitleColor:whiteColor forState:UIControlStateNormal];
    _fiftyButton.backgroundColor = _lightBlueColor;
    [_fiftyButton setTitleColor:whiteColor forState:UIControlStateNormal];
    _hundredButton.backgroundColor = _lightBlueColor;
    [_hundredButton setTitleColor:whiteColor forState:UIControlStateNormal];

    _monthlyFirstOptionButton.backgroundColor = _lightBlueColor;
    [_monthlyFirstOptionButton setTitleColor:whiteColor forState:UIControlStateNormal];
    _monthlySecondOptionButton.backgroundColor = _lightBlueColor;
    [_monthlySecondOptionButton setTitleColor:whiteColor forState:UIControlStateNormal];
    _monthlyThirdOptionButton.backgroundColor = _lightBlueColor;
    [_monthlyThirdOptionButton setTitleColor:whiteColor forState:UIControlStateNormal];
    _monthlyUpdateButton.backgroundColor = [UIColor grayColor];
    [_monthlyUpdateButton setTitleColor:whiteColor forState:UIControlStateNormal];
    _monthlyCancelButton.backgroundColor = colors.background;
    [_monthlyCancelButton setTitleColor:colors.lightTextColor forState:UIControlStateNormal];
}

- (void)adjustForKeyboard:(NSNotification *)aNotification
{
    NSDictionary *userInfo = [aNotification userInfo];

    CGRect keyboardFrameEnd = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    id<UICoordinateSpace> fromCoordinateSpace = [(UIScreen *)aNotification.object coordinateSpace];
    id<UICoordinateSpace> toCoordinateSpace = self.view;
    keyboardFrameEnd = [fromCoordinateSpace convertRect:keyboardFrameEnd toCoordinateSpace:toCoordinateSpace];

    if ([aNotification.name isEqualToString: UIKeyboardWillHideNotification]) {
        _contentScrollView.contentInset = UIEdgeInsetsZero;
    } else {
        if (@available(iOS 11.0, *)) {
            _contentScrollView.contentInset = UIEdgeInsetsMake(0., 0., keyboardFrameEnd.size.height - self.view.safeAreaInsets.bottom, 0.);
        } else {
            _contentScrollView.contentInset = UIEdgeInsetsMake(0., 0., keyboardFrameEnd.size.height, 0.);
        }
    }

    [_contentScrollView scrollRectToVisible:_previousDonationsButton.frame animated:YES];
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
    self.selectedCurrencyButton.hidden = bValue;
    self.intervalSelectorControl.hidden = bValue;
    if (bValue) {
        self.previousDonationsButton.hidden = YES;
        self.oneTimePaymentView.hidden = YES;
        self.monthlyPaymentView.hidden = YES;
    } else {
        _previousDonationsButton.hidden = !_stripeController.previousChargesAvailable;
        if (self.intervalSelectorControl.selectedSegmentIndex == 0) {
            self.oneTimePaymentView.hidden = NO;
            self.monthlyPaymentView.hidden = YES;
        } else {
            self.oneTimePaymentView.hidden = YES;
            self.monthlyPaymentView.hidden = NO;
        }
    }
}

- (IBAction)switchCurrency:(id)sender
{
    [_applePayButton removeFromSuperview];
    _applePayButton = nil;
    [_payPalImageView removeFromSuperview];
    _payPalImageView = nil;
    _presentingCurrencySelector = YES;
    [self presentViewController:_actionSheet animated:YES completion:nil];
}

- (IBAction)numberButtonAction:(UIButton *)sender
{
    [UIView animateWithDuration:.25 animations:^{
        [self uncheckNumberButtons];
        sender.selected = YES;
        self->_selectedDonationAmount = [NSNumber numberWithInteger:sender.tag];
        self.continueButton.enabled = YES;
        self.continueButton.backgroundColor = PresentationTheme.current.colors.orangeUI;
        self->_applePayButton.enabled = YES;
        sender.backgroundColor = self->_blueColor;
    }];
}

- (IBAction)continueButtonAction:(id)sender
{
    [_applePayButton removeFromSuperview];
    _applePayButton = nil;
    [_payPalImageView removeFromSuperview];
    _payPalImageView = nil;
    _presentingCurrencySelector = NO;
    [self presentViewController:_actionSheet animated:YES completion:nil];
}

- (IBAction)customAmountFieldAction:(id)sender
{
    [UIView animateWithDuration:.25 animations:^{
        CGFloat floatValue = self.customAmountField.text.floatValue;
        self.continueButton.enabled = floatValue > 0.;
        self.continueButton.backgroundColor = self.continueButton.enabled ? PresentationTheme.current.colors.orangeUI : [UIColor grayColor];
        self->_selectedDonationAmount = [NSNumber numberWithFloat:floatValue];
        [self uncheckNumberButtons];
    }];
}

- (IBAction)showPreviousCharges:(id)sender
{
    VLCDonationPreviousChargesViewController *previousChargesVC = [[VLCDonationPreviousChargesViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:previousChargesVC animated:YES];
}

- (IBAction)segmentedControlAction:(id)sender
{
    _selectedDonationAmount = nil;
    [UIView animateWithDuration:0.5 animations:^{
        if (self.intervalSelectorControl.selectedSegmentIndex == 0) {
            self.oneTimePaymentView.hidden = NO;
            self.monthlyPaymentView.hidden = YES;
            if (self->_selectedCurrency.supportsPayPal) {
                if ([self->_paymentProviders indexOfObject:@"PayPal"] == NSNotFound) {
                    [self->_paymentProviders addObject:@"PayPal"];
                }
            }
            [self uncheckNumberButtons];
            self->_continueButton.enabled = NO;
            self->_continueButton.backgroundColor = [UIColor grayColor];
        } else {
            self.oneTimePaymentView.hidden = YES;
            self.monthlyPaymentView.hidden = NO;
            [self->_paymentProviders removeObject:@"PayPal"];
            [self uncheckMonthlyButtons];
            self->_monthlyUpdateButton.enabled = NO;
            self->_monthlyUpdateButton.backgroundColor = [UIColor grayColor];
        }
    }];
}

#pragma mark - monthly donation actions

- (void)uncheckMonthlyButtons
{
    _monthlyFirstOptionButton.backgroundColor = _lightBlueColor;
    _monthlySecondOptionButton.backgroundColor = _lightBlueColor;
    _monthlyThirdOptionButton.backgroundColor = _lightBlueColor;
}

- (IBAction)monthlyOptionAction:(UIButton *)sender
{
    [UIView animateWithDuration:.25 animations:^{
        [self uncheckMonthlyButtons];
        self->_selectedDonationAmount = [NSNumber numberWithInteger:sender.tag];
        sender.backgroundColor = self->_blueColor;

        self->_monthlyUpdateButton.enabled = YES;
        self->_monthlyUpdateButton.backgroundColor = PresentationTheme.current.colors.orangeUI;
    }];
}

- (IBAction)monthlyUpdateAction:(id)sender
{
    [self continueButtonAction:sender];
}

- (IBAction)monthlyCancelAction:(id)sender
{

}

#pragma mark - action sheet delegate

- (NSString *)headerViewTitle
{
    if (_presentingCurrencySelector) {
        return NSLocalizedString(@"DONATION_CHOOSE_CURRENCY", nil);
    } else {
        return NSLocalizedString(@"DONATION_CHOOSE_PP", nil);
    }
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_presentingCurrencySelector) {
        return _availableCurrencies[indexPath.row];
    } else {
        return _paymentProviders[indexPath.row];
    }
}

- (void)actionSheetWithCollectionView:(UICollectionView *)collectionView didSelectItem:(id)item At:(NSIndexPath *)indexPath
{
    if (_presentingCurrencySelector) {
        _selectedCurrency = _availableCurrencies[indexPath.row];
    } else {
        _selectedPaymentProvider = _paymentProviders[indexPath.row];
    }
}

- (void)actionSheetDidFinishClosingAnimation:(VLCActionSheet *)actionSheet
{
    if (_presentingCurrencySelector) {
        [self showSelectedCurrency];
    } else {
        [self showSelectedPaymentProvider];
    }
}

- (void)showSelectedCurrency
{
    [self uncheckNumberButtons];

    [_selectedCurrencyButton setTitle:_selectedCurrency.localCurrencySymbol forState:UIControlStateNormal];
    NSArray *values = _selectedCurrency.values;

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.currencySymbol = _selectedCurrency.localCurrencySymbol;
    formatter.maximumFractionDigits = 0;

    [_fiveButton setTitle:[formatter stringFromNumber:values[0]] forState:UIControlStateNormal];
    [_fiveButton setTag:[values[0] intValue]];
    [_monthlyFirstOptionButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"DONATION_MONTHLY_FORMAT", nil),
                                         [formatter stringFromNumber:values[0]]] forState:UIControlStateNormal];
    [_monthlyFirstOptionButton setTag:[values[0] intValue]];
    [_tenButton setTitle:[formatter stringFromNumber:values[1]] forState:UIControlStateNormal];
    [_tenButton setTag:[values[1] intValue]];
    [_monthlySecondOptionButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"DONATION_MONTHLY_FORMAT", nil),
                                          [formatter stringFromNumber:values[1]]] forState:UIControlStateNormal];;
    [_monthlySecondOptionButton setTag:[values[1] intValue]];
    [_twentyButton setTitle:[formatter stringFromNumber:values[2]] forState:UIControlStateNormal];
    [_twentyButton setTag:[values[2] intValue]];
    [_monthlyThirdOptionButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"DONATION_MONTHLY_FORMAT", nil),
                                         [formatter stringFromNumber:values[2]]] forState:UIControlStateNormal];;
    [_monthlyThirdOptionButton setTag:[values[2] intValue]];
    [_thirtyButton setTitle:[formatter stringFromNumber:values[3]] forState:UIControlStateNormal];
    [_thirtyButton setTag:[values[3] intValue]];
    [_fiftyButton setTitle:[formatter stringFromNumber:values[4]] forState:UIControlStateNormal];
    [_fiftyButton setTag:[values[4] intValue]];
    [_hundredButton setTitle:[formatter stringFromNumber:values[5]] forState:UIControlStateNormal];
    [_hundredButton setTag:[values[5] intValue]];

    _paymentProviders = [NSMutableArray array];
    if (_selectedCurrency.supportsPayPal) {
        [_paymentProviders addObject:@"PayPal"];
    }
    // Check if Apple Pay is available
    if ([PKPaymentAuthorizationViewController canMakePayments]) {
        [_paymentProviders addObject:@"Apple Pay"];
    }
    /* we need to support credit card authentication via 3D Secure for which we depend on
     * ASWebAuthenticationSession that was introduced in iOS 12 */
    if (@available(iOS 12.0, *)) {
        [_paymentProviders addObject:NSLocalizedString(@"DONATE_CC_DC", nil)];
    }
}

- (void)showSelectedPaymentProvider
{
    _recurring = self.intervalSelectorControl.selectedSegmentIndex != 0;
    if ([_selectedPaymentProvider isEqualToString:@"PayPal"]) {
        VLCDonationPayPalViewController *payPalVC = [[VLCDonationPayPalViewController alloc] initWithNibName:nil bundle:nil];
        [payPalVC setDonationAmount:_selectedDonationAmount.intValue];
        [payPalVC setCurrencyCode:_selectedCurrency.isoCode];
        [self.navigationController pushViewController:payPalVC animated:YES];
    } else if ([_selectedPaymentProvider isEqualToString:@"Apple Pay"]) {
        [self initiateApplePayPayment];
    } else if ([_selectedPaymentProvider isEqualToString:NSLocalizedString(@"DONATE_CC_DC", nil)]) {
        VLCDonationCreditCardViewController *ccVC = [[VLCDonationCreditCardViewController alloc] initWithNibName:nil bundle:nil];
        [ccVC setDonationAmount:_selectedDonationAmount withCurrency:_selectedCurrency recurring:_recurring];
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
    if (_presentingCurrencySelector) {
        [self configureCellForCurrency:cell atIndexPath:indexPath];
    } else {
        [self configureCellForPaymentProvider:cell atIndexPath:indexPath];
    }

    return cell;
}

- (NSInteger)numberOfRows
{
    if (_presentingCurrencySelector) {
        return _availableCurrencies.count;
    }

    return _paymentProviders.count;
}

- (void)configureCellForCurrency:(VLCActionSheetCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    VLCCurrency *currency = _availableCurrencies[indexPath.row];
    cell.name.text = currency.userReadableName;
    cell.name.textAlignment = NSTextAlignmentNatural;
}

- (void)configureCellForPaymentProvider:(VLCActionSheetCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSString *paymentProviderName = _paymentProviders[indexPath.row];
    cell.name.text = @"";

    if ([paymentProviderName isEqualToString:@"Apple Pay"]) {
        if (@available(iOS 10.2, *)) {
            _applePayButton = [PKPaymentButton buttonWithType:PKPaymentButtonTypeDonate style:PKPaymentButtonStyleBlack];
        } else {
            _applePayButton = [PKPaymentButton buttonWithType:PKPaymentButtonTypePlain style:PKPaymentButtonStyleBlack];
        }
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
        _payPalImageView = [[UIImageView alloc] initWithImage:paypalLogo];
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
}

#pragma mark - payment view controller delegate

- (void)initiateApplePayPayment {
    PKPaymentSummaryItem *summaryItem;
    if (_recurring) {
        if (@available(iOS 15.0, *)) {
            PKRecurringPaymentSummaryItem *summary = [PKRecurringPaymentSummaryItem summaryItemWithLabel:NSLocalizedString(@"DONATION_VIDEOLAN", "")
                                                                                                  amount:[NSDecimalNumber decimalNumberWithDecimal:[_selectedDonationAmount decimalValue]]];
            summary.intervalUnit = NSCalendarUnitMonth;
            summary.intervalCount = 1;
            summaryItem = summary;
        } else {
            summaryItem = [PKPaymentSummaryItem summaryItemWithLabel:NSLocalizedString(@"DONATION_MONTHLY_VIDEOLAN", "")
                                                              amount:[NSDecimalNumber decimalNumberWithDecimal:[_selectedDonationAmount decimalValue]]];
        }
    } else {
        summaryItem = [PKPaymentSummaryItem summaryItemWithLabel:NSLocalizedString(@"DONATION_VIDEOLAN", "")
                                                          amount:[NSDecimalNumber decimalNumberWithDecimal:[_selectedDonationAmount decimalValue]]];
    }

    PKPaymentRequest *paymentRequest = [[PKPaymentRequest alloc] init];
    paymentRequest.countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    paymentRequest.merchantIdentifier = @"merchant.org.videolan.vlc";
    paymentRequest.merchantCapabilities = PKMerchantCapability3DS;
    paymentRequest.paymentSummaryItems = @[summaryItem];
    paymentRequest.currencyCode = _selectedCurrency.isoCode;
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
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"DONATION_CONTINUE", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
    _successCompletionHandler = completion;
    [_stripeController processPayment:payment forAmount:_selectedDonationAmount currency:_selectedCurrency recurring:_recurring];
}

- (void)paymentAuthorizationViewControllerDidFinish:(nonnull PKPaymentAuthorizationViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
        if (self->_donationSuccess) {
            [self donationReceived];
        } else {
            if (self->_donationErrorMessage != nil) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"PURCHASE_FAILED",
                                                                                                                   comment: "")
                                                                                         message:self->_donationErrorMessage
                                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * _Nonnull action){
                    [self dismissViewControllerAnimated:YES completion:nil];
                }]];
                alertController.popoverPresentationController.sourceView = self.confettiView;

                [self presentViewController:alertController animated:YES completion:nil];
            }
        }
    }];
}

- (void)stripeProcessingSucceededWithReceipt:(NSString *)receipt
{
    _donationSuccess = YES;
    _receiptURLString = receipt;
    _successCompletionHandler(PKPaymentAuthorizationStatusSuccess);
}

- (void)stripeProcessingFailedWithError:(NSString *)errorMessage
{
    _donationSuccess = NO;
    _donationErrorMessage = errorMessage;
    _successCompletionHandler(PKPaymentAuthorizationStatusFailure);
}

- (void)donationReceived
{
    [self hidePurchaseInterface:YES];
    [self.confettiView startConfetti];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"PURCHASE_SUCESS_TITLE",
                                                                                                       comment: "")
                                                                             message:NSLocalizedString(@"PURCHASE_SUCESS_DESCRIPTION",
                                                                                                       comment: "")
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    if (_receiptURLString != nil) {
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"DONATION_RECEIPT", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action){
            [self dismissViewControllerAnimated:YES completion:nil];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self->_receiptURLString]];
        }]];
    }
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action){
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    alertController.popoverPresentationController.sourceView = self.confettiView;

    [self presentViewController:alertController animated:YES completion:nil];
}

@end
