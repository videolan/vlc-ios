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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleLabel.text = NSLocalizedString(@"DONATION_BANK_TRANSFER", nil);
    self.descriptionLabel.text = NSLocalizedString(@"DONATION_BANK_TRANSFER_LONG", nil);
    self.authorizationTextLabel.text = [VLCSEPA authorizationTextForCurrentLocale];

    [self.continueButton setTitle:NSLocalizedString(@"DONATION_BUTTON_AGREE", nil) forState:UIControlStateNormal];
    self.continueButton.backgroundColor = PresentationTheme.current.colors.orangeUI;
    [self.continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.continueButton.layer.cornerRadius = 5.;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(refuseSepa)];
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
