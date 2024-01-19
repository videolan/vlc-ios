/*****************************************************************************
 * VLCDonationCreditCardViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023-2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDonationCreditCardViewController.h"
#import "VLCStripeController.h"
#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
#import <AuthenticationServices/AuthenticationServices.h>

#ifndef UITextContentTypeCreditCardExpiration
UITextContentType const UITextContentTypeCreditCardExpiration = @"UITextContentTypeCreditCardExpiration";
UITextContentType const UITextContentTypeCreditCardSecurityCode = @"UITextContentTypeCreditCardSecurityCode";
#endif

#define DEBUG_MODE 0

@interface VLCDonationCreditCardViewController () <VLCStripeControllerDelegate, ASWebAuthenticationPresentationContextProviding>
{
    float _donationAmount;
    NSString *_currencyCode;
    VLCStripeController *_stripeController;
    ASWebAuthenticationSession *_webAuthenticationSession;
}

@end

@implementation VLCDonationCreditCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _stripeController = [[VLCStripeController alloc] init];
    _stripeController.delegate = self;

    self.creditCardNumberLabel.text = NSLocalizedString(@"DONATION_CC_NUM", nil);
    self.expiryDateLabel.text = NSLocalizedString(@"DONATION_CC_EXPIRY_DATE", nil);
    self.expiryDateMonthField.placeholder = NSLocalizedString(@"DONATION_CC_EXPIRY_DATE_MONTH", nil);
    self.expiryDateYearField.placeholder = NSLocalizedString(@"DONATION_CC_EXPIRY_DATE_YEAR", nil);
    self.cvvLabel.text = NSLocalizedString(@"DONATION_CC_CVV", nil);
    if (@available(iOS 15.0, *)) {
        self.expiryDateMonthField.textContentType = UITextContentTypeDateTime;
        self.expiryDateYearField.textContentType = UITextContentTypeDateTime;
    }
    if (@available(iOS 10.0, *)) {
        self.creditCardNumberField.textContentType = UITextContentTypeCreditCardNumber;
    }
    if (@available(iOS 17.0, *)) {
        self.expiryDateMonthField.textContentType = UITextContentTypeCreditCardExpiration;
        self.expiryDateYearField.textContentType = UITextContentTypeCreditCardExpiration;
        self.cvvField.textContentType = UITextContentTypeCreditCardSecurityCode;
    }
    if (@available(iOS 14.0, *)) {
        self.continueButton.role = UIButtonRolePrimary;
    }
    [self.continueButton setTitle:NSLocalizedString(@"DONATION_DONATE_BUTTON", nil) forState:UIControlStateNormal];

    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelDonation:)]];
}

- (void)hideInputElements:(BOOL)bValue
{
    self.creditCardNumberLabel.hidden = bValue;
    self.expiryDateLabel.hidden = bValue;
    self.expiryDateSeparatorLabel.hidden = bValue;
    self.cvvLabel.hidden = bValue;
    self.creditCardNumberField.hidden = bValue;
    self.expiryDateMonthField.hidden = bValue;
    self.expiryDateYearField.hidden = bValue;
    self.cvvField.hidden = bValue;
    self.continueButton.hidden = bValue;

    if (bValue) {
        self.descriptionLabel.text = NSLocalizedString(@"DONATION_DESCRIPTION", nil);
    } else {
        self.descriptionLabel.text = NSLocalizedString(@"DONATION_CC_INFO_NOT_STORED", nil);
    }
}

- (NSString *)title
{
    return NSLocalizedString(@"DONATION_WINDOW_TITLE", nil);
}

- (void)cancelDonation:(id)sender
{
    [_webAuthenticationSession cancel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setDonationAmount:(float)donationAmount withCurrency:(NSString *)currency
{
    _donationAmount = donationAmount;
    _currencyCode = currency;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"DONATION_AMOUNT", nil), _donationAmount];
    [self hideInputElements:NO];
    if (DEBUG_MODE) {
        self.creditCardNumberField.text = @"4242424242424242";
        self.cvvField.text = @"424";
        self.expiryDateMonthField.text = @"12";
        self.expiryDateYearField.text = @"42";
    }
}

- (IBAction)fieldAction:(id)sender
{
    // American Express cards have 4 digits for the CVV
    _continueButton.enabled = _cvvField.text.length >= 3 && _expiryDateMonthField.text.length == 2 && _expiryDateYearField.text.length == 2 && _creditCardNumberField.text.length == 16;
}

- (IBAction)continueButtonAction:(id)sender
{
    [self hideInputElements:YES];
    [self.activityIndicator startAnimating];

    [_stripeController processPaymentWithCard:self.creditCardNumberField.text
                                          cvv:self.cvvField.text
                                     exprMonth:self.expiryDateMonthField.text
                                     exprYear:self.expiryDateYearField.text
                                    forAmount:_donationAmount
                                     currency:_currencyCode];
}

#pragma mark - stripe controller delegation

- (void)stripeProcessingSucceeded {
    [self.activityIndicator stopAnimating];

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

- (void)stripeProcessingFailedWithError:(NSString *)errorMessage
{
    [self.activityIndicator stopAnimating];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"PURCHASE_FAILED",
                                                                                                       comment: "")
                                                                             message:errorMessage
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action){
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)show3DS:(NSURL *)redirectURL withCallbackURL:(NSURL *)callbackURL
{
    _webAuthenticationSession = [[ASWebAuthenticationSession alloc] initWithURL:redirectURL
                                                     callbackURLScheme:callbackURL.scheme
                                                     completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
        if (error != nil) {
            [self stripeProcessingFailedWithError:error.localizedDescription];
            return;
        }

        if (callbackURL) {
            NSURLComponents *components = [NSURLComponents componentsWithString:callbackURL.absoluteString];
            NSArray *queryItems = components.queryItems;
            for (NSURLQueryItem *queryItem in queryItems) {
                if ([queryItem.name isEqualToString:@"payment_intent"]) {
                    [self->_stripeController continueWithPaymentIntent:queryItem.value];
                    break;
                }
            }
        }
    }];

    // Set the presentation context delegate
    _webAuthenticationSession.presentationContextProvider = self;

    // Start the authentication session
    [_webAuthenticationSession start];
}

#pragma mark - ASWebAuthenticationPresentationContextProviding

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session {
    // Return the view controller's view as the anchor for presenting the authentication session
    return self.view.window;
}

@end

#pragma clang diagnostic pop
