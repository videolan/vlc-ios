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

    self.titleLabel.text = NSLocalizedString(@"FIRST_STEPS_WELCOME", nil);
    self.subtitleLabel.text = NSLocalizedString(@"FIRST_STEPS_WELCOME_DETAIL", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.actualContentView.center = self.view.center;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.actualContentView.center = self.view.center;
}

- (NSString *)pageTitle
{
    return NSLocalizedString(@"FIRST_STEPS_WELCOME", nil);;
}

- (NSUInteger)page
{
    return 1;
}

@end
