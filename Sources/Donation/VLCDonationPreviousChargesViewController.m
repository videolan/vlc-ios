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

#import "VLCDonationPreviousChargesViewController.h"
#import "VLCStripeController.h"
#import "VLCNetworkListCell.h"
#import "VLCCharge.h"
#import "VLC-Swift.h"

NSString * const VLCDonationPreviousChargesViewControllerReuseIdentifier = @"VLCDonationPreviousChargesViewControllerReuseIdentifier";

@interface VLCInsetLabel : UILabel
@end

@implementation VLCInsetLabel

- (void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:CGRectInset(rect, 20., 20.)];
}

@end

@interface VLCDonationPreviousChargesViewController ()
{
    NSMutableArray <VLCCharge *>*_charges;
    VLCStripeController *_stripeController;
    UIActivityIndicatorView *_activityIndicator;
    ColorPalette *_colors;
    UILabel *_explainationLabel;
}
@end

@implementation VLCDonationPreviousChargesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _charges = [NSMutableArray array];

    _colors = PresentationTheme.current.colors;

    self.tableView.backgroundColor = _colors.background;

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.color = _colors.orangeUI;
    _activityIndicator.hidesWhenStopped = YES;
    [self.tableView addSubview:_activityIndicator];
    [_activityIndicator startAnimating];

    _stripeController = [[VLCStripeController alloc] init];
    [_stripeController requestChargesForViewController:self];

    _explainationLabel = [[VLCInsetLabel alloc] init];
    _explainationLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    _explainationLabel.textColor = _colors.cellDetailTextColor;
    _explainationLabel.text = NSLocalizedString(@"DONATION_CHARGES_CLEARED_ON_REINSTALL", nil);
    _explainationLabel.numberOfLines = 0;
    _explainationLabel.textAlignment = NSTextAlignmentCenter;

    self.tableView.tableFooterView = _explainationLabel;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    CGRect frame = self.tableView.tableFooterView.frame;
    frame.size.width = self.tableView.bounds.size.width;
    frame.size.height = [VLCNetworkListCell heightOfCell] * 1.5;
    self.tableView.tableFooterView.frame = frame;
}

- (NSString *)title
{
    return NSLocalizedString(@"DONATIONS_PREVIOUS", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _activityIndicator.center = self.tableView.center;
}

- (void)addPreviousCharge:(VLCCharge *)charge
{
    [_charges addObject:charge];
    [self.tableView reloadData];
    [_activityIndicator stopAnimating];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _charges.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:VLCDonationPreviousChargesViewControllerReuseIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:VLCDonationPreviousChargesViewControllerReuseIdentifier];

    VLCCharge *charge = _charges[indexPath.row];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.currencyCode = charge.currencyCode;
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    cell.titleLabel.text = [formatter stringFromNumber:charge.amount];

    cell.subtitleLabel.text = [NSDateFormatter localizedStringFromDate:charge.creationDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    cell.folderTitleLabel.text = @"";
    cell.thumbnailImage = [UIImage imageNamed:@"Lunettes"];

    cell.titleLabel.textColor = _colors.cellTextColor;
    cell.subtitleLabel.textColor = _colors.cellDetailTextColor;
    cell.isDownloadable = YES;
    cell.downloadButton.userInteractionEnabled = NO;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    VLCCharge *charge = _charges[indexPath.row];
    [[UIApplication sharedApplication] openURL:charge.receiptURL];
}

@end
