/*****************************************************************************
 * VLCStripeController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

@class PKPayment;
@class VLCCurrency;
@class VLCPrice;
@class VLCInvoice;
@class VLCCharge;
@class VLCSubscription;

NS_ASSUME_NONNULL_BEGIN

@protocol VLCStripeControllerDelegate <NSObject>

@required
- (void)stripeProcessingSucceeded;
- (void)stripeProcessingFailedWithError:(NSString *)errorMessage;

@optional
- (void)show3DS:(NSURL *)redirectURL withCallbackURL:(NSURL *)callbackURL;
- (void)setInvoices:(NSArray <VLCInvoice *>*)invoices;
- (void)setCharges:(NSArray <VLCCharge *>*)charges;
- (void)setCurrentSubscription:(nullable VLCSubscription *)subscription;
- (void)setRecurringPriceList:(NSArray <VLCPrice *>*)priceList;

@end

@interface VLCStripeController : NSObject

@property (readwrite, weak) id<VLCStripeControllerDelegate> delegate;
@property (readonly) NSString *customerName;

@property (readonly) BOOL currentLocaleIsEmbargoed;

- (void)processPayment:(PKPayment *)payment
             forAmount:(NSNumber *)amount
                 price:(VLCPrice *)price
              currency:(VLCCurrency *)currencyCode
             recurring:(BOOL)recurring;

- (void)processPaymentWithCard:(NSString *)cardNumber
                           cvv:(NSString *)cvv
                     exprMonth:(NSString *)month
                      exprYear:(NSString *)year
                     forAmount:(NSNumber *)amount
                         price:(VLCPrice *)price
                      currency:(VLCCurrency *)currency
                     recurring:(BOOL)recurring;

- (void)processPaymentWithSEPAAccount:(NSString *)accountNumber
                                 name:(NSString *)name
                                email:(NSString *)email
                            forAmount:(NSNumber *)amount
                                price:(VLCPrice *)price
                             currency:(VLCCurrency *)currency
                            recurring:(BOOL)recurring;

- (void)continueWithPaymentIntent:(NSString *)paymentIntent;
- (void)continueWithSetupIntent:(NSString *)setupIntent;

- (void)requestInvoices;
- (void)requestCharges;
- (void)requestAvailablePricesInCurrency:(VLCCurrency *)currency;
- (void)requestCurrentCustomerSubscription;

- (void)updateSubscription:(VLCSubscription *)sub toPrice:(VLCPrice *)price;
- (void)cancelSubscription:(VLCSubscription *)sub;

- (void)handleCustomerToContinueWithTarget:(id)target selector:(SEL)action;

@end

NS_ASSUME_NONNULL_END
