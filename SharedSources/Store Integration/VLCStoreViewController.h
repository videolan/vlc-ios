/*****************************************************************************
* VLCStoreViewController.h
* VLC for iOS
*****************************************************************************
* Copyright (c) 2020 VideoLAN. All rights reserved.
* $Id$
*
* Authors: Felix Paul Kühne <fkuehne # videolan.org>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCConfettiView;

@interface VLCStoreViewController : UIViewController

@property (retain) IBOutlet UILabel *tippingExplainedLabel;
@property (retain) IBOutlet UICollectionView *collectionView;
@property (retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (retain) IBOutlet UILabel *cannotMakePaymentsLabel;
@property (retain) IBOutlet UIStackView *emojiStackView;
@property (retain) IBOutlet UIButton *performPurchaseButton;
@property (retain) IBOutlet VLCConfettiView *confettiView;

- (IBAction)performPurchase:(id)sender;

@end

NS_ASSUME_NONNULL_END
