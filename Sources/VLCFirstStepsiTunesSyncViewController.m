/*****************************************************************************
 * VLCFirstStepsiTunesSyncViewController
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFirstStepsiTunesSyncViewController.h"
#import "VLC-Swift.h"

@implementation VLCFirstStepsiTunesSyncViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.descriptionLabel.text = NSLocalizedString(@"FIRST_STEPS_ITUNES_DETAILS", nil);
    self.titleLabel.text = NSLocalizedString(@"FIRST_STEPS_ITUNES_TITLE", nil);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTheme) name:kVLCThemeDidChangeNotification object:nil];
    [self updateTheme];
}

- (void)updateTheme
{
    self.titleLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    self.descriptionLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor;
    self.backgroundView.backgroundColor = PresentationTheme.current.colors.background;
    self.view.backgroundColor = PresentationTheme.current.colors.background;
}

- (NSString *)pageTitle
{
    return NSLocalizedString(@"FIRST_STEPS_ITUNES", nil);
}

- (NSUInteger)page
{
    return 0;
}

@end
