/*****************************************************************************
 * VLCFirstStepsSixthPageViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFirstStepsSixthPageViewController.h"

@interface VLCFirstStepsSixthPageViewController ()

@end

@implementation VLCFirstStepsSixthPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        self.flossDescriptionLabel.text = NSLocalizedString(@"FIRST_STEPS_FLOSS", @"");
    else
        self.flossDescriptionLabel.text = [NSLocalizedString(@"FIRST_STEPS_FLOSS", @"") stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\n"];

    [self.learnMoreButton setTitle:NSLocalizedString(@"BUTTON_LEARN_MORE", @"") forState:UIControlStateNormal];
}

- (NSString *)pageTitle
{
    return @"VLC";
}

- (NSUInteger)page
{
    return 6;
}

- (IBAction)learnMore:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.videolan.org/contribute.html"]];
}

@end
