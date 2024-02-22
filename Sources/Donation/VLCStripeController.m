/*****************************************************************************
 * VLCStripeController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCStripeController.h"
#import <PassKit/PassKit.h>
#import <AFNetworking/AFNetworking.h>
#import "VLCCurrency.h"
#import "VLCCharge.h"
#import "VLCDonationPreviousChargesViewController.h"

const NSString *publishableStripeAPIKey = @"";
const NSString *secretStripeAPIKey = @"";
NSString *callbackURLString = @"vlcpay://3ds";

@interface VLCStripeController()
{
    VLCCurrency *_currency;
    NSString *_amount;
    BOOL _recurring;

    NSDictionary *_card;
    NSString *_tokenID;

    AFHTTPSessionManager *_sessionManager;
}
@end

@implementation VLCStripeController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.stripe.com/v1/"]];
    }
    return self;
}

- (void)dealloc
{
    [_sessionManager invalidateSessionCancelingTasks:YES resetSession:YES];
}

#pragma mark - apple pay internals

- (void)processPayment:(PKPayment *)payment
             forAmount:(NSNumber *)amount
              currency:(VLCCurrency *)currency
             recurring:(BOOL)recurring
{
    _currency = currency;
    _amount = [[NSNumber numberWithInt:amount.intValue * 100] stringValue];
    _recurring = recurring;

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
                      currency:(VLCCurrency *)currency
                     recurring:(BOOL)recurring
{
    _currency = currency;
    _amount = [[NSNumber numberWithInt:amount.intValue * 100] stringValue];
    _recurring = recurring;

    NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
    mutDict[@"card[number]"] = cardNumber;
    mutDict[@"card[exp_month]"] = month;
    mutDict[@"card[exp_year]"] = year;
    mutDict[@"card[cvc]"] = cvv;

    [self createStripeTokenWithParameters:[mutDict copy]];
}

#pragma mark - generic API

- (NSDictionary *)publishableKeyHeaders
{
    return @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", publishableStripeAPIKey],
              @"Content-Type" : @"application/x-www-form-urlencoded" };
}

- (NSDictionary *)secretKeyHeaders
{
    return @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", secretStripeAPIKey],
              @"Content-Type" : @"application/x-www-form-urlencoded" };
}

- (void)createStripeTokenWithParameters:(NSDictionary *)parameters
{
    [_sessionManager POST:@"tokens"
               parameters:parameters
                  headers:[self publishableKeyHeaders]
                 progress:nil
                  success:^(NSURLSessionTask *task, NSDictionary *jsonResponse) {
        self->_tokenID = jsonResponse[@"id"];
        if (self->_tokenID) {
            APLog(@"Stripe token created successfully");
            self->_card = jsonResponse[@"card"];
            // a CVC check is not needed
            if (self->_card[@"cvc_check"] == nil) {
                APLog(@"No CVC check needed, continuing with the charge");
                [self processPayment];
            } else {
                APLog(@"CVC check needed, requesting payment intent confirmation");
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
                  failure:^(NSURLSessionTask *task, NSError *error) {
        APLog(@"Error creating Stripe token: %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];

}

- (void)processPayment {
    [_sessionManager POST:@"charges"
               parameters:@{@"amount" : _amount,
                            @"currency" : _currency.isoCode,
                            @"source" : _tokenID}
                  headers:[self secretKeyHeaders]
                 progress:nil
                  success:^(NSURLSessionTask *task, NSDictionary *jsonResponse) {
        NSString *receipt = jsonResponse[@"receipt_url"];
        NSString *chargeID = jsonResponse[@"id"];
        if ([jsonResponse[@"paid"] boolValue]) {
            APLog(@"Direct charge successfully processed");
            [self rememberCharge:chargeID];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate stripeProcessingSucceededWithReceipt:receipt];
            });
        } else {
            NSDictionary *errorDict = jsonResponse[@"error"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate stripeProcessingFailedWithError:errorDict ? errorDict[@"message"] : @"unknown"];
            });
            APLog(@"Error processing direct charge: %@", jsonResponse);
        }
    }
                  failure:^(NSURLSessionTask *task, NSError *error) {
        APLog(@"Error processing direct charge: %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

- (void)confirmPaymentIntent
{
    [_sessionManager POST:@"payment_intents"
               parameters:@{@"confirm" : @"true",
                            @"amount" : _amount,
                            @"currency" : _currency.isoCode,
                            @"payment_method_data" : @{ @"type" : @"card", @"card[token]" : _tokenID },
                            @"return_url" : callbackURLString}
                  headers:[self secretKeyHeaders]
                 progress:nil
                  success:^(NSURLSessionTask *task, NSDictionary *jsonResponse) {
        NSDictionary *nextAction = jsonResponse[@"next_action"];
        int amountReceived = [jsonResponse[@"amount_received"] intValue];
        NSString *chargeID = jsonResponse[@"latest_charge"];

        if (nextAction == (NSDictionary*) [NSNull null]) {
            APLog(@"Payment intent was approved, no further action needed");
            if (amountReceived > 0) {
                [self rememberCharge:chargeID];
                [self forwardReceiptForCharge:chargeID];
                return;
            }
        } else {
            APLog(@"Received a next action on payment intent confirmation");
            NSDictionary *redirectToURL = nextAction[@"redirect_to_url"];
            NSString *url = redirectToURL[@"url"];
            NSURL *redirectURL = [NSURL URLWithString:url];
            if (redirectURL != nil) {
                if ([self.delegate respondsToSelector:@selector(show3DS:withCallbackURL:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate show3DS:(NSURL *)redirectURL withCallbackURL:[NSURL URLWithString:callbackURLString]];
                    });
                    return;
                }
            }
        }

        NSDictionary *errorDict = jsonResponse[@"error"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:errorDict ? errorDict[@"message"] : @"unknown"];
        });
        APLog(@"Payment intent confirmation failed: %@", jsonResponse);
    }
                  failure:^(NSURLSessionTask *task, NSError *error) {
        APLog(@"Payment intent confirmation failed: %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

- (void)continueWithPaymentIntent:(NSString *)paymentIntent
{
    [_sessionManager POST:[NSString stringWithFormat:@"payment_intents/%@", paymentIntent]
               parameters:nil
                  headers:[self secretKeyHeaders]
                 progress:nil
                  success:^(NSURLSessionTask *task, NSDictionary *jsonResponse) {
        int amountReceived = [jsonResponse[@"amount_received"] intValue];
        NSString *chargeID = jsonResponse[@"latest_charge"];
        if (amountReceived != 0) {
            APLog(@"Successfully confirmed payment intent after additional action");
            [self rememberCharge:chargeID];
            [self forwardReceiptForCharge:chargeID];
            return;
        }

        NSDictionary *errorDict = jsonResponse[@"error"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:errorDict ? errorDict[@"message"] : @"Card rejected"];
        });
        APLog(@"Failed to confirm payment intent after additional action: %@", jsonResponse);
    }
                  failure:^(NSURLSessionTask *task, NSError *error) {
        APLog(@"Failed to confirm payment intent after additional action: %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

#pragma mark - post-payment handling of charges

- (void)forwardReceiptForCharge:(NSString *)chargeID
{
    [_sessionManager POST:[NSString stringWithFormat:@"charges/%@", chargeID]
               parameters:nil
                  headers:[self secretKeyHeaders]
                 progress:nil
                  success:^(NSURLSessionTask *task, NSDictionary *jsonResponse) {
        NSString *receiptURLString = jsonResponse[@"receipt_url"];
        BOOL captured = [jsonResponse[@"captured"] boolValue];

        if (captured) {
            APLog(@"Received receipt, forwarding to the UI");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate stripeProcessingSucceededWithReceipt:receiptURLString];
            });
            return;
        }

        NSDictionary *errorDict = jsonResponse[@"error"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:errorDict ? errorDict[@"message"] : @"Card rejected"];
        });
        APLog(@"Failed to receive the receipt: %@", jsonResponse);
    }
                  failure:^(NSURLSessionTask *task, NSError *error) {
        APLog(@"Failed to receive the receipt: %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate stripeProcessingFailedWithError:error.localizedDescription];
        });
    }];
}

- (void)rememberCharge:(NSString *)chargeID
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *mutArray = [defaults mutableArrayValueForKey:kVLCDonationCharges];
    [mutArray addObject:chargeID];
    [defaults setObject:mutArray forKey:kVLCDonationCharges];
}

- (BOOL)previousChargesAvailable
{
    NSArray *previousCharges = [[NSUserDefaults standardUserDefaults] arrayForKey:kVLCDonationCharges];
    return previousCharges.count > 0;
}

- (void)requestChargesForViewController:(VLCDonationPreviousChargesViewController *)vc
{
    NSArray *chargeIDs = [[NSUserDefaults standardUserDefaults] arrayForKey:kVLCDonationCharges];
    for (NSString *chargeID in chargeIDs) {
        [self requestCharge:chargeID forViewController:vc];
    }
}

- (void)requestCharge:(NSString *)chargeID forViewController:(VLCDonationPreviousChargesViewController *)vc
{
    [_sessionManager POST:[NSString stringWithFormat:@"charges/%@", chargeID]
               parameters:nil
                  headers:[self secretKeyHeaders]
                 progress:nil
                  success:^(NSURLSessionTask *task, NSDictionary *jsonResponse) {
        VLCCharge *charge = [[VLCCharge alloc] initWithDictionary:jsonResponse];
        APLog(@"Received requested charge, forwarding to UI");
        dispatch_async(dispatch_get_main_queue(), ^{
            [vc addPreviousCharge:charge];
        });
    }
                  failure:^(NSURLSessionTask *task, NSError *error){
        APLog(@"Error requesting charge: %@", error.localizedDescription);
    }];
}

@end
