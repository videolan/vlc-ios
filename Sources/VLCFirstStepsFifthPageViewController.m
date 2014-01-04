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
    self.timeLabel.text = NSLocalizedString(@"FIRST_STEPS_TIME", @"");
    self.aspectLabel.text = NSLocalizedString(@"FIRST_STEPS_ASPECT", @"");
    self.speedLabel.text = NSLocalizedString(@"FIRST_STEPS_SPEED", @"");
    self.repeatLabel.text = NSLocalizedString(@"FIRST_STEPS_REPEAT", @"");
    self.subtitlesLabel.text = NSLocalizedString(@"FIRST_STEPS_SUBTITLES", @"");
    self.audioLabel.text = NSLocalizedString(@"FIRST_STEPS_AUDIO", @"");
    self.volumeLabel.text = NSLocalizedString(@"FIRST_STEPS_VOLUME", @"");
    self.positionLabel.text = NSLocalizedString(@"FIRST_STEPS_POSITION", @"");
    self.effectsLabel.text = NSLocalizedString(@"VIDEO_FILTER", @"");
}

- (void)viewWillAppear:(BOOL)animated
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self.actualContentView.center = self.view.center;
}

- (NSString *)pageTitle
{
    return NSLocalizedString(@"FIRST_STEPS_PLAYBACK", @"");
}

- (NSUInteger)page
{
    return 5;
}

@end
