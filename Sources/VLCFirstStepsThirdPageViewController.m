/*****************************************************************************
 * VLCFirstStepsThirdPageViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFirstStepsThirdPageViewController.h"

@interface VLCFirstStepsThirdPageViewController ()

@end

@implementation VLCFirstStepsThirdPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    /* FIXME: l10n */
}

- (NSString *)pageTitle
{
    return @"WiFi Upload";
}

- (NSUInteger)page
{
    return 3;
}

@end
