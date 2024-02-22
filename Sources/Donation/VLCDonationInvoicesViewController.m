/*****************************************************************************
 * VLCDonationPreviousChargesViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDonationInvoicesViewController.h"
#import "VLCStripeController.h"
#import "VLCNetworkListCell.h"
#import "VLCInvoice.h"
#import "VLCCharge.h"
#import "VLCCurrency.h"
#import "VLC-Swift.h"

NSString * const VLCDonationInvoicesViewControllerReuseIdentifier = @"VLCDonationInvoicesViewControllerReuseIdentifier";

@interface VLCInsetLabel : UILabel
@end

@implementation VLCInsetLabel

- (void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:CGRectInset(rect, 20., 20.)];
}

@end

@interface VLCDonationInvoicesViewController () <VLCStripeControllerDelegate>
{
    NSArray <VLCInvoice *>*_invoices;
    NSArray <VLCCharge *>*_charges;
    VLCStripeController *_stripeController;
    UIActivityIndicatorView *_activityIndicator;
    ColorPalette *_colors;
    UILabel *_explainationLabel;
}
@end

@implementation VLCDonationInvoicesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _invoices = [NSMutableArray array];

    _colors = PresentationTheme.current.colors;

    self.tableView.backgroundColor = _colors.background;

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.color = _colors.orangeUI;
    _activityIndicator.hidesWhenStopped = YES;
    [self.tableView addSubview:_activityIndicator];
    [_activityIndicator startAnimating];

    _explainationLabel = [[VLCInsetLabel alloc] init];
    _explainationLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    _explainationLabel.textColor = _colors.cellDetailTextColor;
    _explainationLabel.numberOfLines = 0;
    _explainationLabel.textAlignment = NSTextAlignmentCenter;

    self.tableView.tableFooterView = _explainationLabel;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    CGRect frame = self.tableView.tableFooterView.frame;
    frame.size.width = self.tableView.bounds.size.width;
    frame.size.height = [VLCNetworkListCell heightOfCell] * 3.;
    self.tableView.tableFooterView.frame = frame;
}

- (void)viewWillAppear:(BOOL)animated
{
    _stripeController = [[VLCAppCoordinator sharedInstance] stripeController];
    _stripeController.delegate = self;
    [_stripeController requestCharges];
    [_stripeController requestInvoices];

    [super viewWillAppear:animated];
    _explainationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"DONATION_CHARGES_CLEARED_ON_REINSTALL", nil), _stripeController.customerName];
    _activityIndicator.center = self.tableView.center;
}

- (NSString *)title
{
    return NSLocalizedString(@"DONATION_INVOICES_RECEIPTS", nil);
}

- (void)setInvoices:(NSArray <VLCInvoice *>*)invoices
{
    _invoices = invoices;
    [self.tableView reloadData];
    [_activityIndicator stopAnimating];
}

- (void)setCharges:(NSArray<VLCCharge *> *)charges
{
    _charges = charges;
    [self.tableView reloadData];
    [_activityIndicator stopAnimating];
}

- (void)stripeProcessingFailedWithError:(nonnull NSString *)errorMessage {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DONATION_APPLE_PAY_NOT_POSSIBLE", nil)
                                                                             message:NSLocalizedString(@"DONATION_APPLE_PAY_NOT_POSSIBLE_LONG", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"DONATION_CONTINUE", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    alertController.popoverPresentationController.sourceView = self.tableView;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)stripeProcessingSucceeded {
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"DONATION_INVOICES", nil);
    }
    return NSLocalizedString(@"DONATION_RECEIPTS", nil);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return _invoices.count;
    } else {
        return _charges.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:VLCDonationInvoicesViewControllerReuseIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:VLCDonationInvoicesViewControllerReuseIdentifier];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;

    if (indexPath.section == 0) {
        VLCInvoice *invoice = _invoices[indexPath.row];
        formatter.currencySymbol = invoice.currency.localCurrencySymbol;
        if (invoice.invoiceNumber.length > 0) {
            cell.titleLabel.text = [NSString stringWithFormat:@"%@: %@", invoice.invoiceNumber, [formatter stringFromNumber:invoice.amount]];
        } else {
            cell.titleLabel.text = [formatter stringFromNumber:invoice.amount];
        }
        cell.subtitleLabel.text = [NSDateFormatter localizedStringFromDate:invoice.creationDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
        cell.isDownloadable = invoice.hostedInvoiceURL != nil;
    } else {
        VLCCharge *charge = _charges[indexPath.row];
        formatter.currencySymbol = charge.currency.localCurrencySymbol;
        if (charge.receiptNumber.length > 0) {
            cell.titleLabel.text = [NSString stringWithFormat:@"%@: %@", charge.receiptNumber, [formatter stringFromNumber:charge.amount]];
        } else {
            cell.titleLabel.text = [formatter stringFromNumber:charge.amount];
        }
        cell.subtitleLabel.text = [NSDateFormatter localizedStringFromDate:charge.creationDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
        cell.isDownloadable = charge.receiptURL != nil;
    }

    cell.folderTitleLabel.text = @"";
    cell.thumbnailImage = [UIImage imageNamed:@"Lunettes"];

    cell.titleLabel.textColor = _colors.cellTextColor;
    cell.subtitleLabel.textColor = _colors.cellDetailTextColor;
    cell.downloadButton.userInteractionEnabled = NO;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0) {
        VLCInvoice *invoice = _invoices[indexPath.row];
        [[UIApplication sharedApplication] openURL:invoice.hostedInvoiceURL];
    } else {
        VLCCharge *charge = _charges[indexPath.row];
        [[UIApplication sharedApplication] openURL:charge.receiptURL];
    }
}

@end
