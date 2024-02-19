/*****************************************************************************
 * VLCDonationNagScreenViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDonationNagScreenViewController.h"
#import "VLCDonationViewController.h"

@implementation VLCDonationNagScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.coloredBackgroundView.layer.cornerRadius = 10.;
    self.coloredBackgroundView.layer.borderWidth = 2.;
    self.coloredBackgroundView.layer.borderColor = [UIColor VLCOrangeTintColor].CGColor;

    self.titleLabel.text = NSLocalizedString(@"DONATION_NAGSCREEN_TITLE", nil);
    self.descriptionLabel.text = NSLocalizedString(@"DONATION_NAGSCREEN_SUBTITLE", nil);
    [self.notnowButton setTitle:NSLocalizedString(@"BUTTON_NOT_NOW", nil) forState:UIControlStateNormal];
    [self.donateButton setTitle:NSLocalizedString(@"DONATION_DONATE_BUTTON", nil) forState:UIControlStateNormal];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
    [self.view addGestureRecognizer:tapRecognizer];
}

- (IBAction)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)donate:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        UIViewController *donationVC = [[VLCDonationViewController alloc] initWithNibName:@"VLCDonationViewController" bundle:nil];
        UINavigationController *donationNC = [[UINavigationController alloc] initWithRootViewController:donationVC];
        donationNC.modalPresentationStyle = UIModalPresentationPopover;
        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:donationNC animated:YES completion:nil];
    }];
}

@end
