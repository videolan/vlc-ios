/*****************************************************************************
 * VLCFirstStepsFifthPageViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFirstStepsFifthPageViewController.h"

@interface VLCFirstStepsFifthPageViewController ()

@end

@implementation VLCFirstStepsFifthPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    /* FIXME: l10n */
}

- (NSString *)pageTitle
{
    return @"Playback";
}

- (NSUInteger)page
{
    return 5;
}

@end
