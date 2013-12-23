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

    /* FIXME: l10n */
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
