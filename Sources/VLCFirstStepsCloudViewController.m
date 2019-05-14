/*****************************************************************************
 * VLCFirstStepsCloudViewController
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFirstStepsCloudViewController.h"
#import "VLC-Swift.h"

@implementation VLCFirstStepsCloudViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.titleLabel.text = NSLocalizedString(@"FIRST_STEPS_CLOUD_TITLE", nil);
    self.descriptionLabel.text = NSLocalizedString(@"FIRST_STEPS_CLOUD_DETAILS", nil);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTheme) name:kVLCThemeDidChangeNotification object:nil];
    [self updateTheme];
}

- (void)updateTheme
{
    self.titleLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    self.descriptionLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    self.backgroundView.backgroundColor = PresentationTheme.current.colors.background;
    BOOL isDarkTheme = PresentationTheme.current == PresentationTheme.darkTheme;
    self.phoneImage.image = isDarkTheme ? [UIImage imageNamed:@"blackCloudiPhone"] : [UIImage imageNamed:@"whiteCloudiPhone"];
}

- (NSString *)pageTitle
{
    return NSLocalizedString(@"FIRST_STEPS_CLOUDS", nil);
}

- (NSUInteger)page
{
    return 2;
}

@end
