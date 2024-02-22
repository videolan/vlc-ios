/*****************************************************************************
 * VLCDonationViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023-2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCConfettiView;
@class VLCPrice;
@class VLCSubscription;

@interface VLCDonationViewController : UIViewController

@property (readwrite, nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *selectedCurrencyButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *fiveButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *tenButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *twentyButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *thirtyButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *fiftyButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *hundredButton;
@property (readwrite, nonatomic, weak) IBOutlet UITextField *customAmountField;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *continueButton;
@property (readwrite, nonatomic, weak) IBOutlet UIScrollView *contentScrollView;
@property (readwrite, nonatomic, weak) IBOutlet VLCConfettiView *confettiView;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *previousDonationsButton;
@property (readwrite, nonatomic, weak) IBOutlet UIView *oneTimePaymentView;
@property (readwrite, nonatomic, weak) IBOutlet UIView *monthlyPaymentView;
@property (readwrite, nonatomic, weak) IBOutlet UISegmentedControl *intervalSelectorControl;

@property (readwrite, nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@property (readwrite, nonatomic, weak) IBOutlet UIButton *monthlyFirstOptionButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *monthlySecondOptionButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *monthlyThirdOptionButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *monthlyUpdateButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *monthlyCancelButton;

- (IBAction)switchCurrency:(id)sender;
- (IBAction)numberButtonAction:(id)sender;
- (IBAction)continueButtonAction:(id)sender;
- (IBAction)customAmountFieldAction:(id)sender;
- (IBAction)showPreviousCharges:(id)sender;

- (IBAction)segmentedControlAction:(id)sender;

- (IBAction)monthlyOptionAction:(id)sender;
- (IBAction)monthlyUpdateAction:(id)sender;
- (IBAction)monthlyCancelAction:(id)sender;

- (void)setRecurringPriceList:(NSArray <VLCPrice *> *)priceList;
- (void)setCurrentSubscription:(nullable VLCSubscription *)plan;

@end

NS_ASSUME_NONNULL_END
