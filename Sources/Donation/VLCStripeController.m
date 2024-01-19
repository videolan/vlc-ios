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

const NSString *publishableStripeAPIKey = @"";
const NSString *secretStripeAPIKey = @"";

@interface VLCStripeController()
{
    NSString *_currencyCode;
    NSString *_amount;
}
@end

@implementation VLCStripeController

#pragma mark - apple pay internals

- (void)processPayment:(PKPayment *)payment forAmount:(CGFloat)amount currency:(NSString *)currencyCode
{
    _currencyCode = currencyCode;
    _amount = [[NSNumber numberWithInteger:(NSInteger)amount * 100] stringValue];
    [self createStripeTokenWithPayment:payment];
}

- (void)createStripeTokenWithPayment:(PKPayment *)payment {
    // Construct the request URL and headers
    NSString *urlString = @"https://api.stripe.com/v1/tokens";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", publishableStripeAPIKey] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    // Construct the request body
    NSDictionary *parameters = [self constructParametersForPayment:payment];
    NSString *bodyString = AFQueryStringFromParameters(parameters);
    // = [NSString stringWithFormat:@"card[number]=%@&card[exp_month]=%@&card[exp_year]=%@&card[cvc]=%@", payment.token.paymentMethod.card.number, payment.token.paymentMethod.card.expMonth, payment.token.paymentMethod.card.expYear, @"123"];
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:bodyData];

    // Perform the request
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            // Handle error
            APLog(@"Error creating Stripe token: %@", error.localizedDescription);
            [self.delegate stripeProcessingCompleted:NO];
        } else {
            // Handle success
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSString *stripeToken = jsonResponse[@"id"];
            if (stripeToken) {
                APLog(@"Stripe token created successfully");
                [self processPaymentWithStripe:stripeToken];
            } else {
                APLog(@"Error creating Stripe token: %@", jsonResponse);
                [self.delegate stripeProcessingCompleted:NO];
            }
        }
    }] resume];
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

- (void)processPaymentWithCard:(NSString *)cardNumber cvv:(NSString *)cvv exprMonth:(NSString *)month exprYear:(NSString *)year forAmount:(CGFloat)amount currency:(NSString *)currencyCode
{
    [self.delegate stripeProcessingCompleted:YES];
}

#pragma mark - generic API

- (void)processPaymentWithStripe:(NSString *)stripeToken {
    // Construct the request URL and headers
    NSString *urlString = @"https://api.stripe.com/v1/charges";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", secretStripeAPIKey] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    // Construct the request body
    NSString *bodyString = [NSString stringWithFormat:@"amount=%@&currency=%@&source=%@", _amount, _currencyCode, stripeToken];
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:bodyData];

    // Perform the request
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            // Handle error
            APLog(@"Error processing payment: %@", error.localizedDescription);
            [self.delegate stripeProcessingCompleted:NO];
        } else {
            // Handle success
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            BOOL success = [jsonResponse[@"paid"] boolValue];
            if (success) {
                APLog(@"Payment successfully processed");
            } else {
                APLog(@"Receive negative response from Stripe: %@", jsonResponse);
            }
            [self.delegate stripeProcessingCompleted:success];
        }
    }] resume];
}

@end
