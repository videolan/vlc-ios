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
#import "VLCCurrency.h"
#import "VLCPrice.h"
#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
#import <AuthenticationServices/AuthenticationServices.h>

#ifndef UITextContentTypeCreditCardExpiration
UITextContentType const UITextContentTypeCreditCardExpiration = @"UITextContentTypeCreditCardExpiration";
UITextContentType const UITextContentTypeCreditCardSecurityCode = @"UITextContentTypeCreditCardSecurityCode";
#endif

@interface VLCDonationCreditCardViewController () <VLCStripeControllerDelegate, ASWebAuthenticationPresentationContextProviding, UITextFieldDelegate>
{
    NSNumber *_donationAmount;
    VLCPrice *_price;
    VLCCurrency *_currency;
    BOOL _recurring;

    VLCStripeController *_stripeController;
    ASWebAuthenticationSession *_webAuthenticationSession;

    NSString *_previousTextFieldContent;
    UITextRange *_previousSelection;
}

@end

@implementation VLCDonationCreditCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _stripeController = [[VLCAppCoordinator sharedInstance] stripeController];
    _stripeController.delegate = self;

    self.creditCardNumberLabel.text = NSLocalizedString(@"DONATION_CC_NUM", nil);
    self.creditCardNumberField.delegate = self;
    self.expiryDateLabel.text = NSLocalizedString(@"DONATION_CC_EXPIRY_DATE", nil);
    self.expiryDateMonthField.placeholder = NSLocalizedString(@"DONATION_CC_EXPIRY_DATE_MONTH", nil);
    self.expiryDateMonthField.delegate = self;
    self.expiryDateYearField.placeholder = NSLocalizedString(@"DONATION_CC_EXPIRY_DATE_YEAR", nil);
    self.expiryDateYearField.delegate = self;
    self.cvvLabel.text = NSLocalizedString(@"DONATION_CC_CVV", nil);
    self.cvvField.delegate = self;
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

    [self updateColors];

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

    [_creditCardNumberField addTarget:self
                               action:@selector(reformatAsCardNumber:)
                     forControlEvents:UIControlEventEditingChanged];
}

- (void)updateColors
{
    ColorPalette *colors = PresentationTheme.current.colors;
    _continueButton.backgroundColor = [UIColor grayColor];
    [_continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _continueButton.layer.cornerRadius = 5.;
    _creditCardNumberField.backgroundColor = colors.background;
    _creditCardNumberField.layer.borderColor = colors.textfieldBorderColor.CGColor;
    _expiryDateMonthField.backgroundColor = colors.background;
    _expiryDateMonthField.layer.borderColor = colors.textfieldBorderColor.CGColor;
    _expiryDateYearField.backgroundColor = colors.background;
    _expiryDateYearField.layer.borderColor = colors.textfieldBorderColor.CGColor;
    _cvvField.backgroundColor = colors.background;
    _cvvField.layer.borderColor = colors.textfieldBorderColor.CGColor;
    _activityIndicator.color = colors.orangeUI;
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
        self.descriptionLabel.text = NSLocalizedString(@"DONATION_BANK_TRANSFER_LONG", nil);
    }
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
        _contentScrollView.contentInset = UIEdgeInsetsMake(0., 0., keyboardFrameEnd.size.height - self.view.safeAreaInsets.bottom, 0.);
    }

    [_contentScrollView scrollRectToVisible:_continueButton.frame animated:YES];
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

- (void)setDonationAmount:(NSNumber *)donationAmount withCurrency:(VLCCurrency *)currency
{
    _donationAmount = donationAmount;
    _currency = currency;
}

- (void)setPrice:(VLCPrice *)selectedPrice withCurrency:(VLCCurrency *)currency recurring:(BOOL)recurring
{
    _price = selectedPrice;
    _currency = currency;
    _recurring = recurring;
}

- (void)viewWillAppear:(BOOL)animated
{
    _stripeController.delegate = self;
    [super viewWillAppear:animated];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.currencySymbol = _currency.localCurrencySymbol;
    formatter.maximumFractionDigits = 0;

    NSNumber *amount = _price ? _price.amount : _donationAmount;
    if (_recurring) {
        self.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"DONATION_AMOUNT", nil),
                                [NSString stringWithFormat:NSLocalizedString(@"DONATION_MONTHLY_FORMAT", nil), [formatter stringFromNumber:amount]]];
    } else {
        self.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"DONATION_AMOUNT", nil), [formatter stringFromNumber:amount]];
    }
    [self hideInputElements:NO];
}

- (IBAction)fieldAction:(id)sender
{
    // American Express cards have 4 digits for the CVV and only 15 digits
    _continueButton.enabled = _cvvField.text.length >= 3 && _expiryDateMonthField.text.length == 2 && _expiryDateYearField.text.length == 2 && _creditCardNumberField.text.length >= 15;
    _continueButton.backgroundColor = _continueButton.enabled ? PresentationTheme.current.colors.orangeUI : [UIColor grayColor];
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
                                        price:_price
                                     currency:_currency
                                    recurring:_recurring];
}

#pragma mark - stripe controller delegation

- (void)stripeProcessingSucceeded
{
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
    alertController.popoverPresentationController.sourceView = self.confettiView;

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
                                                      handler:^(UIAlertAction * _Nonnull action) {
        [self hideInputElements:NO];
    }]];
    alertController.popoverPresentationController.sourceView = self.confettiView;

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
                } else if ([queryItem.name isEqualToString:@"setup_intent"]) {
                    [self->_stripeController continueWithSetupIntent:queryItem.value];
                    break;
                } else {
                    APLog(@"invalid query item name: %@", queryItem.name);
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

#pragma mark - credit card number formatting

// Version 1.3
// Source and explanation: http://stackoverflow.com/a/19161529/1709587
-(void)reformatAsCardNumber:(UITextField *)textField
{
    // In order to make the cursor end up positioned correctly, we need to
    // explicitly reposition it after we inject spaces into the text.
    // targetCursorPosition keeps track of where the cursor needs to end up as
    // we modify the string, and at the end we set the cursor position to it.
    NSUInteger targetCursorPosition = [textField offsetFromPosition:textField.beginningOfDocument
                                                         toPosition:textField.selectedTextRange.start];

    NSString *cardNumberWithoutSpaces = [self removeNonDigits:textField.text
                                    andPreserveCursorPosition:&targetCursorPosition];

    if ([cardNumberWithoutSpaces length] > 19) {
        // If the user is trying to enter more than 19 digits, we prevent
        // their change, leaving the text field in  its previous state.
        // While 16 digits is usual, credit card numbers have a hard
        // maximum of 19 digits defined by ISO standard 7812-1 in section
        // 3.8 and elsewhere. Applying this hard maximum here rather than
        // a maximum of 16 ensures that users with unusual card numbers
        // will still be able to enter their card number even if the
        // resultant formatting is odd.
        [textField setText:_previousTextFieldContent];
        textField.selectedTextRange = _previousSelection;
        return;
    }

    NSString *cardNumberWithSpaces =
    [self insertCreditCardSpaces:cardNumberWithoutSpaces andPreserveCursorPosition:&targetCursorPosition];

    textField.text = cardNumberWithSpaces;
    UITextPosition *targetPosition = [textField positionFromPosition:[textField beginningOfDocument]
                                                              offset:targetCursorPosition];

    [textField setSelectedTextRange: [textField textRangeFromPosition:targetPosition
                                                           toPosition:targetPosition]
    ];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    int maxLength = 0;
    if (textField == self.creditCardNumberField) {
        maxLength = 19; // this includes the spaces
    } else if (textField == self.expiryDateMonthField || textField == self.expiryDateYearField) {
        maxLength = 2;
    } else if (textField == self.cvvField) {
        maxLength = 4;
    }

    NSString *currentString = textField.text;
    NSString *newString = [currentString stringByReplacingCharactersInRange:range withString:string];

    // Note textField's current state before performing the change, in case
    // reformatTextField wants to revert it
    _previousTextFieldContent = textField.text;
    _previousSelection = textField.selectedTextRange;

    return newString.length <= maxLength;
}

/*
 Removes non-digits from the string, decrementing `cursorPosition` as
 appropriate so that, for instance, if we pass in `@"1111 1123 1111"`
 and a cursor position of `8`, the cursor position will be changed to
 `7` (keeping it between the '2' and the '3' after the spaces are removed).
 */
- (NSString *)removeNonDigits:(NSString *)string
    andPreserveCursorPosition:(NSUInteger *)cursorPosition
{
    NSUInteger originalCursorPosition = *cursorPosition;
    NSMutableString *digitsOnlyString = [NSMutableString new];
    for (NSUInteger i=0; i<[string length]; i++) {
        unichar characterToAdd = [string characterAtIndex:i];
        if (isdigit(characterToAdd)) {
            NSString *stringToAdd =
            [NSString stringWithCharacters:&characterToAdd
                                    length:1];

            [digitsOnlyString appendString:stringToAdd];
        } else {
            if (i < originalCursorPosition) {
                (*cursorPosition)--;
            }
        }
    }

    return digitsOnlyString;
}

/*
 Detects the card number format from the prefix, then inserts spaces into
 the string to format it as a credit card number, incrementing `cursorPosition`
 as appropriate so that, for instance, if we pass in `@"111111231111"` and a
 cursor position of `7`, the cursor position will be changed to `8` (keeping
 it between the '2' and the '3' after the spaces are added).
 */
- (NSString *)insertCreditCardSpaces:(NSString *)string
           andPreserveCursorPosition:(NSUInteger *)cursorPosition
{
    // Mapping of card prefix to pattern is taken from
    // https://baymard.com/checkout-usability/credit-card-patterns

    // UATP cards have 4-5-6 (XXXX-XXXXX-XXXXXX) format
    bool is456 = [string hasPrefix: @"1"];

    // These prefixes reliably indicate either a 4-6-5 or 4-6-4 card. We treat all
    // these as 4-6-5-4 to err on the side of always letting the user type more
    // digits.
    bool is465 = [string hasPrefix: @"34"] ||
    [string hasPrefix: @"37"] ||

    // Diners Club
    [string hasPrefix: @"300"] ||
    [string hasPrefix: @"301"] ||
    [string hasPrefix: @"302"] ||
    [string hasPrefix: @"303"] ||
    [string hasPrefix: @"304"] ||
    [string hasPrefix: @"305"] ||
    [string hasPrefix: @"309"] ||
    [string hasPrefix: @"36"] ||
    [string hasPrefix: @"38"] ||
    [string hasPrefix: @"39"];

    // In all other cases, assume 4-4-4-4-3.
    // This won't always be correct; for instance, Maestro has 4-4-5 cards
    // according to https://baymard.com/checkout-usability/credit-card-patterns,
    // but I don't know what prefixes identify particular formats.
    bool is4444 = !(is456 || is465);

    NSMutableString *stringWithAddedSpaces = [NSMutableString new];
    NSUInteger cursorPositionInSpacelessString = *cursorPosition;
    for (NSUInteger i=0; i<[string length]; i++) {
        bool needs465Spacing = (is465 && (i == 4 || i == 10 || i == 15));
        bool needs456Spacing = (is456 && (i == 4 || i == 9 || i == 15));
        bool needs4444Spacing = (is4444 && i > 0 && (i % 4) == 0);

        if (needs465Spacing || needs456Spacing || needs4444Spacing) {
            [stringWithAddedSpaces appendString:@" "];
            if (i < cursorPositionInSpacelessString) {
                (*cursorPosition)++;
            }
        }
        unichar characterToAdd = [string characterAtIndex:i];
        NSString *stringToAdd =
        [NSString stringWithCharacters:&characterToAdd length:1];

        [stringWithAddedSpaces appendString:stringToAdd];
    }

    return stringWithAddedSpaces;
}

@end

#pragma clang diagnostic pop
