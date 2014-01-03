/*****************************************************************************
 * VLCFirstStepsThirdPageViewController
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
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

    self.connectDescriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"FIRST_STEPS_WIFI_CONNECT_DETAILS",@""), [[UIDevice currentDevice] model]];
    self.uploadDescriptionLabel.text = NSLocalizedString(@"FIRST_STEPS_WIFI_UPLOAD_DETAILS", @"");
}

- (NSString *)pageTitle
{
    return NSLocalizedString(@"HTTP_UPLOAD", @"");
}

- (NSUInteger)page
{
    return 3;
}

@end
