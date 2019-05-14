/*****************************************************************************
 * VLCFirstStepsWifiSharingViewController
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFirstStepsWifiSharingViewController.h"
#import "VLC-Swift.h"

@implementation VLCFirstStepsWifiSharingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.titleLabel.text = NSLocalizedString(@"FIRST_STEPS_WIFI_TITLE", nil);
    self.descriptionLabel.text =NSLocalizedString(@"FIRST_STEPS_WIFI_DETAILS", nil);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTheme) name:kVLCThemeDidChangeNotification object:nil];
    [self updateTheme];
}

- (void)updateTheme
{
    self.titleLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    self.descriptionLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor;
    self.backgroundView.backgroundColor = PresentationTheme.current.colors.background;
    BOOL isDarkTheme = PresentationTheme.current == PresentationTheme.darkTheme;
    self.phoneImage.image = isDarkTheme ? [UIImage imageNamed:@"blackiPhone"] : [UIImage imageNamed:@"whiteiPhone"];
}

- (NSString *)pageTitle
{
    return NSLocalizedString(@"WEBINTF_TITLE", nil);
}

- (NSUInteger)page
{
    return 1;
}

@end
