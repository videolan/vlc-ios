/*****************************************************************************
* VLCStoreController.m
* VLC for iOS
*****************************************************************************
* Copyright (c) 2020 VideoLAN. All rights reserved.
* $Id$
*
* Authors: Felix Paul Kühne <fkuehne # videolan.org>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

#import "VLCStoreController.h"
#import <StoreKit/StoreKit.h>

NSString *VLCStoreControllerAvailableProductsUpdated = @"VLCStoreControllerAvailableProductsUpdated";
NSString *VLCStoreControllerPurchasedProductsRestored = @"VLCStoreControllerPurchasedProductsRestored";
NSString *VLCStoreControllerTipReceived = @"VLCStoreControllerTipReceived";
NSString *VLCStoreControllerInteractionFailed = @"VLCStoreControllerInteractionFailed";

@interface VLCStoreController() <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    NSArray *_productIdentifiers;
    SKProductsRequest *_productRequest;
    SKPaymentQueue *_paymentQueue;
}
@end

@implementation VLCStoreController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _productIdentifiers = @[@"org.videolan.vlc.huge_tip",
                                @"org.videolan.vlc.large_tip",
                                @"org.videolan.vlc.medium_tip",
                                @"org.videolan.vlc.small_tip",
                                @"org.videolan.vlc.micro_tip"];
        _paymentQueue = [SKPaymentQueue defaultQueue];
        [_paymentQueue addTransactionObserver:self];
    }
    return self;
}

- (BOOL)canMakePayments
{
    return [SKPaymentQueue canMakePayments];
}

- (void)validateAvailableProducts
{
    [self validateProductIdentifiers:_productIdentifiers];
}

- (void)validateProductIdentifiers:(NSArray *)productIdentifiers
{
    APLog(@"%s", __func__);
    _productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:_productIdentifiers]];

    _productRequest.delegate = self;
    [_productRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    _availableProducts = response.products;

    for (NSString *invalidIdentifier in response.invalidProductIdentifiers) {
        APLog(@"%s: found invalid identifier: '%@'", __func__, invalidIdentifier);
    }

    APLog(@"%s: %lu verified products", __func__, _availableProducts.count);
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCStoreControllerAvailableProductsUpdated object:self];
}

- (void)restorePurchasedProducts
{
    [_paymentQueue restoreCompletedTransactions];
}

#pragma mark - payment processing

- (void)purchaseProduct:(SKProduct *)product
{
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [_paymentQueue addPayment:payment];
}

// Sent when the transaction array has changed (additions or state changes).  Client should check state of transactions and finish as appropriate.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions;
{
    NSString *state;
    NSUInteger transactionCount = transactions.count;
    APLog(@"%s: %lu transactions", __func__, transactionCount);
    for (NSUInteger x = 0 ; x < transactionCount; x++) {
        SKPaymentTransaction *transaction = transactions[x];

        switch(transaction.transactionState){
            case SKPaymentTransactionStatePurchasing:
                state = @"purchasing";
                break;
            case SKPaymentTransactionStatePurchased:
                state = @"purchased";
                [self tipReceived];
                [_paymentQueue finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                state = @"restored";
                [self purchasesRestored];
                [_paymentQueue finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                state = [NSString stringWithFormat:@"failed (%@, %li)", transaction.error.localizedDescription, transaction.error.code];
                [self storeInteractionFailedWithError:transaction.error];
                [_paymentQueue finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
                state = @"deferred";
                // FIXME: handle state correctly as "Ask to Buy."
                break;
        }
        APLog(@"%s: state: %@", __func__, state);
    }
}

// Sent when an error is encountered while adding transactions from the user's purchase history back to the queue.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error;
{
    APLog(@"%s: %@", __func__, error);
}

// Sent when all transactions from the user's purchase history have successfully been added back to the queue.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue;
{
    NSArray *transactions = queue.transactions;
    NSUInteger transactionCount = transactions.count;
    APLog(@"%s: %lu transactions", __func__, transactionCount);
    for (NSUInteger x = 0 ; x < transactionCount; x++) {
        SKPaymentTransaction *transaction = transactions[x];
        if (transaction.transactionState == SKPaymentTransactionStateRestored) {
            NSString *productID = transaction.payment.productIdentifier;
            APLog(@"%s: restored '%@'", __func__, productID);
            [self purchasesRestored];
            [_paymentQueue finishTransaction:transaction];
            break;
        }
    }
}

// Sent when a user initiates an IAP buy from the App Store
- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product;
{
    // FIXME: is this a good answer?
    return YES;
}

- (void)tipReceived
{
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCStoreControllerTipReceived object:self];
}

- (void)purchasesRestored
{
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCStoreControllerPurchasedProductsRestored object:self];
}

- (void)storeInteractionFailedWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCStoreControllerInteractionFailed
                                                        object:self
                                                      userInfo:@{ VLCStoreControllerInteractionFailed : error }];
}

@end
