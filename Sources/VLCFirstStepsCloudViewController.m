/*****************************************************************************
 * VLCFirstStepsCloudViewController
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

#import "VLCFirstStepsCloudViewController.h"
#import "VLC-Swift.h"

@implementation VLCFirstStepsCloudViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:NSStringFromClass([VLCFirstStepsBaseViewController class]) bundle:nibBundleOrNil];
    return self;
}

+ (VLCFirstStepsPage)page
{
    return VLCFirstStepsPageClouds;
}

+ (NSString *)pageTitleText
{
    return NSLocalizedString(@"FIRST_STEPS_CLOUDS", nil);
}

+ (NSString *)titleText
{
    return NSLocalizedString(@"FIRST_STEPS_CLOUD_TITLE", nil);
}

+ (NSString *)descriptionText
{
    return NSLocalizedString(@"FIRST_STEPS_CLOUD_DETAILS", nil);
}

- (void)configurePage
{
    [super configurePage];

    BOOL isDarkTheme = PresentationTheme.current == PresentationTheme.darkTheme;
    UIImage *img = isDarkTheme ? [UIImage imageNamed:@"blackCloudiPhone"] : [UIImage imageNamed:@"whiteCloudiPhone"];
    for (UIImageView *imageView in self.images) {
        imageView.image = img;
    }
}

@end
