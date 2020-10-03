/*****************************************************************************
 * VLCFirstStepsiTunesSyncViewController
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

#import "VLCFirstStepsiTunesSyncViewController.h"
#import "VLC-Swift.h"

@implementation VLCFirstStepsiTunesSyncViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:NSStringFromClass([VLCFirstStepsBaseViewController class]) bundle:nibBundleOrNil];
    return self;
}

+ (VLCFirstStepsPage)page
{
    return VLCFirstStepsPageiTunesSync;
}

+ (NSString *)pageTitleText
{
    return NSLocalizedString(@"FIRST_STEPS_ITUNES", nil);
}

+ (NSString *)titleText
{
    return NSLocalizedString(@"FIRST_STEPS_ITUNES_TITLE", nil);
}

+ (NSString *)descriptionText
{
    return NSLocalizedString(@"FIRST_STEPS_ITUNES_DETAILS", nil);
}

- (NSArray <NSLayoutConstraint *> *)imageViewConstraints:(UIImageView *)imageView
{
    UIImage *img = imageView.image;
    return @[
        [imageView.widthAnchor constraintEqualToAnchor:imageView.heightAnchor multiplier:img.size.width / img.size.height],
        [imageView.leadingAnchor constraintEqualToAnchor:self.centralView.leadingAnchor],
        [imageView.topAnchor constraintEqualToAnchor:self.centralView.topAnchor],
        [imageView.bottomAnchor constraintLessThanOrEqualToAnchor:self.centralView.bottomAnchor],
    ];
}

@end
