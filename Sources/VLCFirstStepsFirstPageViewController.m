/*****************************************************************************
 * VLCFirstStepsFirstPageViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFirstStepsFirstPageViewController.h"

@interface VLCFirstStepsFirstPageViewController ()

@end

@implementation VLCFirstStepsFirstPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.titleLabel.text = NSLocalizedString(@"FIRST_STEPS_WELCOME", @"");
    self.subtitleLabel.text = NSLocalizedString(@"FIRST_STEPS_WELCOME_DETAIL", @"");
}

- (NSString *)pageTitle
{
    return NSLocalizedString(@"FIRST_STEPS_WELCOME", @"");;
}

- (NSUInteger)page
{
    return 1;
}

@end
