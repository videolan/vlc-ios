/*****************************************************************************
 * VLCMovieViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Carola Nitz <caro # videolan.org>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Ahmad Harb <harb.dev.leb # gmail.com>
 *          Fabio Ritrovato <sephiroth87 # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Filipe Cabecinhas <vlc # filcab dot net>
 *          Marc Etcheverry <marc # taplightsoftware dot com>
 *          Christopher Loessl <cloessl # x-berg dot de>
 *          Sylver Bruneau <sylver.bruneau # gmail dot com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMovieViewController.h"
#import "VLCExternalDisplayController.h"
#import "VLCTrackSelectorTableViewCell.h"
#import "VLCTrackSelectorHeaderView.h"
#import "VLCEqualizerView.h"
#import "VLCMultiSelectionMenuView.h"
#import "VLCPlaybackController.h"
#import "UIDevice+VLC.h"
#import "VLCTimeNavigationTitleView.h"
#import "VLCPlayerDisplayController.h"
#import "VLCAppDelegate.h"
#import "VLCStatusLabel.h"
#import "VLCMovieViewControlPanelView.h"
#import "VLCSlider.h"
#import "VLCLibraryViewController.h"
#import "UIDevice+VLC.h"

#define FORWARD_SWIPE_DURATION 30
#define BACKWARD_SWIPE_DURATION 10
#define SHORT_JUMP_DURATION 10

#define ZOOM_SENSITIVITY 2.99f
#define DEFAULT_FOV 80.f
#define MAX_FOV 150.f
#define MIN_FOV 20.f

#define TRACK_SELECTOR_TABLEVIEW_CELL @"track selector table view cell"
#define TRACK_SELECTOR_TABLEVIEW_SECTIONHEADER @"track selector table view section header"

#define LOCKCHECK \
if (_interfaceIsLocked) \
return

typedef NS_ENUM(NSInteger, VLCPanType) {
  VLCPanTypeNone,
  VLCPanTypeBrightness,
  VLCPanTypeSeek,
  VLCPanTypeVolume,
  VLCPanTypeProjection
};

@interface VLCMovieViewController () <UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, VLCMultiSelectionViewDelegate, VLCEqualizerViewUIDelegate>
{
    BOOL _controlsHidden;
    BOOL _videoFiltersHidden;
    BOOL _playbackSpeedViewHidden;

    UIActionSheet *_subtitleActionSheet;
    UIActionSheet *_audiotrackActionSheet;

    NSTimer *_idleTimer;

    BOOL _viewAppeared;
    BOOL _displayRemainingTime;
    BOOL _positionSet;
    BOOL _playerIsSetup;
    BOOL _isScrubbing;
    BOOL _interfaceIsLocked;
    BOOL _switchingTracksNotChapters;
    BOOL _audioOnly;

    BOOL _volumeGestureEnabled;
    BOOL _playPauseGestureEnabled;
    BOOL _brightnessGestureEnabled;
    BOOL _seekGestureEnabled;
    BOOL _closeGestureEnabled;
    BOOL _variableJumpDurationEnabled;
    BOOL _mediaHasProjection;
    BOOL _playbackWillClose;
    BOOL _isTapSeeking;
    VLCMovieJumpState _previousJumpState;

    UIPinchGestureRecognizer *_pinchRecognizer;
    VLCPanType _currentPanType;
    UIPanGestureRecognizer *_panRecognizer;
    UISwipeGestureRecognizer *_swipeRecognizerLeft;
    UISwipeGestureRecognizer *_swipeRecognizerRight;
    UISwipeGestureRecognizer *_swipeRecognizerUp;
    UISwipeGestureRecognizer *_swipeRecognizerDown;
    UITapGestureRecognizer *_tapRecognizer;
    UITapGestureRecognizer *_tapOnVideoRecognizer;
    UITapGestureRecognizer *_tapToSeekRecognizer;
    UITapGestureRecognizer *_tapToToggleiPhoneXRatioRecognizer;

    UIView *_trackSelectorContainer;
    UITableView *_trackSelectorTableView;

    VLCEqualizerView *_equalizerView;
    VLCMultiSelectionMenuView *_multiSelectionView;

    VLCPlaybackController *_vpc;

    UIView *_sleepTimerContainer;
    UIDatePicker *_sleepTimeDatePicker;
    NSTimer *_sleepCountDownTimer;

    NSInteger _mediaDuration;
    NSInteger _numberOfTapSeek;

    CGFloat _fov;
    CGPoint _saveLocation;
    CGSize _screenSizePixel;
}
@property (nonatomic, strong) VLCMovieViewControlPanelView *controllerPanel;
@property (nonatomic, strong) UIPopoverController *masterPopoverController;
@property (nonatomic, strong) UIWindow *externalWindow;
@end

@implementation VLCMovieViewController

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = @{kVLCShowRemainingTime : @(YES)};
    [defaults registerDefaults:appDefaults];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (_tapRecognizer)
        [self.view removeGestureRecognizer:_tapRecognizer];
    if (_swipeRecognizerLeft)
        [self.view removeGestureRecognizer:_swipeRecognizerLeft];
    if (_swipeRecognizerRight)
        [self.view removeGestureRecognizer:_swipeRecognizerRight];
    if (_swipeRecognizerUp)
        [self.view removeGestureRecognizer:_swipeRecognizerUp];
    if (_swipeRecognizerDown)
        [self.view removeGestureRecognizer:_swipeRecognizerDown];
    if (_panRecognizer)
        [self.view removeGestureRecognizer:_panRecognizer];
    if (_pinchRecognizer)
        [self.view removeGestureRecognizer:_pinchRecognizer];
    if (_tapToSeekRecognizer)
        [self.view removeGestureRecognizer:_tapToSeekRecognizer];
    if (_tapToToggleiPhoneXRatioRecognizer) {
        [self.view removeGestureRecognizer:_tapToToggleiPhoneXRatioRecognizer];
    }
    [self.view removeGestureRecognizer:_tapOnVideoRecognizer];

    _tapRecognizer = nil;
    _swipeRecognizerLeft = nil;
    _swipeRecognizerRight = nil;
    _swipeRecognizerUp = nil;
    _swipeRecognizerDown = nil;
    _panRecognizer = nil;
    _pinchRecognizer = nil;
    _tapOnVideoRecognizer = nil;
    _tapToSeekRecognizer = nil;
    _tapToToggleiPhoneXRatioRecognizer = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect rect;

    _vpc = [VLCPlaybackController sharedInstance];

    int deviceSpeedCategory = [[UIDevice currentDevice] VLCSpeedCategory];

    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;

    self.videoFilterView.hidden = YES;
    _videoFiltersHidden = YES;
    _hueLabel.text = NSLocalizedString(@"VFILTER_HUE", nil);
    _hueSlider.accessibilityLabel = _hueLabel.text;
    _hueSlider.isAccessibilityElement = YES;
    _contrastLabel.text = NSLocalizedString(@"VFILTER_CONTRAST", nil);
    _contrastSlider.accessibilityLabel = _contrastLabel.text;
    _contrastSlider.isAccessibilityElement = YES;
    _brightnessLabel.text = NSLocalizedString(@"VFILTER_BRIGHTNESS", nil);
    _brightnessSlider.accessibilityLabel = _brightnessLabel.text;
    _brightnessSlider.isAccessibilityElement = YES;
    _saturationLabel.text = NSLocalizedString(@"VFILTER_SATURATION", nil);
    _saturationSlider.accessibilityLabel = _saturationLabel.text;
    _saturationSlider.isAccessibilityElement = YES;
    _gammaLabel.text = NSLocalizedString(@"VFILTER_GAMMA", nil);
    _gammaSlider.accessibilityLabel = _gammaLabel.text;
    _gammaSlider.isAccessibilityElement = YES;
    _playbackSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SPEED", nil);
    _playbackSpeedSlider.accessibilityLabel = _playbackSpeedLabel.text;
    _playbackSpeedSlider.isAccessibilityElement = YES;
    _audioDelayLabel.text = NSLocalizedString(@"AUDIO_DELAY", nil);
    _audioDelaySlider.accessibilityLabel = _audioDelayLabel.text;
    _audioDelaySlider.isAccessibilityElement = YES;
    _spuDelayLabel.text = NSLocalizedString(@"SPU_DELAY", nil);
    _spuDelaySlider.accessibilityLabel = _spuDelayLabel.text;
    _spuDelaySlider.isAccessibilityElement = YES;

    _resetVideoFilterButton.accessibilityLabel = NSLocalizedString(@"VIDEO_FILTER_RESET_BUTTON", nil);
    _resetVideoFilterButton.isAccessibilityElement = YES;
    _sleepTimerButton.accessibilityLabel = NSLocalizedString(@"BUTTON_SLEEP_TIMER", nil);
    _sleepTimerButton.isAccessibilityElement = YES;
    [_sleepTimerButton setTitle:NSLocalizedString(@"BUTTON_SLEEP_TIMER", nil) forState:UIControlStateNormal];

    _multiSelectionView = [[VLCMultiSelectionMenuView alloc] init];
    _multiSelectionView.delegate = self;
    _multiSelectionView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _multiSelectionView.hidden = YES;
    [self.view addSubview:_multiSelectionView];

    _scrubHelpLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_HELP", nil);

    self.playbackSpeedView.hidden = YES;
    _playbackSpeedViewHidden = YES;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(handleExternalScreenDidConnect:)
                   name:UIScreenDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(handleExternalScreenDidDisconnect:)
                   name:UIScreenDidDisconnectNotification object:nil];
    [center addObserver:self selector:@selector(screenBrightnessChanged:)
                   name:UIScreenBrightnessDidChangeNotification object:nil];
    [center addObserver:self
               selector:@selector(appBecameActive:)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(playbackDidStop:)
                   name:VLCPlaybackControllerPlaybackDidStop
                 object:nil];

    _playingExternallyTitle.text = NSLocalizedString(@"PLAYING_EXTERNALLY_TITLE", nil);
    _playingExternallyDescription.text = NSLocalizedString(@"PLAYING_EXTERNALLY_DESC", nil);
    if ([[UIDevice currentDevice] VLCHasExternalDisplay])
        [self showOnExternalDisplay];

    self.trackNameLabel.text = self.artistNameLabel.text = self.albumNameLabel.text = @"";

    _movieView.userInteractionEnabled = NO;

    _tapOnVideoRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControlsVisible)];
    _tapOnVideoRecognizer.delegate = self;
    [self.view addGestureRecognizer:_tapOnVideoRecognizer];

    _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    _pinchRecognizer.delegate = self;

    if ([[UIDevice currentDevice] isiPhoneX]) {
        _tapToToggleiPhoneXRatioRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:_vpc action:@selector(switchIPhoneXFullScreen)];
        _tapToToggleiPhoneXRatioRecognizer.numberOfTapsRequired = 2;
        [self.view addGestureRecognizer:_tapToToggleiPhoneXRatioRecognizer];
     } else {
        _tapToSeekRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToSeekRecognized:)];
        [_tapToSeekRecognizer setNumberOfTapsRequired:2];
        [_tapOnVideoRecognizer requireGestureRecognizerToFail:_tapToSeekRecognizer];
        [self.view addGestureRecognizer:_tapToSeekRecognizer];
    }
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayPause)];
    [_tapRecognizer setNumberOfTouchesRequired:2];

    _currentPanType = VLCPanTypeNone;
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panRecognized:)];
    [_panRecognizer setMinimumNumberOfTouches:1];
    [_panRecognizer setMaximumNumberOfTouches:1];


    _swipeRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
    _swipeRecognizerLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    _swipeRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
    _swipeRecognizerRight.direction = UISwipeGestureRecognizerDirectionRight;
    _swipeRecognizerUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
    _swipeRecognizerUp.direction = UISwipeGestureRecognizerDirectionUp;
    _swipeRecognizerUp.numberOfTouchesRequired = 2;
    _swipeRecognizerDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
    _swipeRecognizerDown.direction = UISwipeGestureRecognizerDirectionDown;
    _swipeRecognizerDown.numberOfTouchesRequired = 2;

    [self.view addGestureRecognizer:_pinchRecognizer];
    [self.view addGestureRecognizer:_swipeRecognizerLeft];
    [self.view addGestureRecognizer:_swipeRecognizerRight];
    [self.view addGestureRecognizer:_swipeRecognizerUp];
    [self.view addGestureRecognizer:_swipeRecognizerDown];
    [self.view addGestureRecognizer:_panRecognizer];
    [self.view addGestureRecognizer:_tapRecognizer];

    [_panRecognizer requireGestureRecognizerToFail:_swipeRecognizerLeft];
    [_panRecognizer requireGestureRecognizerToFail:_swipeRecognizerRight];
    [_panRecognizer requireGestureRecognizerToFail:_swipeRecognizerUp];
    [_panRecognizer requireGestureRecognizerToFail:_swipeRecognizerDown];

    _panRecognizer.delegate = self;
    _swipeRecognizerRight.delegate = self;
    _swipeRecognizerLeft.delegate = self;
    _swipeRecognizerUp.delegate = self;
    _swipeRecognizerDown.delegate = self;
    _tapRecognizer.delegate = self;
    _tapToSeekRecognizer.delegate = self;

    _isTapSeeking = NO;
    _previousJumpState = VLCMovieJumpStateDefault;
    _numberOfTapSeek = 0;

    _playerIsSetup = NO;

    [self.movieView setAccessibilityLabel:NSLocalizedString(@"VO_VIDEOPLAYER_TITLE", nil)];
    [self.movieView setAccessibilityHint:NSLocalizedString(@"VO_VIDEOPLAYER_DOUBLETAP", nil)];

    rect = self.view.frame;
    CGFloat width;
    CGFloat height;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        width = 300.;
        height = 320.;
    } else {
        width = 420.;
        height = 470.;
    }

    _trackSelectorTableView = [[UITableView alloc] initWithFrame:CGRectMake(0., 0., width, height) style:UITableViewStylePlain];
    _trackSelectorTableView.delegate = self;
    _trackSelectorTableView.dataSource = self;
    _trackSelectorTableView.separatorColor = [UIColor clearColor];
    _trackSelectorTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _trackSelectorTableView.rowHeight = 44.;
    _trackSelectorTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _trackSelectorTableView.sectionHeaderHeight = 28.;
    [_trackSelectorTableView registerClass:[VLCTrackSelectorTableViewCell class] forCellReuseIdentifier:TRACK_SELECTOR_TABLEVIEW_CELL];
    [_trackSelectorTableView registerClass:[VLCTrackSelectorHeaderView class] forHeaderFooterViewReuseIdentifier:TRACK_SELECTOR_TABLEVIEW_SECTIONHEADER];
    _trackSelectorTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    _trackSelectorContainer = [[VLCFrostedGlasView alloc] initWithFrame:CGRectMake((rect.size.width - width) / 2., (rect.size.height - height) / 2., width, height)];
    [_trackSelectorContainer addSubview:_trackSelectorTableView];
    _trackSelectorContainer.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;
    _trackSelectorContainer.hidden = YES;

    if (deviceSpeedCategory >= 3) {
        _trackSelectorTableView.opaque = NO;
        _trackSelectorTableView.backgroundColor = [UIColor clearColor];
    } else
        _trackSelectorTableView.backgroundColor = [UIColor blackColor];
    _trackSelectorTableView.allowsMultipleSelection = YES;

    [self.view addSubview:_trackSelectorContainer];

    _equalizerView = [[VLCEqualizerView alloc] initWithFrame:CGRectMake(0, 0, 450., 240.)];
    _equalizerView.delegate = [VLCPlaybackController sharedInstance];
    _equalizerView.UIdelegate = self;
    _equalizerView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    _equalizerView.hidden = YES;
    [self.view addSubview:_equalizerView];

    //Sleep Timer initialization
    [self sleepTimerInitializer:deviceSpeedCategory];
    [self setupControlPanel];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    _screenSizePixel = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
    _saveLocation = CGPointMake(-1.f, -1.f);

    [self setupConstraints];
}

- (void)setupControlPanel
{
    _controllerPanel = [[VLCMovieViewControlPanelView alloc] initWithFrame:CGRectZero];
    [_controllerPanel.bwdButton addTarget:self action:@selector(backward:) forControlEvents:UIControlEventTouchUpInside];
    [_controllerPanel.fwdButton addTarget:self action:@selector(forward:) forControlEvents:UIControlEventTouchUpInside];
    [_controllerPanel.playPauseButton addTarget:self action:@selector(playPause) forControlEvents:UIControlEventTouchUpInside];
    [_controllerPanel.moreActionsButton addTarget:self action:@selector(moreActions:) forControlEvents:UIControlEventTouchUpInside];
    [_controllerPanel.playbackSpeedButton addTarget:self action:@selector(showPlaybackSpeedView) forControlEvents:UIControlEventTouchUpInside];
    [_controllerPanel.trackSwitcherButton addTarget:self action:@selector(switchTrack:) forControlEvents:UIControlEventTouchUpInside];
    [_controllerPanel.videoFilterButton addTarget:self action:@selector(videoFilterToggle:) forControlEvents:UIControlEventTouchUpInside];

    // HACK: get the slider from volume view
    UISlider *volumeSlider = nil;
    for (id aView in _controllerPanel.volumeView.subviews){
        if ([aView isKindOfClass:[UISlider class]]){
            volumeSlider = (UISlider *)aView;
            break;
        }
    }
    [volumeSlider addTarget:self action:@selector(volumeSliderAction:) forControlEvents:UIControlEventValueChanged];

    _controllerPanel.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:_controllerPanel];
}

- (void)setupConstraints
{
    NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[panel]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:@{@"panel":_controllerPanel}];

    NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[panel]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:@{@"panel":_controllerPanel}];
    [self.view addConstraints:hConstraints];
    [self.view addConstraints:vConstraints];
}

- (void)setupNavigationbar
{
    UIButton *doneButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [doneButton addTarget:self action:@selector(closePlayback:) forControlEvents:UIControlEventTouchUpInside];
    [doneButton setTitle:NSLocalizedString(@"BUTTON_DONE", nil) forState:UIControlStateNormal];
    doneButton.translatesAutoresizingMaskIntoConstraints = NO;

    self.timeNavigationTitleView = [[[NSBundle mainBundle] loadNibNamed:@"VLCTimeNavigationTitleView" owner:self options:nil] objectAtIndex:0];
    self.timeNavigationTitleView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.navigationController.navigationBar addSubview:self.timeNavigationTitleView];
    [self.navigationController.navigationBar addSubview:doneButton];

    NSObject *guide = self.navigationController.navigationBar;
    if (@available(iOS 11.0, *)) {
        guide = self.navigationController.navigationBar.safeAreaLayoutGuide;
    }
    [self.navigationController.view addConstraints: @[
                                                      [NSLayoutConstraint constraintWithItem:doneButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeLeft multiplier:1 constant:8],
                                                      [NSLayoutConstraint constraintWithItem:doneButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.navigationController.navigationBar attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
                                                      [NSLayoutConstraint constraintWithItem:self.timeNavigationTitleView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:doneButton attribute:NSLayoutAttributeRight multiplier:1 constant:0],
                                                      [NSLayoutConstraint constraintWithItem:self.timeNavigationTitleView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeRight multiplier:1 constant:0],
                                                      [NSLayoutConstraint constraintWithItem:self.timeNavigationTitleView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.navigationController.navigationBar attribute:NSLayoutAttributeTop multiplier:1 constant:0],
                                                      [NSLayoutConstraint constraintWithItem:self.timeNavigationTitleView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.navigationController.navigationBar attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
                                                      ]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _vpc.delegate = self;
    [_vpc recoverPlaybackState];

    [self setupNavigationbar];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    /* reset audio meta data views */
    self.artworkImageView.image = nil;
    self.trackNameLabel.text = nil;
    self.artistNameLabel.text = nil;
    self.albumNameLabel.text = nil;

    [self screenBrightnessChanged:nil];
    [self setControlsHidden:NO animated:animated];

    [self updateDefaults];

    //Disabling video gestures, media not init in the player yet.
    [self enableNormalVideoGestures:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDefaults) name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _viewAppeared = YES;
    _playbackWillClose = NO;

    [_vpc recoverDisplayedMetadata];
    _vpc.videoOutputView = self.movieView;
    _multiSelectionView.repeatMode = _vpc.repeatMode;
    _multiSelectionView.shuffleMode = _vpc.isShuffleMode;

    //Media is loaded in the media player, checking the projection type and configuring accordingly.
    _fov = 0.f;
    _mediaHasProjection = NO;
    if ([_vpc currentMediaProjection] == VLCMediaProjectionEquiRectangular) {
        _fov = DEFAULT_FOV;
        _mediaHasProjection = YES;
    }

    [self enableNormalVideoGestures:!_mediaHasProjection];

}

- (void)viewDidLayoutSubviews
{
    CGRect equalizerRect = _equalizerView.frame;
    equalizerRect.origin.x = CGRectGetMidX(self.view.bounds) - CGRectGetWidth(equalizerRect)/2.0;
    equalizerRect.origin.y = CGRectGetMidY(self.view.bounds) - CGRectGetHeight(equalizerRect)/2.0;
    _equalizerView.frame = equalizerRect;

    CGRect multiSelectionFrame;
    CGRect controllerPanelFrame = _controllerPanel.frame;;

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) {
        multiSelectionFrame = (CGRect){CGPointMake(0., 0.), [_multiSelectionView proposedDisplaySize]};
        multiSelectionFrame.origin.x = controllerPanelFrame.size.width - multiSelectionFrame.size.width;
        multiSelectionFrame.origin.y = controllerPanelFrame.origin.y - multiSelectionFrame.size.height;
        _multiSelectionView.frame = multiSelectionFrame;
        _multiSelectionView.showsEqualizer = YES;
        return;
    }

    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        _multiSelectionView.showsEqualizer = YES;
        multiSelectionFrame = (CGRect){CGPointMake(0., 0.), [_multiSelectionView proposedDisplaySize]};
        multiSelectionFrame.origin.x = controllerPanelFrame.size.width - multiSelectionFrame.size.width;
        multiSelectionFrame.origin.y = controllerPanelFrame.origin.y - multiSelectionFrame.size.height;
    } else {
        _multiSelectionView.showsEqualizer = NO;
        multiSelectionFrame = (CGRect){CGPointMake(0., 0.), [_multiSelectionView proposedDisplaySize]};
        multiSelectionFrame.origin.x = controllerPanelFrame.size.width - multiSelectionFrame.size.width;
        multiSelectionFrame.origin.y = controllerPanelFrame.origin.y - multiSelectionFrame.size.height;
    }
    _multiSelectionView.frame = multiSelectionFrame;
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (_vpc.videoOutputView == self.movieView) {
        _vpc.videoOutputView = nil;
    }

    _viewAppeared = NO;
    if (_idleTimer) {
        [_idleTimer invalidate];
        _idleTimer = nil;
    }

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [super viewWillDisappear:animated];

    // hide filter UI for next run
    if (!_videoFiltersHidden)
        _videoFiltersHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    if (!_playbackSpeedViewHidden)
        _playbackSpeedViewHidden = YES;

    // reset tap to seek values
    _isTapSeeking = NO;
    _previousJumpState = VLCMovieJumpStateDefault;
    _numberOfTapSeek = 0;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    [[NSUserDefaults standardUserDefaults] setBool:_displayRemainingTime forKey:kVLCShowRemainingTime];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self setControlsHidden:YES animated:flag];
    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void)updateDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (!_playbackWillClose) {
        _displayRemainingTime = [[defaults objectForKey:kVLCShowRemainingTime] boolValue];
        [self updateTimeDisplayButton];
    }

    _volumeGestureEnabled = [[defaults objectForKey:kVLCSettingVolumeGesture] boolValue];
    _playPauseGestureEnabled = [[defaults objectForKey:kVLCSettingPlayPauseGesture] boolValue];
    _brightnessGestureEnabled = [[defaults objectForKey:kVLCSettingBrightnessGesture] boolValue];
    _seekGestureEnabled = [[defaults objectForKey:kVLCSettingSeekGesture] boolValue];
    _closeGestureEnabled = [[defaults objectForKey:kVLCSettingCloseGesture] boolValue];
    _variableJumpDurationEnabled = [[defaults objectForKey:kVLCSettingVariableJumpDuration] boolValue];
}

#pragma mark - Initializer helper

- (void)sleepTimerInitializer:(int)deviceSpeedCategory
{
    /* add sleep timer UI */
    _sleepTimerContainer = [[VLCFrostedGlasView alloc] initWithFrame:CGRectMake(0., 0., 300., 200.)];
    _sleepTimerContainer.center = self.view.center;
    _sleepTimerContainer.clipsToBounds = YES;
    _sleepTimerContainer.layer.cornerRadius = 5;
    _sleepTimerContainer.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;

    //Layers used to create a separator for the buttons.
    CALayer *horizontalSeparator = [CALayer layer];
    horizontalSeparator.frame = CGRectMake(0., 162., 300., 1.);
    horizontalSeparator.backgroundColor = [UIColor VLCLightTextColor].CGColor;

    CALayer *verticalSeparator = [CALayer layer];
    verticalSeparator.frame = CGRectMake(150., 162., 1., 48.);
    verticalSeparator.backgroundColor = [UIColor VLCLightTextColor].CGColor;

    _sleepTimeDatePicker = [[UIDatePicker alloc] init];
    if (deviceSpeedCategory >= 3) {
        _sleepTimeDatePicker.opaque = NO;
        _sleepTimeDatePicker.backgroundColor = [UIColor clearColor];
    } else
        _sleepTimeDatePicker.backgroundColor = [UIColor blackColor];
    _sleepTimeDatePicker.tintColor = [UIColor VLCLightTextColor];
    _sleepTimeDatePicker.frame = CGRectMake(0., 0., 300., 162.);
    _sleepTimeDatePicker.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;

    [_sleepTimerContainer addSubview:_sleepTimeDatePicker];
    [_sleepTimerContainer.layer addSublayer:horizontalSeparator];
    [_sleepTimerContainer.layer addSublayer:verticalSeparator];

    UIButton *cancelSleepTimer = [[UIButton alloc] initWithFrame:CGRectMake(0., 162., 150., 48.)];
    cancelSleepTimer.backgroundColor = [UIColor clearColor];
    [cancelSleepTimer setTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) forState:UIControlStateNormal];
    [cancelSleepTimer setTintColor:[UIColor VLCLightTextColor]];
    [cancelSleepTimer setTitleColor:[UIColor VLCDarkTextShadowColor] forState:UIControlStateHighlighted];
    [cancelSleepTimer addTarget:self action:@selector(sleepTimerCancel:) forControlEvents:UIControlEventTouchDown];
    cancelSleepTimer.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 10, 0);
    [_sleepTimerContainer addSubview:cancelSleepTimer];

    UIButton *confirmSleepTimer = [[UIButton alloc] initWithFrame:CGRectMake(150., 162., 150., 48.)];
    confirmSleepTimer.backgroundColor = [UIColor clearColor];
    [confirmSleepTimer setTitle:NSLocalizedString(@"BUTTON_DONE", nil) forState:UIControlStateNormal];
    [confirmSleepTimer setTintColor:[UIColor VLCLightTextColor]];
    [confirmSleepTimer setTitleColor:[UIColor VLCDarkTextShadowColor] forState:UIControlStateHighlighted];
    [confirmSleepTimer addTarget:self action:@selector(sleepTimerAction:) forControlEvents:UIControlEventTouchDown];
    confirmSleepTimer.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 10, 0);
    [_sleepTimerContainer addSubview:confirmSleepTimer];

    /* adapt the date picker style to suit our needs */
    [_sleepTimeDatePicker setValue:[UIColor whiteColor] forKeyPath:@"textColor"];
    SEL selector = NSSelectorFromString(@"setHighlightsToday:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDatePicker instanceMethodSignatureForSelector:selector]];
    BOOL no = NO;
    [invocation setSelector:selector];
    [invocation setArgument:&no atIndex:2];
    [invocation invokeWithTarget:_sleepTimeDatePicker];

    if (_sleepTimerContainer.subviews.count > 0) {
        NSArray *subviewsOfSubview = [_sleepTimeDatePicker.subviews[0] subviews];
        NSUInteger subviewCount = subviewsOfSubview.count;
        for (NSUInteger x = 0; x < subviewCount; x++) {
            if ([subviewsOfSubview[x] isKindOfClass:[UILabel class]])
                [subviewsOfSubview[x] setTextColor:[UIColor VLCLightTextColor]];
        }
    }
    _sleepTimeDatePicker.datePickerMode = UIDatePickerModeCountDownTimer;
    _sleepTimeDatePicker.minuteInterval = 1;
    _sleepTimeDatePicker.minimumDate = [NSDate date];
    _sleepTimeDatePicker.countDownDuration = 1200.;

    [self.view addSubview:_sleepTimerContainer];
}

#pragma mark - controls visibility

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    LOCKCHECK;

    if (!_closeGestureEnabled || isnan(recognizer.velocity))
        return;

    CGFloat diff = DEFAULT_FOV * -(ZOOM_SENSITIVITY * recognizer.velocity / _screenSizePixel.width);

    if (_mediaHasProjection) {
        if ([_vpc updateViewpoint:0 pitch:0 roll:0 fov:diff absolute:NO]) {
            //Checking for fov value in case of
            _fov = MAX(MIN(_fov + diff, MAX_FOV), MIN_FOV);
        }
    } else if (recognizer.velocity < 0.) {
        [self minimizePlayback:nil];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view != self.view)
        return NO;

    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated
{
    _controlsHidden = hidden;
    CGFloat alpha = _controlsHidden? 0.0f: 1.0f;

    if (!_controlsHidden) {
        self.navigationController.navigationBar.alpha = 0.0;
        self.navigationController.navigationBar.hidden = NO;
        _controllerPanel.alpha = 0.0f;
        _controllerPanel.hidden = !_videoFiltersHidden;
        _videoFilterView.alpha = 0.0f;
        _videoFilterView.hidden = _videoFiltersHidden;
        _playbackSpeedView.alpha = 0.0f;
        _playbackSpeedView.hidden = _playbackSpeedViewHidden;
        _trackSelectorContainer.alpha = 0.0f;
        _trackSelectorContainer.hidden = YES;
        _equalizerView.alpha = 0.0f;
        _equalizerView.hidden = YES;
        if (_sleepTimerContainer) {
            _sleepTimerContainer.alpha = 0.0f;
            _sleepTimerContainer.hidden = YES;
        }
        _multiSelectionView.alpha = 0.0f;
        _multiSelectionView.hidden = YES;

        _artistNameLabel.hidden = NO;
        _albumNameLabel.hidden = NO;
        _trackNameLabel.hidden = NO;
    }

    void (^animationBlock)() = ^() {
        self.navigationController.navigationBar.alpha = alpha;
        _controllerPanel.alpha = alpha;
        _videoFilterView.alpha = alpha;
        _playbackSpeedView.alpha = alpha;
        _trackSelectorContainer.alpha = alpha;
        _equalizerView.alpha = alpha;
        _multiSelectionView.alpha = alpha;
        if (_sleepTimerContainer)
            _sleepTimerContainer.alpha = alpha;

        CGFloat metaInfoAlpha = _audioOnly ? 1.0f : alpha;
        _artistNameLabel.alpha = metaInfoAlpha;
        _albumNameLabel.alpha = metaInfoAlpha;
        _trackNameLabel.alpha = metaInfoAlpha;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        _controllerPanel.hidden = _videoFiltersHidden ? _controlsHidden : NO;
        _videoFilterView.hidden = _videoFiltersHidden;
        _playbackSpeedView.hidden = _playbackSpeedViewHidden;
        self.navigationController.navigationBar.hidden = _controlsHidden;
        _trackSelectorContainer.hidden = YES;
        _equalizerView.hidden = YES;
        if (_sleepTimerContainer)
            _sleepTimerContainer.hidden = YES;
        _multiSelectionView.hidden = YES;

        _artistNameLabel.hidden = _audioOnly ? NO : _controlsHidden;
        _albumNameLabel.hidden =  _audioOnly ? NO : _controlsHidden;
        _trackNameLabel.hidden =  _audioOnly ? NO : _controlsHidden;
    };

    UIStatusBarAnimation animationType = animated? UIStatusBarAnimationFade: UIStatusBarAnimationNone;
    NSTimeInterval animationDuration = animated? 0.3: 0.0;

    [[UIApplication sharedApplication] setStatusBarHidden:_viewAppeared ? _controlsHidden : NO withAnimation:animationType];
    [UIView animateWithDuration:animationDuration animations:animationBlock completion:completionBlock];
}

- (void)toggleControlsVisible
{
    if (!_trackSelectorContainer.hidden) {
        for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers)
            [recognizer setEnabled:YES];
    }

    if (_controlsHidden && !_videoFiltersHidden)
        _videoFiltersHidden = YES;

    if (_isTapSeeking)
        _numberOfTapSeek = 0;

    [self setControlsHidden:!_controlsHidden animated:YES];
}

- (void)_resetIdleTimer
{
    if (!_idleTimer)
        _idleTimer = [NSTimer scheduledTimerWithTimeInterval:4.
                                                      target:self
                                                    selector:@selector(idleTimerExceeded)
                                                    userInfo:nil
                                                     repeats:NO];
    else {
        if (fabs([_idleTimer.fireDate timeIntervalSinceNow]) < 4.)
            [_idleTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:4.]];
    }
}

- (NSString *)_stringInTimeFormatFrom:(int)duration
{
    if (duration < 60) {
        return [NSString stringWithFormat:@"%is", duration];
    } else {
        return [NSString stringWithFormat:@"%im%is", duration / 60, duration % 60];
    }
}

- (void)_seekFromTap
{
    NSMutableString *hudString = [NSMutableString string];
    VLCMediaPlayer *mediaPlayer = _vpc.mediaPlayer;
    int seekDuration = (int)_numberOfTapSeek * SHORT_JUMP_DURATION;

    if (seekDuration > 0) {
        [mediaPlayer shortJumpForward];
        [hudString appendString:@"⇒ "];
        _previousJumpState = VLCMovieJumpStateForward;
    } else {
        [mediaPlayer shortJumpBackward];
        [hudString appendString:@"⇐ "];
        _previousJumpState = VLCMovieJumpStateBackward;
    }
    [hudString appendString: [self _stringInTimeFormatFrom:abs(seekDuration)]];
    [self.statusLabel showStatusMessage:[NSString stringWithString:hudString]];
    if (_controlsHidden)
        [self setControlsHidden:NO animated:NO];
}

- (void)idleTimerExceeded
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(idleTimerExceeded) withObject:nil waitUntilDone:NO];
        return;
    }

    _idleTimer = nil;
    if (!_controlsHidden)
        [self toggleControlsVisible];

    if (_isTapSeeking) {
        _isTapSeeking = NO;
        _numberOfTapSeek = 0;
    }

    if (!_videoFiltersHidden)
        _videoFiltersHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    if (!_playbackSpeedViewHidden)
        _playbackSpeedViewHidden = YES;

    if (self.scrubIndicatorView.hidden == NO)
        self.scrubIndicatorView.hidden = YES;
}

- (UIResponder *)nextResponder
{
    [self _resetIdleTimer];
    return [super nextResponder];
}

- (void)enableNormalVideoGestures:(BOOL)enable
{
    [_tapRecognizer setEnabled:enable];
    [_swipeRecognizerUp setEnabled:enable];
    [_swipeRecognizerDown setEnabled:enable];
    [_swipeRecognizerLeft setEnabled:enable];
    [_swipeRecognizerRight setEnabled:enable];
}

#pragma mark - controls

- (IBAction)closePlayback:(id)sender
{
    LOCKCHECK;
    _playbackWillClose = YES;
    [_vpc stopPlayback];
}

- (IBAction)minimizePlayback:(id)sender
{
    LOCKCHECK;
    [[UIApplication sharedApplication] sendAction:@selector(closeFullscreenPlayback) to:nil from:self forEvent:nil];
}

- (IBAction)positionSliderAction:(UISlider *)sender
{
    LOCKCHECK;

    /* we need to limit the number of events sent by the slider, since otherwise, the user
     * wouldn't see the I-frames when seeking on current mobile devices. This isn't a problem
     * within the Simulator, but especially on older ARMv7 devices, it's clearly noticeable. */
    [self performSelector:@selector(_setPositionForReal) withObject:nil afterDelay:0.3];
    if (_mediaDuration > 0) {
        VLCTime *newPosition = [VLCTime timeWithInt:(int)(sender.value * _mediaDuration)];
        [self.timeNavigationTitleView.timeDisplayButton setTitle:newPosition.stringValue forState:UIControlStateNormal];
        [self.timeNavigationTitleView setNeedsLayout];
        self.timeNavigationTitleView.timeDisplayButton.accessibilityLabel = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"PLAYBACK_POSITION", nil), newPosition.stringValue];
        _positionSet = NO;
    }
    [self _resetIdleTimer];
}

- (void)_setPositionForReal
{
    if (!_positionSet) {
        _vpc.mediaPlayer.position = self.timeNavigationTitleView.positionSlider.value;
        [_vpc setNeedsMetadataUpdate];
        _positionSet = YES;
    }
}

- (IBAction)positionSliderTouchDown:(id)sender
{
    LOCKCHECK;

    [self _updateScrubLabel];
    self.scrubIndicatorView.hidden = NO;
    _isScrubbing = YES;
}

- (IBAction)positionSliderTouchUp:(id)sender
{
    LOCKCHECK;

    self.scrubIndicatorView.hidden = YES;
    _isScrubbing = NO;
}

- (void)_updateScrubLabel
{
    float speed = self.timeNavigationTitleView.positionSlider.scrubbingSpeed;
    if (speed == 1.)
        self.currentScrubSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_HIGH", nil);
    else if (speed == .5)
        self.currentScrubSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_HALF", nil);
    else if (speed == .25)
        self.currentScrubSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_QUARTER", nil);
    else
        self.currentScrubSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_FINE", nil);

    [self _resetIdleTimer];
}

- (IBAction)positionSliderDrag:(id)sender
{
    LOCKCHECK;

    [self _updateScrubLabel];
}

- (void)volumeSliderAction:(id)sender
{
    LOCKCHECK;

    [self _resetIdleTimer];
}

- (void)updateTimeDisplayButton
{
    VLCMediaPlayer *mediaPlayer = _vpc.mediaPlayer;
    UIButton *timeDisplayButton = self.timeNavigationTitleView.timeDisplayButton;
    if (_displayRemainingTime)
        [timeDisplayButton setTitle:[[mediaPlayer remainingTime] stringValue] forState:UIControlStateNormal];
    else
        [timeDisplayButton setTitle:[[mediaPlayer time] stringValue] forState:UIControlStateNormal];
    [self.timeNavigationTitleView setNeedsLayout];
}

- (void)updateSleepTimerButton
{
    NSMutableString *title = [NSMutableString stringWithString:NSLocalizedString(@"BUTTON_SLEEP_TIMER", nil)];
    if (_vpc.sleepTimer != nil && _vpc.sleepTimer.valid) {
        int remainSeconds = (int)[_vpc.sleepTimer.fireDate timeIntervalSinceNow];
        int hour = remainSeconds / 3600;
        int minute = (remainSeconds - hour * 3600) / 60;
        int second = remainSeconds % 60;
        [title appendFormat:@"  %02d:%02d:%02d", hour, minute, second];
    } else {
        [_sleepCountDownTimer invalidate];
    }

    [_sleepTimerButton setTitle:title forState:UIControlStateNormal];
}

#pragma mark - playback controller delegation

- (void)playbackPositionUpdated:(VLCPlaybackController *)controller
{
    VLCMediaPlayer *mediaPlayer = controller.mediaPlayer;
    if (!_isScrubbing) {
        self.timeNavigationTitleView.positionSlider.value = [mediaPlayer position];
    }

    [self updateTimeDisplayButton];
}

- (void)prepareForMediaPlayback:(VLCPlaybackController *)controller
{
    self.trackNameLabel.text = self.artistNameLabel.text = self.albumNameLabel.text = @"";
    self.timeNavigationTitleView.positionSlider.value = 0.;
    [self.timeNavigationTitleView.timeDisplayButton setTitle:@"" forState:UIControlStateNormal];
    self.timeNavigationTitleView.timeDisplayButton.accessibilityLabel = @"";
    if (![[UIDevice currentDevice] VLCHasExternalDisplay])
        self.brightnessSlider.value = [UIScreen mainScreen].brightness * 2.;
    [_equalizerView reloadData];

    double playbackRate = controller.playbackRate;
    self.playbackSpeedSlider.value = log2(playbackRate);
    self.playbackSpeedIndicator.text = [NSString stringWithFormat:@"%.2fx", playbackRate];

    float audioDelay = controller.audioDelay;
    self.audioDelaySlider.value = audioDelay;
    self.audioDelayIndicator.text = [NSString stringWithFormat:@"%1.2f s", audioDelay];

    float subtitleDelay = controller.subtitleDelay;
    self.spuDelaySlider.value = subtitleDelay;
    self.spuDelayIndicator.text = [NSString stringWithFormat:@"%1.00f s", subtitleDelay];

    [self _resetIdleTimer];
}

- (void)playbackDidStop:(NSNotification *)notification
{
    [self minimizePlayback:nil];
}

- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
currentMediaHasTrackToChooseFrom:(BOOL)currentMediaHasTrackToChooseFrom
        currentMediaHasChapters:(BOOL)currentMediaHasChapters
          forPlaybackController:(VLCPlaybackController *)controller
{
    if (currentState == VLCMediaPlayerStateBuffering)
        _mediaDuration = controller.mediaDuration;

    if (currentState == VLCMediaPlayerStateError)
        [self.statusLabel showStatusMessage:NSLocalizedString(@"PLAYBACK_FAILED", nil)];

    [_controllerPanel updateButtons];

    _multiSelectionView.mediaHasChapters = currentMediaHasChapters;
}

- (void)showStatusMessage:(NSString *)statusMessage forPlaybackController:(VLCPlaybackController *)controller
{
    [self.statusLabel showStatusMessage:statusMessage];
}

- (void)hideShowAspectratioButton:(BOOL)hide
{
    [UIView animateWithDuration:.3
                     animations:^{
                         self.widthConstraint.constant = hide ? 0 : 30;
                         self.timeNavigationTitleView.aspectRatioButton.hidden = hide;
                     }];
}

- (void)displayMetadataForPlaybackController:(VLCPlaybackController *)controller
                                       title:(NSString *)title
                                     artwork:(UIImage *)artwork
                                      artist:(NSString *)artist
                                       album:(NSString *)album
                                   audioOnly:(BOOL)audioOnly
{
    if (!_viewAppeared)
        return;

    self.trackNameLabel.text = title;
    self.artworkImageView.image = artwork;
    if (!artwork) {
        self.artistNameLabel.text = artist;
        self.albumNameLabel.text = album;
    } else
        self.artistNameLabel.text = self.albumNameLabel.text = nil;

    [self hideShowAspectratioButton:audioOnly];
    [_controllerPanel updateButtons];
    
    _audioOnly = audioOnly;
}

- (IBAction)playPause
{
    LOCKCHECK;

    [_vpc playPause];
}

- (IBAction)forward:(id)sender
{
    LOCKCHECK;
    [_vpc forward];
}

- (IBAction)backward:(id)sender
{
    LOCKCHECK;

    [_vpc backward];
}

- (IBAction)switchTrack:(id)sender
{
    LOCKCHECK;

    if (_trackSelectorContainer.hidden == YES || _switchingTracksNotChapters == NO) {
        _switchingTracksNotChapters = YES;

        _trackSelectorContainer.hidden = NO;
        _trackSelectorContainer.alpha = 1.;

        [_trackSelectorTableView reloadData];

        if (_equalizerView.hidden == NO)
            _equalizerView.hidden = YES;

        if (!_playbackSpeedViewHidden)
            self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            if (!_controlsHidden) {
                self.controllerPanel.hidden = _controlsHidden = YES;
                self.navigationController.navigationBar.hidden = YES;
            }
        }

        self.videoFilterView.hidden = _videoFiltersHidden = YES;

        for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers)
            [recognizer setEnabled:NO];
        [_tapOnVideoRecognizer setEnabled:YES];

    } else {
        _trackSelectorContainer.hidden = YES;
        _switchingTracksNotChapters = NO;
    }
}

- (IBAction)toggleTimeDisplay:(id)sender
{
    LOCKCHECK;

    _displayRemainingTime = !_displayRemainingTime;
    [self updateTimeDisplayButton];

    [self _resetIdleTimer];
}

- (IBAction)sleepTimer:(id)sender
{
    if (!_playbackSpeedViewHidden)
        self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (!_controlsHidden) {
            self.controllerPanel.hidden = _controlsHidden = YES;
        }
    }

    self.videoFilterView.hidden = _videoFiltersHidden = YES;
    _sleepTimerContainer.alpha = 1.;
    _sleepTimerContainer.hidden = NO;
}

- (IBAction)sleepTimerCancel:(id)sender
{
    NSTimer *sleepTimer = [_vpc sleepTimer];

    if (sleepTimer) {
        [sleepTimer invalidate];
        sleepTimer = nil;
    }
    [self.statusLabel showStatusMessage:NSLocalizedString(@"SLEEP_TIMER_UPDATED", nil)];
    [self setControlsHidden:YES animated:YES];
}

- (IBAction)sleepTimerAction:(id)sender
{
    [_vpc scheduleSleepTimerWithInterval:_sleepTimeDatePicker.countDownDuration];

    if (_sleepCountDownTimer == nil || _sleepCountDownTimer.valid == NO) {
        _sleepCountDownTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                   target:self
                                                                 selector:@selector(updateSleepTimerButton)
                                                                 userInfo:nil
                                                                  repeats:YES];
    }
    [self.statusLabel showStatusMessage:NSLocalizedString(@"SLEEP_TIMER_UPDATED", nil)];
    [self setControlsHidden:YES animated:YES];
}

- (void)moreActions:(UIButton *)sender
{
    if (_multiSelectionView.hidden == NO) {
        [UIView animateWithDuration:.3
                         animations:^{
                             _multiSelectionView.hidden = YES;
                         }
                         completion:^(BOOL finished){
                         }];
        return;
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            _multiSelectionView.showsEqualizer = YES;
        } else {
            _multiSelectionView.showsEqualizer = NO;
        }
    }

    CGRect workFrame = _multiSelectionView.frame;
    workFrame.size = [_multiSelectionView proposedDisplaySize];
    workFrame.origin.x = CGRectGetMaxX(sender.frame) - workFrame.size.width;

    _multiSelectionView.alpha = 1.0f;

    /* animate */
    _multiSelectionView.frame = CGRectMake(workFrame.origin.x, workFrame.origin.y + workFrame.size.height, workFrame.size.width, 0.);
    [UIView animateWithDuration:.3
                     animations:^{
                         _multiSelectionView.frame = workFrame;
                         _multiSelectionView.hidden = NO;
                     }
                     completion:^(BOOL finished){
                     }];
    [self _resetIdleTimer];
}

#pragma mark - multi-select delegation

- (void)toggleUILock
{
    _interfaceIsLocked = !_interfaceIsLocked;

    _multiSelectionView.displayLock = _interfaceIsLocked;
}

- (void)toggleEqualizer
{
    LOCKCHECK;

    if (_equalizerView.hidden) {
        if (!_playbackSpeedViewHidden)
            self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            if (!_controlsHidden) {
                self.controllerPanel.hidden = _controlsHidden = YES;
                self.navigationController.navigationBar.hidden = YES;
            }
        }

        _trackSelectorContainer.hidden = YES;

        self.videoFilterView.hidden = _videoFiltersHidden = YES;
        _equalizerView.alpha = 1.;
        _equalizerView.hidden = NO;
    } else
        _equalizerView.hidden = YES;
}

- (void)toggleChapterAndTitleSelector
{
    LOCKCHECK;

    if (_trackSelectorContainer.hidden == YES || _switchingTracksNotChapters == YES) {
        _switchingTracksNotChapters = NO;

        [_trackSelectorTableView reloadData];
        _trackSelectorContainer.hidden = NO;
        _trackSelectorContainer.alpha = 1.;

        if (_equalizerView.hidden == NO)
            _equalizerView.hidden = YES;

        if (!_playbackSpeedViewHidden)
            self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            if (!_controlsHidden) {
                self.controllerPanel.hidden = _controlsHidden = YES;
            }
        }

        _sleepTimerContainer.hidden = YES;

        self.videoFilterView.hidden = _videoFiltersHidden = YES;
    } else {
        _trackSelectorContainer.hidden = YES;
    }
}

- (void)toggleRepeatMode
{
    LOCKCHECK;

    VLCMediaListPlayer *listPlayer = _vpc.listPlayer;
    VLCRepeatMode nextRepeatMode = VLCDoNotRepeat;
    switch (listPlayer.repeatMode) {
        case VLCDoNotRepeat:
            nextRepeatMode = VLCRepeatCurrentItem;
            break;
        case VLCRepeatCurrentItem:
            nextRepeatMode = VLCRepeatAllItems;
            break;
        default:
            nextRepeatMode = VLCDoNotRepeat;
            break;
    }
    listPlayer.repeatMode = nextRepeatMode;
    _multiSelectionView.repeatMode = nextRepeatMode;
}

- (void)toggleShuffleMode
{
    LOCKCHECK;
    _vpc.shuffleMode = !_vpc.isShuffleMode;
    _multiSelectionView.shuffleMode = _vpc.isShuffleMode;
}

- (void)hideMenu
{
    [UIView animateWithDuration:.2
                     animations:^{
                         _multiSelectionView.hidden = YES;
                     }
                     completion:^(BOOL finished){
                     }];
    [self _resetIdleTimer];
}

#pragma mark - track selector table view
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger ret = 0;
    VLCMediaPlayer *mediaPlayer = _vpc.mediaPlayer;

    if (_switchingTracksNotChapters == YES) {
        if (mediaPlayer.audioTrackIndexes.count > 2)
            ret++;

        if (mediaPlayer.videoSubTitlesIndexes.count > 1)
            ret++;
    } else {
        if ([mediaPlayer numberOfTitles] > 1)
            ret++;

        if ([mediaPlayer numberOfChaptersForTitle:mediaPlayer.currentTitleIndex] > 1)
            ret++;
    }

    return ret;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:TRACK_SELECTOR_TABLEVIEW_SECTIONHEADER];

    if (!view)
        view = [[VLCTrackSelectorHeaderView alloc] initWithReuseIdentifier:TRACK_SELECTOR_TABLEVIEW_SECTIONHEADER];

    return view;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    VLCMediaPlayer *mediaPlayer = _vpc.mediaPlayer;

    if (_switchingTracksNotChapters == YES) {
        if (mediaPlayer.audioTrackIndexes.count > 2 && section == 0)
            return NSLocalizedString(@"CHOOSE_AUDIO_TRACK", nil);

        if (mediaPlayer.videoSubTitlesIndexes.count > 1)
            return NSLocalizedString(@"CHOOSE_SUBTITLE_TRACK", nil);
    } else {
        if ([mediaPlayer numberOfTitles] > 1 && section == 0)
            return NSLocalizedString(@"CHOOSE_TITLE", nil);

        if ([mediaPlayer numberOfChaptersForTitle:mediaPlayer.currentTitleIndex] > 1)
            return NSLocalizedString(@"CHOOSE_CHAPTER", nil);
    }

    return @"unknown track type";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCTrackSelectorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TRACK_SELECTOR_TABLEVIEW_CELL];

    if (!cell)
        cell = [[VLCTrackSelectorTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TRACK_SELECTOR_TABLEVIEW_CELL];

    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    VLCMediaPlayer *mediaPlayer = _vpc.mediaPlayer;
    BOOL cellShowsCurrentTrack = NO;

    if (_switchingTracksNotChapters == YES) {
        NSArray *indexArray;
        NSString *trackName;
        if ([mediaPlayer numberOfAudioTracks] > 2 && section == 0) {
            indexArray = mediaPlayer.audioTrackIndexes;

            if ([indexArray indexOfObject:[NSNumber numberWithInt:mediaPlayer.currentAudioTrackIndex]] == row)
                cellShowsCurrentTrack = YES;

            NSArray *audioTrackNames = mediaPlayer.audioTrackNames;
            if (row < audioTrackNames.count) {
                trackName = audioTrackNames[row];
            }
        } else {
            indexArray = mediaPlayer.videoSubTitlesIndexes;

            if ([indexArray indexOfObject:[NSNumber numberWithInt:mediaPlayer.currentVideoSubTitleIndex]] == row)
                cellShowsCurrentTrack = YES;

            NSArray *videoSubtitlesNames = mediaPlayer.videoSubTitlesNames;
            if (row < videoSubtitlesNames.count) {
                trackName = mediaPlayer.videoSubTitlesNames[row];
            }
        }

        if (trackName != nil) {
            if ([trackName isEqualToString:@"Disable"])
                cell.textLabel.text = NSLocalizedString(@"DISABLE_LABEL", nil);
            else
                cell.textLabel.text = trackName;
        }
    } else {
        if ([mediaPlayer numberOfTitles] > 1 && section == 0) {
            NSArray *titleDescriptions = mediaPlayer.titleDescriptions;
            if (row < titleDescriptions.count) {
                NSDictionary *description = titleDescriptions[row];
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", description[VLCTitleDescriptionName], [[VLCTime timeWithNumber:description[VLCTitleDescriptionDuration]] stringValue]];
            }

            if (row == mediaPlayer.currentTitleIndex)
                cellShowsCurrentTrack = YES;
        } else {
            NSArray *chapterDescriptions = [mediaPlayer chapterDescriptionsOfTitle:mediaPlayer.currentTitleIndex];
            if (row < chapterDescriptions.count) {
                NSDictionary *description = chapterDescriptions[row];
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", description[VLCChapterDescriptionName], [[VLCTime timeWithNumber:description[VLCChapterDescriptionDuration]] stringValue]];
            }

            if (row == mediaPlayer.currentChapterIndex)
                cellShowsCurrentTrack = YES;
        }
    }
    [cell setShowsCurrentTrack:cellShowsCurrentTrack];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    VLCMediaPlayer *mediaPlayer = _vpc.mediaPlayer;

    if (_switchingTracksNotChapters == YES) {
        NSInteger audioTrackCount = mediaPlayer.audioTrackIndexes.count;

        if (audioTrackCount > 2 && section == 0)
            return audioTrackCount;

        return mediaPlayer.videoSubTitlesIndexes.count;
    } else {
        if ([mediaPlayer numberOfTitles] > 1 && section == 0)
            return [mediaPlayer numberOfTitles];
        else
            return [mediaPlayer numberOfChaptersForTitle:mediaPlayer.currentTitleIndex];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSInteger index = indexPath.row;
    VLCMediaPlayer *mediaPlayer = _vpc.mediaPlayer;

    if (_switchingTracksNotChapters == YES) {
        NSArray *indexArray;
        if (mediaPlayer.audioTrackIndexes.count > 2 && indexPath.section == 0) {
            indexArray = mediaPlayer.audioTrackIndexes;
            if (index <= indexArray.count)
                mediaPlayer.currentAudioTrackIndex = [indexArray[index] intValue];

        } else {
            indexArray = mediaPlayer.videoSubTitlesIndexes;
            if (index <= indexArray.count)
                mediaPlayer.currentVideoSubTitleIndex = [indexArray[index] intValue];
        }
    } else {
        if ([mediaPlayer numberOfTitles] > 1 && indexPath.section == 0)
            mediaPlayer.currentTitleIndex = (int)index;
        else
            mediaPlayer.currentChapterIndex = (int)index;
    }

    CGFloat alpha = 0.0f;
    _trackSelectorContainer.alpha = 1.0f;

    void (^animationBlock)() = ^() {
        _trackSelectorContainer.alpha = alpha;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers)
            [recognizer setEnabled:YES];
        _trackSelectorContainer.hidden = YES;
    };

    NSTimeInterval animationDuration = .3;
    [UIView animateWithDuration:animationDuration animations:animationBlock completion:completionBlock];
}

#pragma mark - multi-touch gestures

- (void)togglePlayPause
{
    LOCKCHECK;

    if (!_playPauseGestureEnabled)
        return;

    [_vpc.mediaPlayer isPlaying] ? [_vpc.listPlayer pause] : [_vpc.listPlayer play];
    if (_controlsHidden)
        [self setControlsHidden:NO animated:YES];
}

- (VLCPanType)detectPanTypeForPan:(UIPanGestureRecognizer*)panRecognizer
{
    NSString *deviceType = [[UIDevice currentDevice] model];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    CGFloat windowWidth = CGRectGetWidth(window.bounds);
    CGPoint location = [panRecognizer locationInView:window];

    VLCPanType panType = VLCPanTypeVolume; // default or right side of the screen
    if (location.x < windowWidth / 2)
        panType = VLCPanTypeBrightness;

    // only check for seeking gesture if on iPad , will overwrite last statements if true
    if ([deviceType isEqualToString:@"iPad"]) {
        if (location.y < 110)
            panType = VLCPanTypeSeek;
    }

    return panType;
}

- (void)panRecognized:(UIPanGestureRecognizer*)panRecognizer
{
    LOCKCHECK;

    CGFloat panDirectionX = [panRecognizer velocityInView:self.view].x;
    CGFloat panDirectionY = [panRecognizer velocityInView:self.view].y;

    if (panRecognizer.state == UIGestureRecognizerStateBegan) {
        _currentPanType = _mediaHasProjection ? VLCPanTypeProjection : [self detectPanTypeForPan:panRecognizer];
    }

    if (_currentPanType == VLCPanTypeSeek) {
        if (!_seekGestureEnabled)
            return;
        VLCMediaPlayer *mediaPlayer = _vpc.mediaPlayer;
        double timeRemainingDouble = (-mediaPlayer.remainingTime.intValue*0.001);
        int timeRemaining = timeRemainingDouble;

        if (panDirectionX > 0) {
            if (timeRemaining > 2 ) // to not go outside duration , video will stop
                [mediaPlayer jumpForward:1];
        } else
            [mediaPlayer jumpBackward:1];
    } else if (_currentPanType == VLCPanTypeVolume) {
        if (!_volumeGestureEnabled)
            return;
        MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        // there is no replacement for .volume which we want to use since Apple's susggestion is to not use their overlays
        // but switch to the volume slider exclusively. meh.
        if (panDirectionY > 0)
            musicPlayer.volume -= 0.01;
        else
            musicPlayer.volume += 0.01;
#pragma clang diagnostic pop
    } else if (_currentPanType == VLCPanTypeBrightness) {
        if (!_brightnessGestureEnabled)
            return;
        CGFloat brightness = [UIScreen mainScreen].brightness;

        if (panDirectionY > 0)
            brightness = brightness - 0.01;
        else
            brightness = brightness + 0.01;

        // Sanity check since -[UIScreen brightness] does not go by 0.01 steps
        if (brightness > 1.0)
            brightness = 1.0;
        else if (brightness < 0.0)
            brightness = 0.0;

        NSAssert(brightness >= 0 && brightness <= 1, @"Brightness must be within 0 and 1 (it is %f)", brightness);

        [[UIScreen mainScreen] setBrightness:brightness];
        self.brightnessSlider.value = brightness * 2.;

        NSString *brightnessHUD = [NSString stringWithFormat:@"%@: %@ %%", NSLocalizedString(@"VFILTER_BRIGHTNESS", nil), [[[NSString stringWithFormat:@"%f",(brightness*100)] componentsSeparatedByString:@"."] objectAtIndex:0]];
        [self.statusLabel showStatusMessage:brightnessHUD];
    } else if (_currentPanType == VLCPanTypeProjection) {

        CGPoint tmp = [panRecognizer locationInView:self.view];
        CGFloat changeX = 0.f;
        CGFloat changeY = 0.f;

        if (_saveLocation.x != -1.f && _saveLocation.y != -1.f) {
            changeX = tmp.x - _saveLocation.x;
            changeY = tmp.y - _saveLocation.y;
        }

        _saveLocation = [panRecognizer locationInView:self.view];

        //screenSizePixel width is used twice to get a constant speed on the movement.
        CGFloat yaw = _fov * -changeX / _screenSizePixel.width;
        CGFloat pitch = _fov * -changeY / _screenSizePixel.width;

        [_vpc updateViewpoint:yaw pitch:pitch roll:0 fov:0 absolute:NO];
    }

    if (panRecognizer.state == UIGestureRecognizerStateEnded) {
        _currentPanType = VLCPanTypeNone;

        //Invalidate saved location when the gesture is ended
        if (_mediaHasProjection)
            _saveLocation = CGPointMake(-1.f, -1.f);
        if ([_vpc.mediaPlayer isPlaying])
            [_vpc.listPlayer play];
    }
}

- (void)swipeRecognized:(UISwipeGestureRecognizer*)swipeRecognizer
{
    LOCKCHECK;

    if (!_seekGestureEnabled)
        return;

    NSString * hudString = @" ";
    VLCMediaPlayer *mediaPlayer = _vpc.mediaPlayer;
    int swipeForwardDuration = (_variableJumpDurationEnabled) ? ((int)(_mediaDuration*0.001*0.05)) : FORWARD_SWIPE_DURATION;
    int swipeBackwardDuration = (_variableJumpDurationEnabled) ? ((int)(_mediaDuration*0.001*0.05)) : BACKWARD_SWIPE_DURATION;

    if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        double timeRemainingDouble = (-mediaPlayer.remainingTime.intValue*0.001);
        int timeRemaining = timeRemainingDouble;

        if (swipeForwardDuration < timeRemaining) {
            if (swipeForwardDuration < 1)
                swipeForwardDuration = 1;
            [mediaPlayer jumpForward:swipeForwardDuration];
            hudString = [NSString stringWithFormat:@"⇒ %is", swipeForwardDuration];
        } else {
            [mediaPlayer jumpForward:(timeRemaining - 5)];
            hudString = [NSString stringWithFormat:@"⇒ %is",(timeRemaining - 5)];
        }
    }
    else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        [mediaPlayer jumpBackward:swipeBackwardDuration];
        hudString = [NSString stringWithFormat:@"⇐ %is",swipeBackwardDuration];
    }else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionUp) {
        [self backward:self];
    }
    else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionDown) {
        [self forward:self];
    }

    if (swipeRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([mediaPlayer isPlaying])
            [_vpc.listPlayer play];

        [self.statusLabel showStatusMessage:hudString];
    }
}

- (void)tapToSeekRecognized:(UITapGestureRecognizer *)tapRecognizer
{
    LOCKCHECK;

    if (!_seekGestureEnabled)
        return;

    CGFloat screenHalf;
    CGFloat tmpPosition;
    CGSize size = self.view.frame.size;
    CGPoint tapPosition = [tapRecognizer locationInView:self.view];

    screenHalf = size.width / 2;
    tmpPosition = tapPosition.x;

    //Handling seek reset if tap orientation changes.
    if (tmpPosition < screenHalf) {
        _numberOfTapSeek = _previousJumpState == VLCMovieJumpStateForward ? -1 : _numberOfTapSeek - 1;
    } else {
        _numberOfTapSeek = _previousJumpState == VLCMovieJumpStateBackward ? 1 : _numberOfTapSeek + 1;
    }

    _isTapSeeking = YES;
    [self _seekFromTap];
}

- (void)equalizerViewReceivedUserInput
{
    [self _resetIdleTimer];
}

#pragma mark - Video Filter UI

- (IBAction)videoFilterToggle:(id)sender
{
    LOCKCHECK;

    if (!_playbackSpeedViewHidden)
        self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (!_controlsHidden) {
            self.controllerPanel.hidden = _controlsHidden = YES;
        }
    }

    self.videoFilterView.hidden = !_videoFiltersHidden;
    _videoFiltersHidden = self.videoFilterView.hidden;
}

- (IBAction)videoFilterSliderAction:(id)sender
{
    VLCMediaPlayer *mediaPlayer = _vpc.mediaPlayer;

    if (sender == self.hueSlider)
        mediaPlayer.hue = (int)self.hueSlider.value;
    else if (sender == self.contrastSlider)
        mediaPlayer.contrast = self.contrastSlider.value;
    else if (sender == self.brightnessSlider) {
        if ([[UIDevice currentDevice] VLCHasExternalDisplay])
            mediaPlayer.brightness = self.brightnessSlider.value;
        else
            [[UIScreen mainScreen] setBrightness:(self.brightnessSlider.value / 2.)];
    } else if (sender == self.saturationSlider)
        mediaPlayer.saturation = self.saturationSlider.value;
    else if (sender == self.gammaSlider)
        mediaPlayer.gamma = self.gammaSlider.value;
    else if (sender == self.resetVideoFilterButton) {
        mediaPlayer.hue = self.hueSlider.value = 0.;
        mediaPlayer.contrast = self.contrastSlider.value = 1.;
        mediaPlayer.brightness = self.brightnessSlider.value = 1.;
        [[UIScreen mainScreen] setBrightness:(self.brightnessSlider.value / 2.)];
        mediaPlayer.saturation = self.saturationSlider.value = 1.;
        mediaPlayer.gamma = self.gammaSlider.value = 1.;
    } else
        APLog(@"unknown sender for videoFilterSliderAction");
    [self _resetIdleTimer];
}

- (void)screenBrightnessChanged:(NSNotification *)notification
{
    if (notification)
        self.brightnessSlider.value = [(UIScreen *)notification.object brightness] * 2.;
    else if (![[UIDevice currentDevice] VLCHasExternalDisplay])
        self.brightnessSlider.value = [(UIScreen *)[[UIScreen screens] firstObject] brightness] * 2.;
}

- (void)appBecameActive:(NSNotification *)aNotification
{
    VLCPlayerDisplayController *pdc = [VLCPlayerDisplayController sharedInstance];
    if (pdc.displayMode == VLCPlayerDisplayControllerDisplayModeFullscreen) {
        [_vpc recoverDisplayedMetadata];
        if (_vpc.videoOutputView != self.movieView) {
            _vpc.videoOutputView = self.movieView;
        }
    }
}

#pragma mark - playback view
- (IBAction)playbackSliderAction:(UISlider *)sender
{
    LOCKCHECK;

    if (sender == _playbackSpeedSlider) {
        double speed = exp2(sender.value);
        _vpc.playbackRate = speed;
        self.playbackSpeedIndicator.text = [NSString stringWithFormat:@"%.2fx", speed];
    } else if (sender == _audioDelaySlider) {
        double delay = sender.value;
        _vpc.audioDelay = delay;
        _audioDelayIndicator.text = [NSString stringWithFormat:@"%1.2f s", delay];
    } else if (sender == _spuDelaySlider) {
        double delay = sender.value;
        _vpc.subtitleDelay = delay;
        _spuDelayIndicator.text = [NSString stringWithFormat:@"%1.00f s", delay];
    }

    [self _resetIdleTimer];
}

- (IBAction)videoDimensionAction:(id)sender
{
    if (sender == self.timeNavigationTitleView.aspectRatioButton) {
        [[VLCPlaybackController sharedInstance] switchAspectRatio];
    }
}

- (IBAction)showPlaybackSpeedView {
    LOCKCHECK;

    if (!_videoFiltersHidden)
        self.videoFilterView.hidden = _videoFiltersHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    self.playbackSpeedView.hidden = !_playbackSpeedViewHidden;
    _playbackSpeedViewHidden = self.playbackSpeedView.hidden;
    [self _resetIdleTimer];
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}

#pragma mark - autorotation

- (BOOL)rotationIsDisabled
{
    return _interfaceIsLocked;
}

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
           || toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

// < iOS 8
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (self.artworkImageView.image)
        self.trackNameLabel.hidden = UIInterfaceOrientationIsLandscape(toInterfaceOrientation);

    if (!_equalizerView.hidden)
        _equalizerView.hidden = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (_vpc.activePlaybackSession && _controlsHidden)
        [self setControlsHidden:NO animated:YES];
}

// >= iOS 8
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {

        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                if (self.artworkImageView.image)
                    self.trackNameLabel.hidden = YES;

                if (!_equalizerView.hidden)
                    _equalizerView.hidden = YES;
        } completion:nil];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if (_vpc.activePlaybackSession && _controlsHidden)
        [self setControlsHidden:NO animated:YES];
}

#pragma mark - External Display

- (void)showOnExternalDisplay
{
    UIScreen *screen = [UIScreen screens][1];
    screen.overscanCompensation = UIScreenOverscanCompensationInsetApplicationFrame;

    self.externalWindow = [[UIWindow alloc] initWithFrame:screen.bounds];

    UIViewController *controller = [[VLCExternalDisplayController alloc] init];
    self.externalWindow.rootViewController = controller;
    [controller.view addSubview:_movieView];
    controller.view.frame = screen.bounds;
    _movieView.frame = screen.bounds;

    self.playingExternallyView.hidden = NO;
    self.externalWindow.screen = screen;
    self.externalWindow.hidden = NO;
}

- (void)hideFromExternalDisplay
{
    [self.view addSubview:_movieView];
    [self.view sendSubviewToBack:_movieView];
    _movieView.frame = self.view.frame;

    self.playingExternallyView.hidden = YES;
    self.externalWindow.hidden = YES;
    self.externalWindow = nil;
}

- (void)handleExternalScreenDidConnect:(NSNotification *)notification
{
    [self showOnExternalDisplay];
}

- (void)handleExternalScreenDidDisconnect:(NSNotification *)notification
{
    [self hideFromExternalDisplay];
}

@end
