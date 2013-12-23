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
    /* FIXME: l10n */
}

- (NSString *)pageTitle
{
    return @"Welcome";
}

- (NSUInteger)page
{
    return 1;
}

@end
