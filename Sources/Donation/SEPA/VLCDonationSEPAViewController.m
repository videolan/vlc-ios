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

#import "VLCDonationSEPAViewController.h"
#import "VLCStripeController.h"
#import "VLCCurrency.h"
#import "VLCPrice.h"
#import "VLC-Swift.h"
#import "VLCSEPANotificationViewController.h"

@interface VLCDonationSEPAViewController () <VLCStripeControllerDelegate, UITextFieldDelegate>
{
    NSNumber *_donationAmount;
    VLCPrice *_price;
    VLCCurrency *_currency;
    BOOL _recurring;

    VLCStripeController *_stripeController;

    NSString *_previousTextFieldContent;
    UITextRange *_previousSelection;

    BOOL _sepaAuthorizationDisplayed;
}

@end

@implementation VLCDonationSEPAViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _stripeController = [[VLCAppCoordinator sharedInstance] stripeController];
    _stripeController.delegate = self;

    self.bankAccountNumberLabel.text = NSLocalizedString(@"DONATION_IBAN", nil);
    self.bankAccountNumberField.delegate = self;
    self.nameLabel.text = NSLocalizedString(@"DONATION_NAME", nil);
    self.nameField.placeholder = NSLocalizedString(@"DONATION_NAME_BANK_ACCOUNT", nil);
    self.emailLabel.text = NSLocalizedString(@"DONATION_EMAIL", nil);
    self.descriptionLabel.text = NSLocalizedString(@"DONATION_BANK_TRANSFER_LONG", nil);

    if (@available(iOS 10.0, *)) {
        self.nameField.textContentType = UITextContentTypeName;
        self.emailField.textContentType = UITextContentTypeEmailAddress;
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

    [_bankAccountNumberField addTarget:self
                                action:@selector(reformatAsCardNumber:)
                      forControlEvents:UIControlEventEditingChanged];
}

- (void)updateColors
{
    ColorPalette *colors = PresentationTheme.current.colors;
    _continueButton.backgroundColor = [UIColor grayColor];
    [_continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _continueButton.layer.cornerRadius = 5.;
    _bankAccountNumberField.backgroundColor = colors.background;
    _bankAccountNumberField.layer.borderColor = colors.textfieldBorderColor.CGColor;
    _nameField.backgroundColor = colors.background;
    _nameField.layer.borderColor = colors.textfieldBorderColor.CGColor;
    _emailField.backgroundColor = colors.background;
    _emailField.layer.borderColor = colors.textfieldBorderColor.CGColor;
    _activityIndicator.color = colors.orangeUI;
}

- (void)hideInputElements:(BOOL)bValue
{
    self.bankAccountNumberLabel.hidden = bValue;
    self.nameLabel.hidden = bValue;
    self.emailLabel.hidden = bValue;
    self.bankAccountNumberField.hidden = bValue;
    self.nameField.hidden = bValue;
    self.emailField.hidden = bValue;
    self.continueButton.hidden = bValue;
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
    [super viewWillAppear:animated];

    if (!_sepaAuthorizationDisplayed) {
        VLCSEPANotificationViewController *sepaNotifVC = [[VLCSEPANotificationViewController alloc] initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:sepaNotifVC animated:NO];
        _sepaAuthorizationDisplayed = YES;
        return;
    }

    _stripeController.delegate = self;
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
    _continueButton.enabled = _bankAccountNumberField.text.length >= 13 && [_emailField.text containsString:@"@"] && _nameField.text.length >= 3;
    _continueButton.backgroundColor = _continueButton.enabled ? PresentationTheme.current.colors.orangeUI : [UIColor grayColor];
}

- (IBAction)continueButtonAction:(id)sender
{
    [self hideInputElements:YES];
    [self.activityIndicator startAnimating];

    [_stripeController processPaymentWithSEPAAccount:self.bankAccountNumberField.text
                                                name:self.nameField.text
                                               email:self.emailField.text
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

#pragma mark - credit card number formatting

// Version 1.3
// Source and explanation: http://stackoverflow.com/a/19161529/1709587
// Adapted for IBAN formatting
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

    if ([cardNumberWithoutSpaces length] > 36) {
        // If the user is trying to enter more than 29 digits, we prevent
        // their change, leaving the text field in  its previous state.
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
    if (textField == self.bankAccountNumberField) {
        maxLength = 36; // this includes the spaces
    }

    NSString *currentString = textField.text;
    NSString *newString = [currentString stringByReplacingCharactersInRange:range withString:string];

    // Note textField's current state before performing the change, in case
    // reformatTextField wants to revert it
    _previousTextFieldContent = textField.text;
    _previousSelection = textField.selectedTextRange;

    return newString.length <= maxLength;
}

- (NSString *)removeNonDigits:(NSString *)string
    andPreserveCursorPosition:(NSUInteger *)cursorPosition
{
    NSUInteger originalCursorPosition = *cursorPosition;
    NSMutableString *digitsOnlyString = [NSMutableString new];
    for (NSUInteger i=0; i<[string length]; i++) {
        unichar characterToAdd = [string characterAtIndex:i];
        if (characterToAdd != ' ') {
            NSString *stringToAdd = [NSString stringWithCharacters:&characterToAdd
                                                            length:1];
            [digitsOnlyString appendString:[stringToAdd uppercaseString]];
        } else {
            if (i < originalCursorPosition) {
                (*cursorPosition)--;
            }
        }
    }

    return digitsOnlyString;
}

- (NSString *)insertCreditCardSpaces:(NSString *)string
           andPreserveCursorPosition:(NSUInteger *)cursorPosition
{
    NSMutableString *stringWithAddedSpaces = [NSMutableString new];
    NSUInteger cursorPositionInSpacelessString = *cursorPosition;
    for (NSUInteger i=0; i<[string length]; i++) {
        bool needs4444Spacing = (i > 0 && (i % 4) == 0);
        if (needs4444Spacing) {
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
