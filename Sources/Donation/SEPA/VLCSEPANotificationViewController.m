/*****************************************************************************
 * VLCSEPANotificationViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSEPANotificationViewController.h"
#import "VLCSEPA.h"
#import "VLCDonationSEPAViewController.h"
#import "VLC-Swift.h"

@implementation VLCSEPANotificationViewController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleLabel.text = NSLocalizedString(@"DONATION_BANK_TRANSFER", nil);
    self.descriptionLabel.text = NSLocalizedString(@"DONATION_BANK_TRANSFER_LONG", nil);
    self.authorizationTextLabel.text = [VLCSEPA authorizationTextForCurrentLocale];

    ColorPalette *colors = PresentationTheme.current.colors;
    [self.continueButton setTitle:NSLocalizedString(@"DONATION_BUTTON_AGREE", nil) forState:UIControlStateNormal];
    self.continueButton.backgroundColor = colors.orangeUI;
    [self.continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.continueButton.layer.cornerRadius = 5.;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(refuseSepa)];

    self.view.backgroundColor = colors.background;
    self.titleLabel.textColor = colors.cellTextColor;
    self.descriptionLabel.textColor = colors.cellTextColor;
    self.authorizationTextLabel.textColor = colors.cellTextColor;

    if (colors.isDark) {
        _iconView.image = [UIImage imageNamed:@"VLCCone26-dark-512x512"];
    } else {
        _iconView.image = [UIImage imageNamed:@"VLCCone26-512x512"];
    }
}

- (void)refuseSepa
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (NSString *)title
{
    return NSLocalizedString(@"DONATION_BANK_TRANSFER", nil);
}

- (IBAction)continueButtonAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
