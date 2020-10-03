/*****************************************************************************
 * VLCFirstStepsWifiSharingViewController
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pavel Akhrameev <p.akhrameev@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFirstStepsWifiSharingViewController.h"
#import "VLC-Swift.h"

@implementation VLCFirstStepsWifiSharingViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:NSStringFromClass([VLCFirstStepsBaseViewController class]) bundle:nibBundleOrNil];
    return self;
}

+ (VLCFirstStepsPage)page
{
    return VLCFirstStepsPageWifiSharing;
}

+ (NSString *)pageTitleText
{
    return NSLocalizedString(@"WEBINTF_TITLE", nil);
}

+ (NSString *)titleText
{
    return NSLocalizedString(@"FIRST_STEPS_WIFI_TITLE", nil);
}

+ (NSString *)descriptionText
{
    return NSLocalizedString(@"FIRST_STEPS_WIFI_DETAILS", nil);
}

- (void)configurePage
{
    [super configurePage];

    BOOL isDarkTheme = PresentationTheme.current == PresentationTheme.darkTheme;
    UIImage *img = isDarkTheme ? [UIImage imageNamed:@"blackiPhone"] : [UIImage imageNamed:@"whiteiPhone"];
    for (UIImageView *imageView in self.images) {
        imageView.image = img;
    }
}

@end
