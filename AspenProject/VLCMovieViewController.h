//
//  VLCDetailViewController.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCStatusLabel.h"
#import "VLCHorizontalSwipeGestureRecognizer.h"
#import "VLCVerticalSwipeGestureRecognizer.h"
#import "OBSlider.h"
#import <MediaPlayer/MediaPlayer.h>

@interface VLCMovieViewController : UIViewController <VLCMediaPlayerDelegate, UIActionSheetDelegate, VLCHorizontalSwipeGestureRecognizer, VLCVerticalSwipeGestureRecognizer>

@property (nonatomic, strong) IBOutlet UIView *movieView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, strong) IBOutlet OBSlider *positionSlider;
@property (nonatomic, strong) IBOutlet UIButton *timeDisplay;
@property (nonatomic, strong) IBOutlet UIButton *playPauseButton;
@property (nonatomic, strong) IBOutlet UIButton *bwdButton;
@property (nonatomic, strong) IBOutlet UIButton *fwdButton;
@property (nonatomic, strong) IBOutlet UIButton *subtitleSwitcherButton;
@property (nonatomic, strong) IBOutlet UIButton *audioSwitcherButton;
@property (nonatomic, strong) IBOutlet UINavigationBar *toolbar;
@property (nonatomic, strong) IBOutlet UIView *controllerPanel;
@property (nonatomic, strong) IBOutlet VLCStatusLabel *statusLabel;
@property (nonatomic, strong) IBOutlet MPVolumeView *volumeView;

@property (nonatomic, strong) IBOutlet UIView *playingExternallyView;
@property (nonatomic, strong) IBOutlet UILabel *playingExternallyTitle;
@property (nonatomic, strong) IBOutlet UILabel *playingExternallyDescription;

@property (nonatomic, strong) IBOutlet UIView *videoFilterView;
@property (nonatomic, strong) IBOutlet UIButton *videoFilterButton;
@property (nonatomic, strong) IBOutlet UILabel *hueLabel;
@property (nonatomic, strong) IBOutlet UISlider *hueSlider;
@property (nonatomic, strong) IBOutlet UILabel *contrastLabel;
@property (nonatomic, strong) IBOutlet UISlider *contrastSlider;
@property (nonatomic, strong) IBOutlet UILabel *brightnessLabel;
@property (nonatomic, strong) IBOutlet UISlider *brightnessSlider;
@property (nonatomic, strong) IBOutlet UILabel *saturationLabel;
@property (nonatomic, strong) IBOutlet UISlider *saturationSlider;
@property (nonatomic, strong) IBOutlet UILabel *gammaLabel;
@property (nonatomic, strong) IBOutlet UISlider *gammaSlider;
@property (nonatomic, strong) IBOutlet UIButton *resetVideoFilterButton;

@property (nonatomic, strong) IBOutlet UIView *playbackSpeedView;
@property (nonatomic, strong) IBOutlet UIButton *playbackSpeedButton;
@property (nonatomic, strong) IBOutlet UISlider *playbackSpeedSlider;
@property (nonatomic, strong) IBOutlet UILabel *playbackSpeedLabel;
@property (nonatomic, strong) IBOutlet UILabel *playbackSpeedIndicator;
@property (nonatomic, strong) IBOutlet UIButton *aspectRatioButton;

@property (nonatomic, strong) IBOutlet UIView *scrubIndicatorView;
@property (nonatomic, strong) IBOutlet UILabel *currentScrubSpeedLabel;
@property (nonatomic, strong) IBOutlet UILabel *scrubHelpLabel;

@property (nonatomic, strong) MLFile *mediaItem;
@property (nonatomic, strong) NSURL *url;

- (IBAction)closePlayback:(id)sender;

- (IBAction)positionSliderAction:(id)sender;
- (IBAction)positionSliderTouchDown:(id)sender;
- (IBAction)positionSliderTouchUp:(id)sender;
- (IBAction)positionSliderDrag:(id)sender;
- (IBAction)toggleTimeDisplay:(id)sender;

- (IBAction)playPause;
- (IBAction)backward:(id)sender;
- (IBAction)forward:(id)sender;
- (IBAction)switchAudioTrack:(id)sender;
- (IBAction)switchSubtitleTrack:(id)sender;

- (IBAction)videoFilterToggle:(id)sender;
- (IBAction)videoFilterSliderAction:(id)sender;

- (IBAction)playbackSpeedSliderAction:(id)sender;
- (IBAction)videoDimensionAction:(id)sender;

@end
