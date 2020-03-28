/*****************************************************************************
* VLCStoreController.h
* VLC for iOS
*****************************************************************************
* Copyright (c) 2020 VideoLAN. All rights reserved.
* $Id$
*
* Authors: Felix Paul Kühne <fkuehne # videolan.org>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *VLCStoreControllerAvailableProductsUpdated;
extern NSString *VLCStoreControllerPurchasedProductsRestored;
extern NSString *VLCStoreControllerTipReceived;
extern NSString *VLCStoreControllerInteractionFailed;

@class SKProduct;

@interface VLCStoreController : NSObject

@property (readonly, nullable, copy) NSArray *availableProducts;
@property (readonly) BOOL canMakePayments;

- (void)validateAvailableProducts;
- (void)restorePurchasedProducts;
- (void)purchaseProduct:(SKProduct *)product;

@end

NS_ASSUME_NONNULL_END
