/*****************************************************************************
 * VLCFirstStepsSecondPageViewController
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
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

    NSString *model = [[UIDevice currentDevice] model];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        self.descriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"FIRST_STEPS_ITUNES_DETAILS", @""), model, model];
    else
        self.descriptionLabel.text = [[NSString stringWithFormat:NSLocalizedString(@"FIRST_STEPS_ITUNES_DETAILS", @""), model, model] stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\n"];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.actualContentView.center = self.view.center;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.actualContentView.center = self.view.center;
}

- (NSString *)pageTitle
{
    return NSLocalizedString(@"FIRST_STEPS_ITUNES", @"");
}

- (NSUInteger)page
{
    return 2;
}

@end
