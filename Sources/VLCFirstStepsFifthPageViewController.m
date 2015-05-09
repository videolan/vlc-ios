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
    self.timeLabel.text = NSLocalizedString(@"FIRST_STEPS_TIME", nil);
    self.aspectLabel.text = NSLocalizedString(@"FIRST_STEPS_ASPECT", nil);
    self.speedLabel.text = NSLocalizedString(@"FIRST_STEPS_SPEED", nil);
    self.repeatLabel.text = NSLocalizedString(@"FIRST_STEPS_REPEAT", nil);
    self.subtitlesLabel.text = NSLocalizedString(@"FIRST_STEPS_SUBTITLES", nil);
    self.audioLabel.text = NSLocalizedString(@"FIRST_STEPS_AUDIO", nil);
    self.volumeLabel.text = NSLocalizedString(@"VOLUME", nil);
    self.positionLabel.text = NSLocalizedString(@"FIRST_STEPS_POSITION", nil);
    self.effectsLabel.text = NSLocalizedString(@"VIDEO_FILTER", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self.actualContentView.center = self.view.center;
}

- (NSString *)pageTitle
{
    return NSLocalizedString(@"FIRST_STEPS_PLAYBACK", nil);
}

- (NSUInteger)page
{
    return 5;
}

@end
