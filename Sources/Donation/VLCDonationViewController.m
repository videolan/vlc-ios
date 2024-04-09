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
#import "VLCPrice.h"
#import "VLCSubscription.h"
#import "VLCDonationInvoicesViewController.h"
#import "VLCDonationSEPAViewController.h"
#import "VLCSEPA.h"

typedef void (^CompletionHandler)(PKPaymentAuthorizationStatus);

@interface VLCDonationViewController () <VLCActionSheetDelegate, VLCActionSheetDataSource, PKPaymentAuthorizationViewControllerDelegate, VLCStripeControllerDelegate>
{
    BOOL _embargoedCountry;

    NSNumber *_selectedDonationAmount;
    NSArray *_availableCurrencies;
    VLCCurrency *_selectedCurrency;
    VLCPrice *_selectedPrice;
    VLCSubscription *_currentSubscription;
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
    VLCStripeController *_stripeController;
    CompletionHandler _successCompletionHandler;
    BOOL _recurring;

    NSArray <VLCPrice *> *_recurringPriceList;
    NSArray *_monthlyButtonList;
}
@end

@implementation VLCDonationViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!_embargoedCountry) {
        _stripeController.delegate = self;
        [self hidePurchaseInterface:NO];
        [_stripeController requestCurrentCustomerSubscription];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _stripeController = [[VLCAppCoordinator sharedInstance] stripeController];
    _stripeController.delegate = self;
    _embargoedCountry = [_stripeController currentLocaleIsEmbargoed];

    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = NO;
    }

    if (_embargoedCountry) {
        _titleLabel.text = NSLocalizedString(@"DONATION_WINDOW_TITLE", nil);
        _descriptionLabel.text = NSLocalizedString(@"DONATION_EMBARGOED_COUNTRY", nil);
        _descriptionLabel.textAlignment = NSTextAlignmentCenter;
        [self hidePurchaseInterface:YES];
        return;
    }

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

    if (@available(iOS 14.0, *)) {
        self.continueButton.role = UIButtonRolePrimary;
        self.monthlyUpdateButton.role = UIButtonRolePrimary;
        self.monthlyCancelButton.role = UIButtonRoleCancel;
    }

    _titleLabel.text = NSLocalizedString(@"DONATION_TITLE", nil);
    _descriptionLabel.text = NSLocalizedString(@"DONATION_DESCRIPTION", nil);
    _customAmountField.placeholder = NSLocalizedString(@"DONATION_CUSTOM_AMOUNT", nil);
    [_continueButton setTitle:NSLocalizedString(@"DONATION_CONTINUE", nil) forState:UIControlStateNormal];
    [_previousDonationsButton setTitle:NSLocalizedString(@"DONATION_INVOICES_RECEIPTS", nil) forState:UIControlStateNormal];
    [_monthlyUpdateButton setTitle:NSLocalizedString(@"DONATION_CONTINUE", nil) forState:UIControlStateNormal];
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
    _monthlyFirstOptionButton.layer.cornerRadius = 5.;
    _monthlySecondOptionButton.layer.cornerRadius = 5.;
    _monthlyThirdOptionButton.layer.cornerRadius = 5.;
    _monthlyUpdateButton.layer.cornerRadius = 5.;
    _monthlyCancelButton.layer.cornerRadius = 5.;

    _monthlyButtonList = @[_monthlyFirstOptionButton,
                           _monthlySecondOptionButton,
                           _monthlyThirdOptionButton];

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

    self.intervalSelectorControl.selectedSegmentIndex = 0;
    [self segmentedControlAction:self];
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
    [_previousDonationsButton setTitleColor:colors.orangeDarkAccent forState:UIControlStateNormal];

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

    for (UIButton *button in _monthlyButtonList) {
        button.backgroundColor = _lightBlueColor;
        [button setTitleColor:whiteColor forState:UIControlStateNormal];
    }
    [_monthlyUpdateButton setTitleColor:whiteColor forState:UIControlStateNormal];
    self.activityIndicatorView.color = colors.orangeUI;
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
    self.previousDonationsButton.hidden = bValue;
    if (bValue) {
        self.oneTimePaymentView.hidden = YES;
        self.monthlyPaymentView.hidden = YES;
    } else {
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
    [self hidePurchaseInterface:YES];
    [_activityIndicatorView startAnimating];
    [_stripeController handleCustomerToContinueWithTarget:self selector:@selector(showPaymentProviderSelectorSheet)];
}

- (void)showPaymentProviderSelectorSheet
{
    [_activityIndicatorView stopAnimating];
    [self hidePurchaseInterface:NO];
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
        self.continueButton.enabled = floatValue >= self->_selectedCurrency.minimalAmount && floatValue < self->_selectedCurrency.maximalAmount;
        self.continueButton.backgroundColor = self.continueButton.enabled ? PresentationTheme.current.colors.orangeUI : [UIColor grayColor];
        self->_selectedDonationAmount = [NSNumber numberWithFloat:floatValue];
        [self uncheckNumberButtons];
    }];
}

- (IBAction)showPreviousCharges:(id)sender
{
    [self hidePurchaseInterface:YES];
    [_activityIndicatorView startAnimating];
    [_stripeController handleCustomerToContinueWithTarget:self selector:@selector(showInvoicesAndReceipts)];
}

- (void)showInvoicesAndReceipts
{
    [_activityIndicatorView stopAnimating];
    [self hidePurchaseInterface:NO];
    VLCDonationInvoicesViewController *previousChargesVC = [[VLCDonationInvoicesViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:previousChargesVC animated:YES];
}

- (IBAction)segmentedControlAction:(id)sender
{
    _selectedDonationAmount = nil;
    if (self.intervalSelectorControl.selectedSegmentIndex == 0) {
        [UIView animateWithDuration:0.5 animations:^{
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
        }];
    } else {
        [self hidePurchaseInterface:YES];
        [self.activityIndicatorView startAnimating];
        [self checkForSubscription];
    }
}

- (void)checkForSubscription
{
    [self.activityIndicatorView stopAnimating];
    [UIView animateWithDuration:0.5 animations:^{
        [self hidePurchaseInterface:NO];
        self.oneTimePaymentView.hidden = YES;
        self.monthlyPaymentView.hidden = NO;
    }];
    [self->_paymentProviders removeObject:@"PayPal"];
    [self updateMonthlyButtons];
    [_stripeController requestCurrentCustomerSubscription];
}

#pragma mark - monthly donation actions

- (void)setRecurringPriceList:(NSArray<VLCPrice *> *)priceList
{
    if (priceList.count != 3) {
        APLog(@"Price list does not match expections");
        [self.activityIndicatorView stopAnimating];
        return;
    }

    _recurringPriceList = priceList;

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.currencySymbol = _selectedCurrency.localCurrencySymbol;
    formatter.maximumFractionDigits = 0;

    [UIView animateWithDuration:0.5 animations: ^{
        VLCPrice *price = priceList[0];
        self.monthlyFirstOptionButton.hidden = NO;
        [self.monthlyFirstOptionButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"DONATION_MONTHLY_FORMAT", nil),
                                             [formatter stringFromNumber:price.amount]]
                                       forState:UIControlStateNormal];
        [self.monthlyFirstOptionButton setTag:0];

        price = priceList[1];
        self.monthlySecondOptionButton.hidden = NO;
        [self.monthlySecondOptionButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"DONATION_MONTHLY_FORMAT", nil),
                                              [formatter stringFromNumber:price.amount]]
                                        forState:UIControlStateNormal];;
        [self.monthlySecondOptionButton setTag:1];

        price = priceList[2];
        self.monthlyThirdOptionButton.hidden = NO;
        [self.monthlyThirdOptionButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"DONATION_MONTHLY_FORMAT", nil),
                                             [formatter stringFromNumber:price.amount]]
                                       forState:UIControlStateNormal];;
        [self.monthlyThirdOptionButton setTag:2];

        [self.activityIndicatorView stopAnimating];
    }];
    [self updateMonthlyButtons];
}

- (void)setCurrentSubscription:(VLCSubscription *)sub
{
    _currentSubscription = sub;
    [self updateMonthlyButtons];
}

- (void)uncheckMonthlyButtons
{
    _monthlyFirstOptionButton.backgroundColor = _lightBlueColor;
    _monthlySecondOptionButton.backgroundColor = _lightBlueColor;
    _monthlyThirdOptionButton.backgroundColor = _lightBlueColor;
}

- (void)updateMonthlyButtons
{
    ColorPalette *colors = PresentationTheme.current.colors;
    [self uncheckMonthlyButtons];

    if (!_recurringPriceList)
        return;

    if (!_currentSubscription) {
        self->_monthlyUpdateButton.enabled = NO;
        self->_monthlyUpdateButton.backgroundColor = [UIColor grayColor];
        [self->_monthlyUpdateButton setTitle:NSLocalizedString(@"DONATION_CONTINUE", nil) forState:UIControlStateNormal];
        _monthlyCancelButton.backgroundColor = colors.background;
        [_monthlyCancelButton setTitleColor:colors.lightTextColor forState:UIControlStateNormal];
        return;
    }

    for (VLCPrice *price in _recurringPriceList) {
        if ([price.id isEqualToString:_currentSubscription.priceid]) {
            NSUInteger index = [_recurringPriceList indexOfObject:price];
            UIButton *foundButton = _monthlyButtonList[index];
            foundButton.backgroundColor = _blueColor;
            [self setActiveSubscriptionState];
            break;
        }
    }
}

- (void)setActiveSubscriptionState
{
    ColorPalette *colors = PresentationTheme.current.colors;
    [UIView animateWithDuration:.25 animations:^{
        self->_monthlyUpdateButton.enabled = YES;
        self->_monthlyUpdateButton.backgroundColor = colors.orangeUI;
        [self->_monthlyUpdateButton setTitle:NSLocalizedString(@"DONATION_UPDATE_MONTHLY", nil) forState:UIControlStateNormal];
        self->_monthlyCancelButton.enabled = YES;
        [self->_monthlyCancelButton setTitleColor:colors.orangeUI forState:UIControlStateNormal];
    }];
}

- (IBAction)monthlyOptionAction:(UIButton *)sender
{
    [UIView animateWithDuration:.25 animations:^{
        [self uncheckMonthlyButtons];
        self->_selectedPrice = self->_recurringPriceList[sender.tag];
        sender.backgroundColor = self->_blueColor;

        self->_monthlyUpdateButton.enabled = YES;
        self->_monthlyUpdateButton.backgroundColor = PresentationTheme.current.colors.orangeUI;
    }];
}

- (IBAction)monthlyUpdateAction:(id)sender
{
    if (_currentSubscription == nil) {
        [self continueButtonAction:sender];
    } else {
        [self.activityIndicatorView startAnimating];
        [self hidePurchaseInterface:YES];
        [_stripeController updateSubscription:_currentSubscription toPrice:_selectedPrice];
    }
}

- (IBAction)monthlyCancelAction:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DONATION_VIDEOLAN",
                                                                                                       comment: "")
                                                                             message:NSLocalizedString(@"DONATION_CANCEL_LONG",
                                                                                                       comment: "")
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"DONATION_CONTINUE", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action){
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction * _Nonnull action){
        [self->_stripeController cancelSubscription:self->_currentSubscription];
    }]];
    alertController.popoverPresentationController.sourceView = self.monthlyCancelButton;

    [self presentViewController:alertController animated:YES completion:nil];
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
    [UIView animateWithDuration:0.5 animations:^{
        [self.activityIndicatorView startAnimating];
        self.monthlyFirstOptionButton.hidden = YES;
        self.monthlySecondOptionButton.hidden = YES;
        self.monthlyThirdOptionButton.hidden = YES;
    }];
    [_stripeController requestAvailablePricesInCurrency:_selectedCurrency];
    [self uncheckNumberButtons];

    [_selectedCurrencyButton setTitle:_selectedCurrency.localCurrencySymbol forState:UIControlStateNormal];
    NSArray *values = _selectedCurrency.values;

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.currencySymbol = _selectedCurrency.localCurrencySymbol;
    formatter.maximumFractionDigits = 0;

    [_fiveButton setTitle:[formatter stringFromNumber:values[0]] forState:UIControlStateNormal];
    [_fiveButton setTag:[values[0] intValue]];
    [_tenButton setTitle:[formatter stringFromNumber:values[1]] forState:UIControlStateNormal];
    [_tenButton setTag:[values[1] intValue]];
    [_twentyButton setTitle:[formatter stringFromNumber:values[2]] forState:UIControlStateNormal];
    [_twentyButton setTag:[values[2] intValue]];
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
    /* SEPA is available in EU, EFTA and 4 microstates for some currencies, if we have a valid translation for the legal contract
     * As the UK is too complex after Brexit, it is ignored even SEPA is still supported with exceptions */
    if ([VLCSEPA isAvailable] && _selectedCurrency.supportsSEPA) {
        [_paymentProviders addObject:NSLocalizedString(@"DONATION_BANK_TRANSFER", nil)];
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
        if (_selectedPrice) {
            [ccVC setPrice:_selectedPrice withCurrency:_selectedCurrency recurring:_recurring];
        } else {
            [ccVC setDonationAmount:_selectedDonationAmount withCurrency:_selectedCurrency];
        }
        [self.navigationController pushViewController:ccVC animated:YES];
    } else if ([_selectedPaymentProvider isEqualToString:NSLocalizedString(@"DONATION_BANK_TRANSFER", nil)]){
        VLCDonationSEPAViewController *sepaVC = [[VLCDonationSEPAViewController alloc] initWithNibName:nil bundle:nil];
        if (_selectedPrice) {
            [sepaVC setPrice:_selectedPrice withCurrency:_selectedCurrency recurring:_recurring];
        } else {
            [sepaVC setDonationAmount:_selectedDonationAmount withCurrency:_selectedCurrency];
        }
        [self.navigationController pushViewController:sepaVC animated:YES];
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
    if (currency == _selectedCurrency) {
        cell.name.textColor = PresentationTheme.current.colors.orangeUI;
    } else {
        cell.name.textColor = PresentationTheme.current.colors.cellTextColor;
    }
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

#pragma mark - stripe controller delegate

- (void)stripeProcessingSucceeded
{
    [self.activityIndicatorView stopAnimating];
    _donationSuccess = YES;
    if (_successCompletionHandler) {
        _successCompletionHandler(PKPaymentAuthorizationStatusSuccess);
    } else {
        [self donationReceived];
    }
}

- (void)stripeProcessingFailedWithError:(NSString *)errorMessage
{
    _donationSuccess = NO;
    _donationErrorMessage = errorMessage;
    if (_successCompletionHandler) {
        _successCompletionHandler(PKPaymentAuthorizationStatusFailure);
    } else {
        [self donationFailed];
    }
}

#pragma mark - payment view controller delegate

- (void)initiateApplePayPayment {
    PKPaymentSummaryItem *summaryItem;
    NSNumber *amount = _selectedPrice ? _selectedPrice.amount : _selectedDonationAmount;
    if (_recurring) {
        if (@available(iOS 15.0, *)) {
            PKRecurringPaymentSummaryItem *summary = [PKRecurringPaymentSummaryItem summaryItemWithLabel:NSLocalizedString(@"DONATION_VIDEOLAN", "")
                                                                                                  amount:[NSDecimalNumber decimalNumberWithDecimal:[amount decimalValue]]];
            summary.intervalUnit = NSCalendarUnitMonth;
            summary.intervalCount = 1;
            summaryItem = summary;
        } else {
            summaryItem = [PKPaymentSummaryItem summaryItemWithLabel:NSLocalizedString(@"DONATION_MONTHLY_VIDEOLAN", "")
                                                              amount:[NSDecimalNumber decimalNumberWithDecimal:[amount decimalValue]]];
        }
    } else {
        summaryItem = [PKPaymentSummaryItem summaryItemWithLabel:NSLocalizedString(@"DONATION_VIDEOLAN", "")
                                                          amount:[NSDecimalNumber decimalNumberWithDecimal:[amount decimalValue]]];
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
        alertController.popoverPresentationController.sourceView = self.continueButton;
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
    _successCompletionHandler = completion;
    [_stripeController processPayment:payment
                            forAmount:_selectedDonationAmount
                                price:_selectedPrice
                             currency:_selectedCurrency
                            recurring:_recurring];
}

- (void)paymentAuthorizationViewControllerDidFinish:(nonnull PKPaymentAuthorizationViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
        if (self->_donationSuccess) {
            [self donationReceived];
        } else {
            [self donationFailed];
        }
    }];
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
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action){
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    alertController.popoverPresentationController.sourceView = self.confettiView;

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)donationFailed
{
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

@end
