/*****************************************************************************
 * VLCMovieViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <MediaPlayer/MediaPlayer.h>
#import "VLCFrostedGlasView.h"
#import "VLCPlaybackService.h"

@class OBSlider;
@class VLCServices;
@class VLCStatusLabel;
@class VLCVerticalSwipeGestureRecognizer;
@class VLCMovieViewControlPanelView;
@class VLCMovieViewController;

typedef NS_ENUM(NSInteger, VLCMovieJumpState) {
    VLCMovieJumpStateDefault,
    VLCMovieJumpStateForward,
    VLCMovieJumpStateBackward
};

@protocol VLCMovieViewControllerDelegate
- (void)movieViewControllerDidSelectMinimize:(VLCMovieViewController *)movieViewController;
- (BOOL)movieViewControllerShouldBeDisplayed:(VLCMovieViewController *)movieViewController;
@end

@interface VLCMovieViewController : UIViewController <UIActionSheetDelegate, VLCPlaybackServiceDelegate>

@property (nonatomic, strong) IBOutlet UIView *movieView;
@property (nonatomic, strong) IBOutlet VLCStatusLabel *statusLabel;

@property (nonatomic, strong) IBOutlet VLCFrostedGlasView *videoFilterView;
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

@property (nonatomic, strong) IBOutlet VLCFrostedGlasView *scrubIndicatorView;
@property (nonatomic, strong) IBOutlet UILabel *currentScrubSpeedLabel;
@property (nonatomic, strong) IBOutlet UILabel *scrubHelpLabel;

@property (nonatomic, strong) IBOutlet UILabel *artistNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *albumNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *trackNameLabel;
@property (nonatomic, strong) IBOutlet UIImageView *artworkImageView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *widthConstraint;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, weak) id<VLCMovieViewControllerDelegate> delegate;

- (instancetype)initWithServices:(VLCServices *)services;

- (IBAction)positionSliderAction:(id)sender;
- (IBAction)positionSliderTouchDown:(id)sender;
- (IBAction)positionSliderTouchUp:(id)sender;
- (IBAction)positionSliderDrag:(id)sender;
- (IBAction)toggleTimeDisplay:(id)sender;

- (IBAction)videoFilterSliderAction:(id)sender;

- (IBAction)videoDimensionAction:(id)sender;

- (void)toggleRepeatMode;
- (void)toggleShuffleMode;
- (void)toggleEqualizer;
- (void)toggleUILock;
- (void)toggleChapterAndTitleSelector;
- (void)hideMenu;

@end
