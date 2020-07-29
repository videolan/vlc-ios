/*****************************************************************************
* VLCStoreViewController.m
* VLC for iOS
*****************************************************************************
* Copyright (c) 2020 VideoLAN. All rights reserved.
* $Id$
*
* Authors: Felix Paul Kühne <fkuehne # videolan.org>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

#import "VLCStoreViewController.h"
#import "VLCStoreController.h"
#import "VLCStoreCollectionViewCell.h"
#import "VLC-Swift.h"

#import <StoreKit/StoreKit.h>

NSString *VLCStoreViewCollectionViewCellReuseIdentifier = @"VLCStoreViewCollectionViewCellReuseIdentifier";
CGFloat VLCStoreViewCollectionViewInterimSpacing = 2.;

@interface VLCStoreViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
{
    VLCStoreController *_storeController;
    NSArray *_availableProducts;
}
@end

@implementation VLCStoreViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _storeController = [[VLCStoreController alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupStoreCoordination];
    [self initStrings];

    [self.collectionView registerClass:[VLCStoreCollectionViewCell class] forCellWithReuseIdentifier:VLCStoreViewCollectionViewCellReuseIdentifier];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;

    self.performPurchaseButton.enabled = NO;

#if TARGET_OS_IOS
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", nil)
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(dismiss)];
    doneButton.accessibilityIdentifier = VLCAccessibilityIdentifier.done;
    self.navigationItem.rightBarButtonItem = doneButton;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeDidChange)
                                                 name:kVLCThemeDidChangeNotification
                                               object:nil];
    [self themeDidChange];
#endif
}

- (void)initStrings
{
    self.title = NSLocalizedString(@"GIVE_TIP", nil);
    self.tippingExplainedLabel.text = @"Short text to explain how the donation will benefit to VLC and why it is important to support VideoLAN.org";
    self.cannotMakePaymentsLabel.text = NSLocalizedString(@"CANNOT_MAKE_PAYMENTS", nil);
    [self.performPurchaseButton setTitle:NSLocalizedString(@"SEND_GIFT", nil) forState:UIControlStateNormal];
}

- (void)updateCollectionViewSizing
{
    if (!_availableProducts) {
        return;
    }
    NSInteger count = _availableProducts.count;
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    flowLayout.itemSize = CGSizeMake((self.collectionView.frame.size.width - VLCStoreViewCollectionViewInterimSpacing * count) / count, 84.);
    flowLayout.minimumInteritemSpacing = .2;
    flowLayout.minimumLineSpacing = .0;
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)themeDidChange
{
    ColorPalette *colors = PresentationTheme.current.colors;
    self.navigationItem.titleView.tintColor = colors.navigationbarTextColor;
    self.view.backgroundColor = colors.background;
    self.collectionView.backgroundColor = colors.background;
    [self.performPurchaseButton setTitleColor:colors.orangeUI forState:UIControlStateNormal];
    [self.performPurchaseButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled];
    [self.collectionView reloadData];
}

- (void)hidePurchaseUI
{
    self.collectionView.hidden = YES;
    self.performPurchaseButton.hidden = YES;
    self.emojiStackView.hidden = YES;
}

#pragma mark - store controller notifications

- (void)setupStoreCoordination
{
    [_activityIndicator startAnimating];

    if (!_storeController.canMakePayments) {
        [_activityIndicator stopAnimating];
        self.cannotMakePaymentsLabel.hidden = NO;
        [self hidePurchaseUI];
        return;
    }

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(availableProductsUpdated:)
                               name:VLCStoreControllerAvailableProductsUpdated
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(purchasedProductsRestored:)
                               name:VLCStoreControllerPurchasedProductsRestored
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(purchaseFailed:)
                               name:VLCStoreControllerInteractionFailed
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(purchaseSucceeded:)
                               name:VLCStoreControllerTipReceived
                             object:nil];

    [_storeController validateAvailableProducts];
}

- (void)availableProductsUpdated:(NSNotification *)aNotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_availableProducts = self->_storeController.availableProducts;
        self.cannotMakePaymentsLabel.hidden = YES;
        [self updateCollectionViewSizing];
        [self.collectionView reloadData];
        [self.activityIndicator stopAnimating];
    });
}

- (void)purchasedProductsRestored:(NSNotification *)aNotification
{
}

- (void)purchaseFailed:(NSNotification *)aNotification
{
    NSError *error = aNotification.userInfo[VLCStoreControllerInteractionFailed];
    if (!error) {
        APLog(@"%s: unknown error", __PRETTY_FUNCTION__);
        return;
    }

    if (error.code == 2) {
        APLog(@"%s: user cancelled purchase", __PRETTY_FUNCTION__);
        return;
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"PURCHASE_FAILED", nil)
                                                                             message:error.localizedDescription
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
    [alertController addAction:action];
    alertController.popoverPresentationController.sourceView = self.collectionView;
    alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    alertController.popoverPresentationController.sourceRect = self.collectionView.bounds;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)purchaseSucceeded:(NSNotification *)aNotification
{
    APLog(@"%s", __func__);

    [self hidePurchaseUI];

    self.title = @"Thank you!";
    self.tippingExplainedLabel.text = @"Thank you for blablablabla, short text to reassure the user on how his money will be used";
    [self.confettiView startConfetti];
}

#pragma mark - collection view data source

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCStoreCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:VLCStoreViewCollectionViewCellReuseIdentifier
                                                                                 forIndexPath:indexPath];

    SKProduct *product = _availableProducts[indexPath.row];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    [cell setPrice:[numberFormatter stringFromNumber:product.price]];

    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    if (_availableProducts) {
        return _availableProducts.count;
    }
    return 0;
}

#pragma mark - collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.performPurchaseButton.enabled = YES;
}

#pragma mark - purchase button

- (void)performPurchase:(id)sender
{
    NSInteger selectedIndex = self.collectionView.indexPathsForSelectedItems.firstObject.row;
    SKProduct *selectedProduct = _availableProducts[selectedIndex];
    APLog(@"User wants to purchase product '%@'", [selectedProduct localizedTitle]);
    [_storeController purchaseProduct:selectedProduct];
}

@end
