/*****************************************************************************
 * VLCFirstStepsSecondPageViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFirstStepsSecondPageViewController.h"

@interface VLCFirstStepsSecondPageViewController ()

@end

@implementation VLCFirstStepsSecondPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    /* FIXME: l10n */
}

- (NSString *)pageTitle
{
    return @"iTunes File Sync";
}

- (NSUInteger)page
{
    return 2;
}

@end
