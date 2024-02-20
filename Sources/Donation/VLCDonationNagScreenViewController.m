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
#import "VLC-Swift.h"

@implementation VLCDonationNagScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    ColorPalette *colors = PresentationTheme.current.colors;

    self.buttonSeparatorView.backgroundColor = colors.orangeUI;

    self.coloredBackgroundView.layer.backgroundColor = colors.background.CGColor;
    self.coloredBackgroundView.layer.cornerRadius = 10.;
    self.coloredBackgroundView.layer.borderWidth = 1.5;
    self.coloredBackgroundView.layer.borderColor = colors.orangeDarkAccent.CGColor;
    self.coloredBackgroundView.layer.shadowColor = colors.textfieldBorderColor.CGColor;
    self.coloredBackgroundView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.coloredBackgroundView.bounds cornerRadius:10.].CGPath;
    self.coloredBackgroundView.layer.shadowRadius = 8;
    self.coloredBackgroundView.layer.shadowOffset = CGSizeMake(0.,0.);
    self.coloredBackgroundView.layer.masksToBounds = NO;
    self.coloredBackgroundView.layer.shadowOpacity = .25;

    self.titleLabel.text = NSLocalizedString(@"DONATION_NAGSCREEN_TITLE", nil);
    self.descriptionLabel.text = NSLocalizedString(@"DONATION_NAGSCREEN_SUBTITLE", nil);
    self.descriptionLabel.textColor = [UIColor lightGrayColor];

    NSDictionary *attributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:18.],
        NSForegroundColorAttributeName: colors.orangeUI
    };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"BUTTON_NOT_NOW", nil) attributes:attributes];
    [self.notnowButton setAttributedTitle:attributedString forState:UIControlStateNormal];

    attributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:18.],
        NSForegroundColorAttributeName: colors.orangeUI
    };
    attributedString = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"DONATION_DONATE_BUTTON", nil) attributes:attributes];
    [self.donateButton setAttributedTitle:attributedString forState:UIControlStateNormal];

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
        donationNC.popoverPresentationController.sourceView = [[[VLCAppCoordinator sharedInstance] tabBarController] tabBar];
        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:donationNC animated:YES completion:nil];
    }];
}

@end
