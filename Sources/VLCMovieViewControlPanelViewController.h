/*****************************************************************************
 * VLCMovieViewControlPanelViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan@tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "VLCPlaybackController.h"

@interface VLCMovieViewControlPanelViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIButton *playbackSpeedButton;
@property (nonatomic, strong) IBOutlet UIButton *trackSwitcherButton;

@property (nonatomic, strong) IBOutlet UIButton *bwdButton;
@property (nonatomic, strong) IBOutlet UIButton *playPauseButton;
@property (nonatomic, strong) IBOutlet UIButton *fwdButton;

@property (nonatomic, strong) IBOutlet UIButton *videoFilterButton;
@property (nonatomic, strong) IBOutlet UIButton *moreActionsButton;

@property (nonatomic, strong) IBOutlet MPVolumeView *volumeView;


@property (nonatomic, weak) VLCPlaybackController *playbackController;


- (void)updateButtons;

@end
