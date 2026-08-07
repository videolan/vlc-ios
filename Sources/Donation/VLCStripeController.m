/*****************************************************************************
 * VLCStripeController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024, 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCStripeController.h"
#import <PassKit/PassKit.h>
#import "VLCStripeConstants.h"
#import "VLCHTTPClient.h"
#import "VLCCurrency.h"
#import "VLCInvoice.h"
#import "VLCCharge.h"
#import "VLCPrice.h"
#import "VLCSubscription.h"
#import "VLCDonationInvoicesViewController.h"
#import "VLCDonationViewController.h"

@interface VLCStripeController()
{
    VLCCurrency *_currency;
    NSString *_amount;
    VLCPrice *_price;
    BOOL _recurring;

    NSString *_tokenID;

    NSString *_customerID;
    NSString *_uuid;

    NSString *_paymentMethod;

    VLCHTTPClient *_client;
}
@end

@implementation VLCStripeController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _client = [[VLCHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.stripe.com/v1/"]];
    }
    return self;
}

- (BOOL)currentLocaleIsEmbargoed
{
    NSString *countryCode = [[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] uppercaseString];
    NSArray *embargoedCountries = @[@"CU", @"IR", @"KP", @"SD", @"SY"]; // Cuba, Iran, North Korea, Sudan, Syria
    for (NSString *embargoedCountry in embargoedCountries) {
        if ([embargoedCountry isEqualToString:countryCode]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - apple pay internals

- (void)processPayment:(PKPayment *)payment
             forAmount:(NSNumber *)amount
                 price:(VLCPrice *)price
              currency:(VLCCurrency *)currency
             recurring:(BOOL)recurring
{
    APLog(@"Processing ApplePay, recurring? %i fixed price? %i", recurring, price != nil);
    _currency = currency;
    _amount = [[NSNumber numberWithInt:amount.intValue * _currency.stripeMultiplier] stringValue];
    _price = price;
    _recurring = recurring;
    _tokenID = nil;

    NSDictionary *parameters = [self constructParametersForPayment:payment];
    [self createStripeTokenWithParameters:parameters];
}

- (NSDictionary *)constructParametersForPayment:(PKPayment *)payment
{
    NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
    mutDict[@"pk_token"] = [[NSString alloc] initWithData:payment.token.paymentData encoding:NSUTF8StringEncoding];

    PKContact *contact = payment.billingContact;
    if (contact) {
        NSMutableDictionary *cardMutDict = [NSMutableDictionary dictionary];
        NSPersonNameComponents *name = contact.name;
        if (name) {
            cardMutDict[@"name"] = [NSPersonNameComponentsFormatter localizedStringFromPersonNameComponents:name style:NSPersonNameComponentsFormatterStyleDefault options:0];
        }

        NSString *email = contact.emailAddress;
        if (email) {
            cardMutDict[@"email"] = email;
        }

        CNPhoneNumber *phoneNumber = contact.phoneNumber;
        if (phoneNumber) {
            cardMutDict[@"phone"] = phoneNumber.stringValue ? phoneNumber.stringValue : [NSNull null];
        }

        CNPostalAddress *address = contact.postalAddress;
        if (address) {
            cardMutDict[@"address_line1"] = address.street ? address.street : [NSNull null];
            cardMutDict[@"address_city"] = address.city ? address.city : [NSNull null];
            cardMutDict[@"address_state"] = address.state ? address.state : [NSNull null];
            cardMutDict[@"address_zip"] = address.postalCode ? address.postalCode : [NSNull null];
            cardMutDict[@"address_country"] = address.ISOCountryCode ?  address.ISOCountryCode.uppercaseString : [NSNull null];
        }

        mutDict[@"card"] = [cardMutDict copy];
    }

    mutDict[@"pk_token_instrument_name"] = payment.token.paymentMethod.displayName;
    mutDict[@"pk_token_payment_network"] = payment.token.paymentMethod.network;

    if ([payment.token.transactionIdentifier isEqualToString:@"Simulated Identifier"]) {
        /* use a fake ID */
        mutDict[@"pk_token_transaction_id"] = [NSString stringWithFormat:@"ApplePayStubs~4242424242424242~0~USD~%@", [[NSUUID UUID] UUIDString]];
    } else {
        mutDict[@"pk_token_transaction_id"] = payment.token.transactionIdentifier ? payment.token.transactionIdentifier : [NSNull null];
    }

    return [mutDict copy];
}

#pragma mark - CB internals

- (void)processPaymentWithCard:(NSString *)cardNumber
                           cvv:(NSString *)cvv
                     exprMonth:(NSString *)month
                      exprYear:(NSString *)year
                     forAmount:(NSNumber *)amount
                         price:(VLCPrice *)price
                      currency:(VLCCurrency *)currency
                     recurring:(BOOL)recurring
{
    APLog(@"Processing CB, recurring? %i fixed price? %i", recurring, price != nil);
    _currency = currency;
    _amount = [[NSNumber numberWithInt:amount.intValue * _currency.stripeMultiplier] stringValue];
    _price = price;
    _recurring = recurring;
    _tokenID = nil;

    NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
    mutDict[@"card[number]"] = cardNumber;
    mutDict[@"card[exp_month]"] = month;
    mutDict[@"card[exp_year]"] = year;
    mutDict[@"card[cvc]"] = cvv;

    [self createStripeTokenWithParameters:[mutDict copy]];
}

#pragma mark - SEPA internals

- (void)processPaymentWithSEPAAccount:(NSString *)accountNumber
                                 name:(NSString *)name
                                email:(NSString *)email
                            forAmount:(NSNumber *)amount
                                price:(VLCPrice *)price
                             currency:(VLCCurrency *)currency
                            recurring:(BOOL)recurring
{
    APLog(@"Processing SEPA payment, recurring? %i fixed price? %i", recurring, price != nil);
    _currency = currency;
    _amount = [[NSNumber numberWithInt:amount.intValue * _currency.stripeMultiplier] stringValue];
    _price = price;
    _recurring = recurring;
    _tokenID = nil;

    [_client POST:@"payment_methods"
       parameters:@{ @"type" : @"sepa_debit",
                     @"[sepa_debit][iban]" : accountNumber,
                     @"[billing_details][name]" : name,
                     @"[billing_details][email]" : email }
          headers:[self secretKeyHeaders]
          success:^(NSDictionary *jsonResponse) {
        APLog(@"SEPA payment method created");
        self->_paymentMethod = jsonResponse[@"id"];
        if (self->_recurring) {
            [self confirmSetupIntent];
        } else {
            [self confirmPaymentIntent];
        }
    }
          failure:^(NSError *error) {
        APLog(@"Error creating sepa payment method: %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

#pragma mark - generic API

- (NSDictionary *)publishableKeyHeaders
{
    return @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", kVLCStripePublishableAPIKey],
              @"Content-Type" : @"application/x-www-form-urlencoded" };
}

- (NSDictionary *)secretKeyHeaders
{
    return @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", kVLCStripeSecretAPIKey],
              @"Content-Type" : @"application/x-www-form-urlencoded" };
}

#pragma mark - token creation

- (void)createStripeTokenWithParameters:(NSDictionary *)parameters
{
    [_client POST:@"tokens"
       parameters:parameters
          headers:[self publishableKeyHeaders]
          success:^(NSDictionary *jsonResponse) {
        self->_tokenID = jsonResponse[@"id"];
        if (self->_tokenID) {
            APLog(@"Stripe token created successfully");
            if (self->_recurring) {
                [self confirmSetupIntent];
            } else {
                [self confirmPaymentIntent];
            }
        } else {
            APLog(@"Error creating Stripe token: %@", jsonResponse);
            NSDictionary *errorDict = jsonResponse[@"error"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate stripeProcessingFailedWithError:errorDict ? errorDict[@"message"] : @"unknown"];
            });
        }
    }
          failure:^(NSError *error) {
        APLog(@"Error creating Stripe token: %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

#pragma mark - payment handling

- (void)confirmPaymentIntent
{
    NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
    mutDict[@"confirm"] = @"true";
    mutDict[@"amount"] = _amount;
    mutDict[@"currency"] = _currency.isoCode;
    mutDict[@"return_url"] = kVLCStripeCallbackURL;
    mutDict[@"customer"] = _customerID;

    if (_tokenID == nil) {
        mutDict[@"payment_method_types"] = @[@"sepa_debit"];
        mutDict[@"payment_method"] = _paymentMethod;
        mutDict[@"mandate_data[customer_acceptance"] = @{ @"type" : @"online",
                                                          @"accepted_at" : [NSNumber numberWithLongLong:(long long)[[NSDate date] timeIntervalSince1970]],
                                                          @"online" : @{ @"ip_address" : @"0.0.0.0",
                                                                         @"user_agent" : _client.userAgent}};
    } else {
        mutDict[@"payment_method_types"] = @[@"card"];
        mutDict[@"payment_method_data"] = @{ @"type" : @"card", @"card[token]" : _tokenID };
    }

    [_client POST:@"payment_intents"
       parameters:mutDict
          headers:[self secretKeyHeaders]
          success:^(NSDictionary *jsonResponse) {
        NSDictionary *nextAction = jsonResponse[@"next_action"];
        self->_paymentMethod = jsonResponse[@"payment_method"];
        if (nextAction == (NSDictionary*) [NSNull null]) {
            APLog(@"Payment intent was approved, no further action needed");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate stripeProcessingSucceeded];
                [self donationSuccessful];
            });
        } else {
            APLog(@"Received a next action on payment intent confirmation");
            NSDictionary *redirectToURL = nextAction[@"redirect_to_url"];
            NSString *url = redirectToURL[@"url"];
            NSURL *redirectURL = [NSURL URLWithString:url];
            if (redirectURL != nil) {
                if ([self.delegate respondsToSelector:@selector(show3DS:withCallbackURL:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate show3DS:(NSURL *)redirectURL withCallbackURL:[NSURL URLWithString:kVLCStripeCallbackURL]];
                    });
                    return;
                }
            }
        }
    }
          failure:^(NSError *error) {
        APLog(@"Payment intent confirmation failed: %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

- (void)continueWithPaymentIntent:(NSString *)paymentIntent
{
    [_client POST:[NSString stringWithFormat:@"payment_intents/%@", paymentIntent]
       parameters:nil
          headers:[self secretKeyHeaders]
          success:^(NSDictionary *jsonResponse) {
        APLog(@"Successfully confirmed payment intent after additional action");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self donationSuccessful];
            [self.delegate stripeProcessingSucceeded];
        });
    }
          failure:^(NSError *error) {
        APLog(@"Failed to confirm payment intent after additional action: %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

#pragma mark - confirmSetupIntent

- (void)confirmSetupIntent
{
    NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
    mutDict[@"confirm"] = @"true";
    mutDict[@"usage"] = @"off_session";
    mutDict[@"return_url"] = kVLCStripeCallbackURL;
    mutDict[@"customer"] = _customerID;

    if (_tokenID == nil) {
        mutDict[@"payment_method_types"] = @[@"sepa_debit"];
        mutDict[@"payment_method"] = _paymentMethod;
        mutDict[@"mandate_data[customer_acceptance"] = @{ @"type" : @"online",
                                                          @"accepted_at" : [NSNumber numberWithLongLong:(long long)[[NSDate date] timeIntervalSince1970]],
                                                          @"online" : @{ @"ip_address" : @"0.0.0.0",
                                                                         @"user_agent" : _client.userAgent}};
    } else {
        mutDict[@"payment_method_types"] = @[@"card"];
        mutDict[@"payment_method_data"] = @{ @"type" : @"card", @"card[token]" : _tokenID };
    }

    [_client POST:@"setup_intents"
       parameters:mutDict
          headers:[self secretKeyHeaders]
          success:^(NSDictionary *jsonResponse) {
        APLog(@"Created Setup Intent");
        NSDictionary *nextAction = jsonResponse[@"next_action"];
        if (nextAction == (NSDictionary*) [NSNull null]) {
            APLog(@"Setup intent was approved, no further action needed");
            self->_paymentMethod = jsonResponse[@"payment_method"];
            [self attachPaymentMethodToCustomer];
        } else {
            APLog(@"Received a next action on setup intent confirmation");
            NSDictionary *redirectToURL = nextAction[@"redirect_to_url"];
            NSString *url = redirectToURL[@"url"];
            NSURL *redirectURL = [NSURL URLWithString:url];
            if (redirectURL != nil) {
                if ([self.delegate respondsToSelector:@selector(show3DS:withCallbackURL:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate show3DS:(NSURL *)redirectURL withCallbackURL:[NSURL URLWithString:kVLCStripeCallbackURL]];
                    });
                    return;
                }
            }
        }
    }
          failure:^(NSError *error) {
        APLog(@"%s: %@", __func__, error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

- (void)continueWithSetupIntent:(NSString *)setupIntent
{
    [_client POST:[NSString stringWithFormat:@"setup_intents/%@", setupIntent]
       parameters:nil
          headers:[self secretKeyHeaders]
          success:^(NSDictionary *jsonResponse) {
        APLog(@"Setup intent was approved after further action");
        self->_paymentMethod = jsonResponse[@"payment_method"];
        [self attachPaymentMethodToCustomer];
    }
          failure:^(NSError *error) {
        APLog(@"Failed to confirm setup intent after additional action: %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

#pragma mark - payment method handling

- (void)attachPaymentMethodToCustomer
{
    [_client POST:[NSString stringWithFormat:@"payment_methods/%@/attach", _paymentMethod]
       parameters:@{@"customer" : _customerID}
          headers:[self secretKeyHeaders]
          success:^(NSDictionary *jsonResponse) {
        APLog(@"payment method attached");
        [self makePaymentMethodDefaultForCustomer];
    }
          failure:^(NSError *error) {
        APLog(@"%s: %@", __func__, error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

- (void)makePaymentMethodDefaultForCustomer
{
    [_client POST:[NSString stringWithFormat:@"customers/%@", _customerID]
       parameters:@{@"invoice_settings" : @{@"default_payment_method" : _paymentMethod}}
          headers:[self secretKeyHeaders]
          success:^(NSDictionary *jsonResponse) {
        APLog(@"Set as default payment method");
        [self addSubscription];
    }
          failure:^(NSError *error) {
        APLog(@"%s: %@", __func__, error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

#pragma mark - subscription management

- (void)addSubscription
{
    [_client POST:@"subscriptions"
       parameters:@{@"customer" : _customerID,
                    @"items[0][price]" : _price.id}
          headers:[self secretKeyHeaders]
          success:^(NSDictionary *jsonResponse) {
        APLog(@"Subscription added");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingSucceeded];
            [self activeSubscription:YES];
        });
    }
          failure:^(NSError *error) {
        APLog(@"%s: %@", __func__, error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

- (void)requestCurrentCustomerSubscription
{
    if (_customerID == nil) {
        // let's check if there is a customer stored that wasn't loaded yet
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _customerID = [defaults stringForKey:kVLCDonationAnonymousCustomerID];
        if (_customerID != nil) {
            [self handleCustomerToContinueWithTarget:self selector:@selector(requestCurrentCustomerSubscription)];
        }
        return;
    }
    [_client GET:@"subscriptions"
      parameters:@{@"customer" : _customerID}
         headers:[self secretKeyHeaders]
         success:^(NSDictionary *jsonResponse) {
        NSArray *searchResultList = jsonResponse[@"data"];
        NSUInteger resultCount = searchResultList.count;
        APLog(@"Found %li subscriptions", resultCount);

        VLCSubscription *sub;
        if (resultCount == 1) {
            sub = [[VLCSubscription alloc] initWithDictionary:searchResultList.firstObject];
        }

        if ([self.delegate respondsToSelector:@selector(setCurrentSubscription:)]) {
            [self.delegate setCurrentSubscription:sub];
        }
    }
         failure:^(NSError *error) {
        APLog(@"%s: %@", __func__, error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

- (void)updateSubscription:(VLCSubscription *)sub toPrice:(VLCPrice *)price
{
    _price = price;
    [_client POST:[NSString stringWithFormat:@"subscriptions/%@", sub.subscriptionid]
       parameters:@{@"items[0][id]" : sub.subscriptionitemid,
                    @"items[0][price]" : _price.id}
          headers:[self secretKeyHeaders]
          success:^(NSDictionary *jsonResponse) {
        APLog(@"Subscription updated");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingSucceeded];
            [self activeSubscription:YES];
        });
    }
          failure:^(NSError *error) {
        APLog(@"%s: %@", __func__, error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

- (void)cancelSubscription:(VLCSubscription *)sub
{
    [_client DELETE:[NSString stringWithFormat:@"subscriptions/%@", sub.subscriptionid]
         parameters:nil
            headers:[self secretKeyHeaders]
            success:^(NSDictionary *jsonResponse) {
        APLog(@"Subscription cancelled");
        if ([self.delegate respondsToSelector:@selector(setCurrentSubscription:)]) {
            [self.delegate setCurrentSubscription:nil];
            [self activeSubscription:NO];
        }
    }
            failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
        APLog(@"%s: %@", __func__, error.localizedDescription);
    }];
}

#pragma mark - pricing

- (void)requestAvailablePricesInCurrency:(VLCCurrency *)currency
{
    [_client GET:@"prices"
      parameters:@{@"currency" : currency.isoCode,
                   @"type" : @"recurring",
                   @"expand[]" : @"data.currency_options"}
         headers:[self secretKeyHeaders]
         success:^(NSDictionary *jsonResponse) {
        NSArray *dictList = jsonResponse[@"data"];
        NSUInteger priceCount = dictList.count;
        NSMutableArray *priceList = [NSMutableArray arrayWithCapacity:priceCount];
        for (NSDictionary *dict in dictList) {
            VLCPrice *price = [[VLCPrice alloc] initWithDictionary:dict
                                                       forCurrency:currency];
            if (price.active) {
                [priceList addObject:price];
            }
        }
        if ([self.delegate respondsToSelector:@selector(setRecurringPriceList:)]) {
            [self.delegate setRecurringPriceList:priceList];
        }
    }
         failure:^(NSError *error) {
        APLog(@"Error retrieving recurring pricelist: %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

#pragma mark - customer handling

- (void)handleCustomerToContinueWithTarget:(id)target selector:(SEL)action
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _customerID = [defaults stringForKey:kVLCDonationAnonymousCustomerID];

    if (_customerID != nil && _customerID.length > 0) {
        if (!self->_uuid) {
            [_client GET:[NSString stringWithFormat:@"customers/%@", _customerID]
              parameters:nil
                 headers:[self secretKeyHeaders]
                 success:^(NSDictionary *jsonResponse) {
                APLog(@"Reloaded customer");
                self->_uuid = jsonResponse[@"name"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [target performSelector:action];
#pragma clang diagnostic pop
            }
                 failure:^(NSError *error) {
                APLog(@"Error reloading customer: %@, deleting...", error.localizedDescription);
                self->_customerID = nil;
                self->_uuid = nil;
                [defaults removeObjectForKey:kVLCDonationAnonymousCustomerID];
            }];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [target performSelector:action];
#pragma clang diagnostic pop
        }
    }
    if (_uuid != nil) {
        return;
    }

    _uuid = [[NSUUID UUID] UUIDString];
    [_client POST:@"customers"
       parameters:@{@"name" : _uuid,
                    @"description" : _uuid,
                    @"preferred_locales" : @[[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]]}
          headers:[self secretKeyHeaders]
          success:^(NSDictionary *jsonResponse) {
        self->_customerID = jsonResponse[@"id"];
        [defaults setObject:self->_customerID forKey:kVLCDonationAnonymousCustomerID];
        APLog(@"Created customer");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [target performSelector:action];
#pragma clang diagnostic pop
    }
          failure:^(NSError *error) {
        APLog(@"Error creating customer: %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

- (NSString *)customerName
{
    return _uuid;
}

- (void)requestInvoices
{
    [_client GET:@"invoices"
      parameters:@{@"customer" : _customerID}
         headers:[self secretKeyHeaders]
         success:^(NSDictionary *jsonResponse) {
        NSArray *data = jsonResponse[@"data"];
        NSUInteger dataCount = data.count;
        APLog(@"Found %li invoices", dataCount);
        NSMutableArray *invoices = [NSMutableArray arrayWithCapacity:dataCount];
        for (NSDictionary *dict in data) {
            VLCInvoice *invoice = [[VLCInvoice alloc] initWithDictionary:dict];
            [invoices addObject:invoice];
        }
        if ([self.delegate respondsToSelector:@selector(setInvoices:)]) {
            [self.delegate setInvoices:invoices];
        }
    } failure:^(NSError *error){
        APLog(@"%s: %@", __func__, error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

- (void)requestCharges
{
    [_client GET:@"charges"
      parameters:@{@"customer" : _customerID}
         headers:[self secretKeyHeaders]
         success:^(NSDictionary *jsonResponse) {
        NSArray *data = jsonResponse[@"data"];
        NSUInteger dataCount = data.count;
        APLog(@"Found %li charges", dataCount);
        NSMutableArray *charges = [NSMutableArray arrayWithCapacity:dataCount];
        for (NSDictionary *dict in data) {
            VLCCharge *charge = [[VLCCharge alloc] initWithDictionary:dict];
            if (charge.receiptNumber != nil) {
                [charges addObject:charge];
            }
        }
        if ([self.delegate respondsToSelector:@selector(setCharges:)]) {
            [self.delegate setCharges:charges];
        }
    } failure:^(NSError *error){
        APLog(@"%s: %@", __func__, error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

- (void)donationSuccessful
{
    NSInteger currentMonth = [NSCalendar.currentCalendar component:NSCalendarUnitMonth fromDate:[NSDate date]];
    NSInteger nextReminderMonth;
    if (currentMonth >= 10) {
        nextReminderMonth = 2;
    } else {
        nextReminderMonth = currentMonth + 3;
    }

    [[NSUserDefaults standardUserDefaults] setInteger:nextReminderMonth forKey:kVLCHasNaggedThisMonth];
}

- (void)activeSubscription:(BOOL)bValue
{
    [[NSUserDefaults standardUserDefaults] setBool:bValue forKey:kVLCHasActiveSubscription];
}

@end
