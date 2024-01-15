/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *        Felix Paul Kühne <fkuehne # videolan.org>
 *        Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackInfoPanelTVViewController.h"
#import "VLCMetadata.h"

#define DEFAULT_DELAY 0.0
#define MIN_DELAY -30000.0
#define MAX_DELAY 30000.0
#define MIN_SPEED 0.25
#define MAX_SPEED 8.0

typedef enum {
    VLCPlaybackOptionsTypePlaybackSpeed,
    VLCPlaybackOptionsTypeSubtitlesDelay,
    VLCPlaybackOptionsTypeAudioDelay,
    VLCPlaybackOptionsTypeNone
} VLCPlaybackOptionsType;

@interface VLCPlaybackInfoPlaybackTVViewController : VLCPlaybackInfoPanelTVViewController
@property (weak, nonatomic) IBOutlet UIStackView *optionsStackView;
@property (nonatomic, weak) IBOutlet UILabel *rateLabel;
@property (weak, nonatomic) IBOutlet UIButton *playbackSpeedButton;
@property (weak, nonatomic) IBOutlet UIView *subtitlesDelayView;
@property (weak, nonatomic) IBOutlet UILabel *subtitlesLabel;
@property (weak, nonatomic) IBOutlet UIButton *subtitlesDelayButton;
@property (weak, nonatomic) IBOutlet UILabel *audioLabel;
@property (weak, nonatomic) IBOutlet UIButton *audioDelayButton;
@property (nonatomic, weak) IBOutlet UISegmentedControl *repeatControl;
@property (nonatomic, weak) IBOutlet UILabel *repeatLabel;
@property (nonatomic, weak) IBOutlet UISegmentedControl *shuffleControl;
@property (nonatomic, weak) IBOutlet UILabel *shuffleLabel;

@property (weak, nonatomic) IBOutlet UIView *valueSelectorView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UIButton *increaseButton;
@property (weak, nonatomic) IBOutlet UIButton *decreaseButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;

- (IBAction)repeatControlChanged:(UISegmentedControl *)sender;
- (IBAction)shuffleControlChanged:(UISegmentedControl *)sender;
- (IBAction)handleResetButton:(UIButton *)sender;
- (IBAction)handlePlaybackSpeed:(UIButton *)sender;
- (IBAction)handleSubtitlesDelay:(UIButton *)sender;
- (IBAction)handleAudioDelay:(UIButton *)sender;
- (IBAction)handleIncreaseDecrease:(UIButton *)sender;

@end
