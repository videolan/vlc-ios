/*****************************************************************************
 * VLCFirstStepsWifiSharingViewController
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFirstStepsDonateViewController.h"
#import "VLC-Swift.h"

@implementation VLCFirstStepsDonateViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:NSStringFromClass([VLCFirstStepsBaseViewController class]) bundle:nibBundleOrNil];
    return self;
}

+ (VLCFirstStepsPage)page
{
    return VLCFirstStepsDonate;
}

+ (NSString *)pageTitleText
{
    return NSLocalizedString(@"DONATION_WINDOW_TITLE", nil);
}

+ (NSString *)titleText
{
    return NSLocalizedString(@"SEND_DONATION", nil);
}

+ (NSString *)descriptionText
{
    return NSLocalizedString(@"DONATION_DESCRIPTION", nil);
}

- (void)configurePage
{
    [super configurePage];

    UIImage *img = [UIImage imageNamed:@"Lunettes"];
    for (UIImageView *imageView in self.images) {
        imageView.image = img;
    }
}

@end
