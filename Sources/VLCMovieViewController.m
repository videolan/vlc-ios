/*****************************************************************************
 * VLCMovieViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2018 VideoLAN. All rights reserved.
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
 *          Andrew Breckenridge <asbreckenridge # me dot com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMovieViewController.h"
#import "VLCEqualizerView.h"
#import "VLCMultiSelectionMenuView.h"
#import "VLCPlaybackService.h"
#import "VLCTimeNavigationTitleView.h"
#import "VLCAppDelegate.h"
#import "VLCStatusLabel.h"
#import "VLCMovieViewControlPanelView.h"
#import "VLCSlider.h"
#import <AVKit/AVKit.h>

#import "VLCTrackSelectorView.h"
#import "VLCMetadata.h"
#import "UIDevice+VLC.h"
#import "VLC-Swift.h"

#define FORWARD_SWIPE_DURATION 30
#define BACKWARD_SWIPE_DURATION 10
#define SHORT_JUMP_DURATION 10

#define ZOOM_SENSITIVITY 5.f
#define DEFAULT_FOV 80.f
#define MAX_FOV 150.f
#define MIN_FOV 20.f
#define NEW_UI 0

typedef NS_ENUM(NSInteger, VLCPanType) {
  VLCPanTypeNone,
  VLCPanTypeBrightness,
  VLCPanTypeSeek,
  VLCPanTypeVolume,
  VLCPanTypeProjection
};

@interface VLCMovieViewController () <UIGestureRecognizerDelegate, VLCMultiSelectionViewDelegate, VLCEqualizerViewUIDelegate, VLCPlaybackServiceDelegate, VLCDeviceMotionDelegate, VLCRendererDiscovererManagerDelegate, PlaybackSpeedViewDelegate, VLCVideoOptionsControlBarDelegate, VLCMediaMoreOptionsActionSheetDelegate, VLCMediaNavigationBarDelegate>
{
    BOOL _controlsHidden;
    BOOL _videoFiltersHidden;
    BOOL _playbackSpeedViewHidden;

    NSTimer *_idleTimer;

    BOOL _viewAppeared;
    BOOL _displayRemainingTime;
    BOOL _positionSet;
    BOOL _isScrubbing;
    BOOL _interfaceIsLocked;
    BOOL _audioOnly;

    BOOL _volumeGestureEnabled;
    BOOL _playPauseGestureEnabled;
    BOOL _brightnessGestureEnabled;
    BOOL _swipeSeekGestureEnabled;
    BOOL _closeGestureEnabled;
    BOOL _variableJumpDurationEnabled;
    BOOL _playbackWillClose;
    BOOL _isTapSeeking;
    VLCMovieJumpState _previousJumpState;
    VLCMediaPlayerState _previousPlayerStateWasPaused;

    UIPinchGestureRecognizer *_pinchRecognizer;
    VLCPanType _currentPanType;
    UIPanGestureRecognizer *_panRecognizer;
    UISwipeGestureRecognizer *_swipeRecognizerLeft;
    UISwipeGestureRecognizer *_swipeRecognizerRight;
    UISwipeGestureRecognizer *_swipeRecognizerUp;
    UISwipeGestureRecognizer *_swipeRecognizerDown;
    UITapGestureRecognizer *_tapRecognizer;
    UITapGestureRecognizer *_tapOnVideoRecognizer;
    UITapGestureRecognizer *_doubleTapRecognizer;

    UIButton *_doneButton;

    VLCTrackSelectorView *_trackSelectorContainer;
    VLCEqualizerView *_equalizerView;
    
    UIStackView *_navigationBarStackView;
    VLCMultiSelectionMenuView *_multiSelectionView;
    
    VLCVideoOptionsControlBar *_videoOptionsControlBar;
    VLCMediaMoreOptionsActionSheet *_moreOptionsActionSheet;
    VLCMediaNavigationBar *_mediaNavigationBar;

    VLCPlaybackService *_vpc;

    UIView *_sleepTimerContainer;
    UIDatePicker *_sleepTimeDatePicker;

    NSInteger _mediaDuration;
    NSInteger _numberOfTapSeek;

    VLCDeviceMotion *_deviceMotion;
    CGFloat _fov;
    CGPoint _saveLocation;
    CGSize _screenPixelSize;
    UIInterfaceOrientation _lockedOrientation;
    UIButton *_rendererButton;

    NSLayoutConstraint *_movieViewLeadingConstraint;
    NSLayoutConstraint *_movieViewTrailingConstraint;
}
@property (nonatomic, strong) VLCMovieViewControlPanelView *controllerPanel;
@property (nonatomic, strong) VLCServices *services;
@property (nonatomic, strong) VLCTimeNavigationTitleView *timeNavigationTitleView;
@property (nonatomic, strong) IBOutlet PlayingExternallyView *playingExternalView;
@property (nonatomic, strong) IBOutlet PlaybackSpeedView *playbackSpeedView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *scrubViewTopConstraint;

@end

@implementation VLCMovieViewController

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = @{kVLCShowRemainingTime : @(YES)};
    [defaults registerDefaults:appDefaults];
}

- (instancetype)initWithServices:(VLCServices *)services
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _services = services;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _vpc = [VLCPlaybackService sharedInstance];

    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;

    self.videoFilterView.hidden = YES;
    _videoFiltersHidden = YES;
    _hueLabel.text = NSLocalizedString(@"VFILTER_HUE", nil);
    _hueSlider.accessibilityLabel = _hueLabel.text;
    _contrastLabel.text = NSLocalizedString(@"VFILTER_CONTRAST", nil);
    _contrastSlider.accessibilityLabel = _contrastLabel.text;
    _brightnessLabel.text = NSLocalizedString(@"VFILTER_BRIGHTNESS", nil);
    _brightnessSlider.accessibilityLabel = _brightnessLabel.text;
    _saturationLabel.text = NSLocalizedString(@"VFILTER_SATURATION", nil);
    _saturationSlider.accessibilityLabel = _saturationLabel.text;
    _gammaLabel.text = NSLocalizedString(@"VFILTER_GAMMA", nil);
    _gammaSlider.accessibilityLabel = _gammaLabel.text;
    _resetVideoFilterButton.accessibilityLabel = NSLocalizedString(@"VIDEO_FILTER_RESET_BUTTON", nil);

    #if !NEW_UI
        [self setupMultiSelectionView];
        self.trackNameLabel.text = @"";
    #else
        [self setupVideoOptionsControlBar];
        _moreOptionsActionSheet = [[VLCMediaMoreOptionsActionSheet alloc] init];
        _moreOptionsActionSheet.moreOptionsDelegate = self;
        self.navigationController.navigationBar.hidden = YES;
        self.trackNameLabel.hidden = YES;
        [self setupMediaNavigationBar];
    #endif

    _scrubHelpLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_HELP", nil);

    self.playbackSpeedView.hidden = YES;
    _playbackSpeedViewHidden = YES;
    _playbackSpeedView.delegate = self;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(handleExternalScreenDidConnect:)
                   name:UIScreenDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(handleExternalScreenDidDisconnect:)
                   name:UIScreenDidDisconnectNotification object:nil];
    [center addObserver:self
               selector:@selector(appBecameActive:)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(playbackDidStop:)
                   name:VLCPlaybackServicePlaybackDidStop
                 object:nil];

    self.artistNameLabel.text = self.albumNameLabel.text = @"";

    _movieView.userInteractionEnabled = NO;

    [self setupGestureRecognizers];

    _isTapSeeking = NO;
    _previousJumpState = VLCMovieJumpStateDefault;
    _numberOfTapSeek = 0;

    CGRect rect = self.resetVideoFilterButton.frame;
    rect.origin.y = rect.origin.y + 5.;
    self.resetVideoFilterButton.frame = rect;

    [self setupMovieView];

    _trackSelectorContainer = [[VLCTrackSelectorView alloc] initWithFrame:CGRectZero];
    _trackSelectorContainer.hidden = YES;
    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers)
            [recognizer setEnabled:YES];
        self->_trackSelectorContainer.hidden = YES;
    };
    _trackSelectorContainer.completionHandler = completionBlock;
    _trackSelectorContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_trackSelectorContainer];

    _equalizerView = [[VLCEqualizerView alloc] initWithFrame:CGRectMake(0, 0, 450., 240.)];
    _equalizerView.delegate = [VLCPlaybackService sharedInstance];
    _equalizerView.UIdelegate = self;
    _equalizerView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    _equalizerView.hidden = YES;
    [self.view addSubview:_equalizerView];

    //Sleep Timer initialization
    [self sleepTimerInitializer];
    [self setupControlPanel];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    _screenPixelSize = CGSizeMake(screenBounds.size.width, screenBounds.size.height);

    [self setupConstraints];
    [self setupRendererDiscovererManager];
}

- (void)setupMovieViewConstraints
{
    _movieViewLeadingConstraint = [_movieView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor];
    _movieViewTrailingConstraint = [_movieView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor];

    [NSLayoutConstraint activateConstraints:@[
        _movieViewLeadingConstraint,
        _movieViewTrailingConstraint,
        [_movieView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_movieView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)setupMovieView
{
    _movieView.translatesAutoresizingMaskIntoConstraints = NO;

    if (@available(iOS 11.0, *)) {
        [self.movieView setAccessibilityIgnoresInvertColors:YES];
    }

    [self setupMovieViewConstraints];
    [self.movieView setAccessibilityIdentifier:@"Video Player Title"];
    [self.movieView setAccessibilityLabel:NSLocalizedString(@"VO_VIDEOPLAYER_TITLE", nil)];
    [self.movieView setAccessibilityHint:NSLocalizedString(@"VO_VIDEOPLAYER_DOUBLETAP", nil)];
}

- (void) setupMultiSelectionView
{
    _multiSelectionView = [[VLCMultiSelectionMenuView alloc] init];
    _multiSelectionView.delegate = self;
    _multiSelectionView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _multiSelectionView.hidden = YES;
    _multiSelectionView.repeatMode = _vpc.repeatMode;
    [self.view addSubview:_multiSelectionView];
}

- (void)setupVideoOptionsControlBar
{
    _videoOptionsControlBar = [[VLCVideoOptionsControlBar alloc] init];
    _videoOptionsControlBar.delegate = self;
    _videoOptionsControlBar.repeatMode = _vpc.repeatMode;
    [self.view addSubview:_videoOptionsControlBar];
}

- (void)setupGestureRecognizers
{
    _tapOnVideoRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControlsVisible)];
    _tapOnVideoRecognizer.delegate = self;
    [self.view addGestureRecognizer:_tapOnVideoRecognizer];

    _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    _pinchRecognizer.delegate = self;

    _doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapRecognized:)];
    [_doubleTapRecognizer setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:_doubleTapRecognizer];
    [_tapOnVideoRecognizer requireGestureRecognizerToFail:_doubleTapRecognizer];

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
    _doubleTapRecognizer.delegate = self;
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

- (NSArray *) getMediaNavigationBarConstraints
{
    UILayoutGuide *guide = self.view.layoutMarginsGuide;
    if (@available(iOS 11.0, *)) {
        guide = self.view.safeAreaLayoutGuide;
    }

    CGFloat padding = 20.0f;
    return @[
      [_mediaNavigationBar.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
      [_mediaNavigationBar.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:padding],
      [_mediaNavigationBar.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant: -padding],
      [_mediaNavigationBar.topAnchor constraintEqualToAnchor:guide.topAnchor constant: padding],
      ];
}

- (void)setupConstraints
{
    NSArray *controlPanelHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[panel]|"
                                                                                      options:0
                                                                                      metrics:nil
                                                                                        views:@{@"panel":_controllerPanel}];

    NSArray *controlPanelVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[panel]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:@{@"panel":_controllerPanel}];
    [self.view addConstraints:controlPanelHorizontalConstraints];
    [self.view addConstraints:controlPanelVerticalConstraints];

    //constraint within _trackSelectorContainer is setting it's height to the tableviews contentview
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:_trackSelectorContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:2.0/3.0 constant:0];
    widthConstraint.priority = UILayoutPriorityRequired - 1;
    NSArray *constraints = @[
                             [NSLayoutConstraint constraintWithItem:_trackSelectorContainer attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_trackSelectorContainer attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_trackSelectorContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:420.0],
                             widthConstraint,
                             [NSLayoutConstraint constraintWithItem:_trackSelectorContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:2.0/3.0 constant:0],
                             [_videoFilterView.bottomAnchor constraintEqualToAnchor:_controllerPanel.topAnchor]
                             ];
    #if NEW_UI
        constraints = [constraints arrayByAddingObjectsFromArray:[self getVideoOptionsConstraints]];
        constraints = [constraints arrayByAddingObjectsFromArray:[self getMediaNavigationBarConstraints]];
    #endif
    [NSLayoutConstraint activateConstraints: constraints];
}

- (UIButton *)doneButton
{
    if (!_doneButton) {
        _doneButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_doneButton setAccessibilityIdentifier:@"Done"];
        [_doneButton addTarget:self action:@selector(closePlayback:) forControlEvents:UIControlEventTouchUpInside];
        [_doneButton setTitle:NSLocalizedString(@"BUTTON_DONE", nil) forState:UIControlStateNormal];
        [_doneButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        _doneButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _doneButton;
}

- (UIStackView *)navigationBarStackView
{
    if (!_navigationBarStackView) {
        _navigationBarStackView = [[UIStackView alloc] init];
        _navigationBarStackView.translatesAutoresizingMaskIntoConstraints = NO;
        _navigationBarStackView.spacing = 8;
        _navigationBarStackView.axis = UILayoutConstraintAxisHorizontal;
        _navigationBarStackView.alignment = UIStackViewAlignmentCenter;
        [_navigationBarStackView addArrangedSubview:self.doneButton];
        [_navigationBarStackView addArrangedSubview:_timeNavigationTitleView];
        [_navigationBarStackView addArrangedSubview:_rendererButton];
    }
    return _navigationBarStackView;
}

- (void) setupMediaNavigationBar {
    _mediaNavigationBar = [[VLCMediaNavigationBar alloc] init];
    _mediaNavigationBar.delegate = self;
    _mediaNavigationBar.chromeCastButton.hidden = _vpc.renderer == nil;
    [self.view addSubview:_mediaNavigationBar];
}

- (void)setupNavigationbar
{
    if (!self.timeNavigationTitleView) {
        self.timeNavigationTitleView = [[[NSBundle mainBundle] loadNibNamed:@"VLCTimeNavigationTitleView" owner:self options:nil] objectAtIndex:0];
        self.timeNavigationTitleView.translatesAutoresizingMaskIntoConstraints = NO;
    }

    if (_vpc.renderer != nil) {
        [_rendererButton setSelected:YES];
    }

    if (self.navigationBarStackView.superview == nil) {
        [self.navigationController.navigationBar addSubview:self.navigationBarStackView];

        NSObject *guide = self.navigationController.navigationBar;
        if (@available(iOS 11.0, *)) {
            guide = self.navigationController.navigationBar.layoutMarginsGuide;
        }

        [NSLayoutConstraint activateConstraints:@[
                                                  [NSLayoutConstraint constraintWithItem:self.navigationBarStackView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.navigationController.navigationBar attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
                                                  [NSLayoutConstraint constraintWithItem:self.navigationBarStackView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeLeft multiplier:1 constant:8],
                                                  [NSLayoutConstraint constraintWithItem:self.navigationBarStackView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeRight multiplier:1 constant:-8],
                                                  [NSLayoutConstraint constraintWithItem:self.navigationBarStackView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.navigationController.navigationBar attribute:NSLayoutAttributeTop multiplier:1 constant:0],
                                                  [NSLayoutConstraint constraintWithItem:self.navigationBarStackView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.navigationController.navigationBar attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
                                                  [NSLayoutConstraint constraintWithItem:self.timeNavigationTitleView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.navigationBarStackView attribute:NSLayoutAttributeHeight multiplier:1 constant:0],
                                                  ]];
        self.scrubViewTopConstraint.constant = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    }
}

- (void)resetVideoFiltersSliders
{
    _brightnessSlider.value = 1.;
    _contrastSlider.value = 1.;
    _hueSlider.value = 0.;
    _saturationSlider.value = 1.;
    _gammaSlider.value = 1.;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _vpc.delegate = self;
    _lockedOrientation = UIInterfaceOrientationPortrait;
    [_vpc recoverPlaybackState];
    #if !NEW_UI
        [self setupNavigationbar];
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        self.trackNameLabel.text = nil;
    #else
        self.navigationController.navigationBar.hidden = YES;
    #endif
    /* reset audio meta data views */
    self.artworkImageView.image = nil;
    self.artistNameLabel.text = nil;
    self.albumNameLabel.text = nil;

    [self setControlsHidden:NO animated:animated];

    [self updateDefaults];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDefaults) name:NSUserDefaultsDidChangeNotification object:nil];

    VLCRendererDiscovererManager *manager = _services.rendererDiscovererManager;

    manager.presentingViewController = self;
    manager.delegate = self;
    if ([_vpc isPlayingOnExternalScreen]) {
         [self showOnDisplay:_playingExternalView.displayView];
    }

    if (@available(iOS 11.0, *)) {
        [self adaptMovieViewToNotch];
    }
}

- (void)layoutFrameForMultiSelectionView
{
    CGRect controllerPanelFrame = _controllerPanel.frame;
    CGRect multiSelectionFrame;
    
    BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (!isIphone) {
        _multiSelectionView.showsEqualizer = YES;
    } else {
        BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
        _multiSelectionView.showsEqualizer = isLandscape;
    }

    multiSelectionFrame = (CGRect){CGPointMake(0., 0.), [_multiSelectionView proposedDisplaySize]};
    multiSelectionFrame.origin.x = controllerPanelFrame.size.width - multiSelectionFrame.size.width;
    multiSelectionFrame.origin.y = controllerPanelFrame.origin.y - multiSelectionFrame.size.height;
    _multiSelectionView.frame = multiSelectionFrame;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _viewAppeared = YES;
    _playbackWillClose = NO;

    [_vpc recoverDisplayedMetadata];
    [self resetVideoFiltersSliders];
    _vpc.videoOutputView = self.movieView;
    
    #if !NEW_UI
        _multiSelectionView.repeatMode = _vpc.repeatMode;
        _multiSelectionView.shuffleMode = _vpc.isShuffleMode;
    #else
        _videoOptionsControlBar.repeatMode = _vpc.repeatMode;
    #endif

    //Media is loaded in the media player, checking the projection type and configuring accordingly.
    [self setupForMediaProjection];
}

- (void)viewDidLayoutSubviews
{
    CGRect equalizerRect = _equalizerView.frame;
    equalizerRect.origin.x = CGRectGetMidX(self.view.bounds) - CGRectGetWidth(equalizerRect)/2.0;
    equalizerRect.origin.y = CGRectGetMidY(self.view.bounds) - CGRectGetHeight(equalizerRect)/2.0;
    _equalizerView.frame = equalizerRect;
    
    #if !NEW_UI
        [self layoutFrameForMultiSelectionView];
    #endif

    self.scrubViewTopConstraint.constant = CGRectGetMaxY(self.navigationController.navigationBar.frame);
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

    [super viewWillDisappear:animated];

    // hide filter UI for next run
    if (!_videoFiltersHidden)
        _videoFiltersHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    if (!_playbackSpeedViewHidden)
        _playbackSpeedViewHidden = YES;

    if (_interfaceIsLocked)
        [self toggleUILock];
    // reset tap to seek values
    _isTapSeeking = NO;
    _previousJumpState = VLCMovieJumpStateDefault;
    _numberOfTapSeek = 0;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    [[NSUserDefaults standardUserDefaults] setBool:_displayRemainingTime forKey:kVLCShowRemainingTime];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.deviceMotion stopDeviceMotion];
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
        [self performSelectorOnMainThread:@selector(updateTimeDisplayButton) withObject:nil waitUntilDone:NO];
    }

    _volumeGestureEnabled = [[defaults objectForKey:kVLCSettingVolumeGesture] boolValue];
    _playPauseGestureEnabled = [[defaults objectForKey:kVLCSettingPlayPauseGesture] boolValue];
    _brightnessGestureEnabled = [[defaults objectForKey:kVLCSettingBrightnessGesture] boolValue];
    _swipeSeekGestureEnabled = [[defaults objectForKey:kVLCSettingSeekGesture] boolValue];
    _closeGestureEnabled = [[defaults objectForKey:kVLCSettingCloseGesture] boolValue];
    _variableJumpDurationEnabled = [[defaults objectForKey:kVLCSettingVariableJumpDuration] boolValue];
}

#pragma mark - Initializer helper

- (void)sleepTimerInitializer
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
    _sleepTimeDatePicker.opaque = NO;
    _sleepTimeDatePicker.backgroundColor = [UIColor clearColor];
    _sleepTimeDatePicker.tintColor = [UIColor VLCLightTextColor];
    _sleepTimeDatePicker.frame = CGRectMake(0., 0., 300., 162.);
    _sleepTimeDatePicker.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;

    [_sleepTimerContainer addSubview:_sleepTimeDatePicker];
    [_sleepTimerContainer.layer addSublayer:horizontalSeparator];
    [_sleepTimerContainer.layer addSublayer:verticalSeparator];

    UIButton *cancelSleepTimer = [[UIButton alloc] initWithFrame:CGRectMake(0., 162., 150., 48.)];
    cancelSleepTimer.backgroundColor = [UIColor clearColor];
    [cancelSleepTimer setTitle:NSLocalizedString(@"BUTTON_RESET", nil) forState:UIControlStateNormal];
    [cancelSleepTimer setTintColor:[UIColor VLCLightTextColor]];
    [cancelSleepTimer setTitleColor:[UIColor VLCDarkTextShadowColor] forState:UIControlStateHighlighted];
    [cancelSleepTimer addTarget:self action:@selector(sleepTimerCancel:) forControlEvents:UIControlEventTouchDown];
    cancelSleepTimer.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 10, 0);
    [_sleepTimerContainer addSubview:cancelSleepTimer];

    UIButton *confirmSleepTimer = [[UIButton alloc] initWithFrame:CGRectMake(150., 162., 150., 48.)];
    confirmSleepTimer.backgroundColor = [UIColor clearColor];
    [confirmSleepTimer setTitle:NSLocalizedString(@"BUTTON_SET", nil) forState:UIControlStateNormal];
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

- (NSArray *)itemsForInterfaceLock
{
    NSArray *arr = [NSArray arrayWithObjects:
                        _pinchRecognizer,
                        _panRecognizer,
                        _tapRecognizer,
                        _doubleTapRecognizer,
                        _controllerPanel.playbackSpeedButton,
                        _controllerPanel.trackSwitcherButton,
                        _controllerPanel.bwdButton,
                        _controllerPanel.playPauseButton,
                        _controllerPanel.fwdButton,
                        _controllerPanel.videoFilterButton,
                        _controllerPanel.volumeView,
                        nil];
    #if !NEW_UI
        arr = [arr arrayByAddingObjectsFromArray:
                    @[_multiSelectionView.repeatButton,
                      _multiSelectionView.shuffleButton,
                      _multiSelectionView.equalizerButton,
                      _multiSelectionView.chapterSelectorButton,
                      _timeNavigationTitleView.minimizePlaybackButton,
                      _timeNavigationTitleView.positionSlider,
                      _timeNavigationTitleView.aspectRatioButton,
                      _doneButton,
                      _rendererButton]];
    #else
        UIView *airplayView;
        if (@available(iOS 11.0, *)) {
            airplayView = (UIView *)_mediaNavigationBar.airplayRoutePickerView;
        } else {
            airplayView = (UIView *)_mediaNavigationBar.airplayVolumeView;
        }
        arr = [arr arrayByAddingObjectsFromArray:
                    @[_videoOptionsControlBar.toggleFullScreenButton,
                      _videoOptionsControlBar.selectSubtitleButton,
                      _videoOptionsControlBar.repeatButton,
                      _mediaNavigationBar.minimizePlaybackButton,
                      _mediaNavigationBar.chromeCastButton,
                      airplayView]
               ];
    #endif
    return arr;
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    CGFloat diff = DEFAULT_FOV * -(ZOOM_SENSITIVITY * recognizer.velocity / _screenPixelSize.width);

    if ([_vpc currentMediaIs360Video]) {
        [self zoom360Video:diff];
    } else if (recognizer.velocity < 0. && _closeGestureEnabled) {
        [self minimizePlayback:nil];
    }
}

- (void)zoom360Video:(CGFloat)zoom
{
    if ([_vpc updateViewpoint:0 pitch:0 roll:0 fov:zoom absolute:NO]) {
        //clamp Fov between min and max fov
        _fov = MAX(MIN(_fov + zoom, MAX_FOV), MIN_FOV);
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
        
    #if !NEW_UI
        _multiSelectionView.alpha = 0.0f;
        _multiSelectionView.hidden = YES;
        self.navigationController.navigationBar.alpha = 0.0;
        self.navigationController.navigationBar.hidden = NO;
        _trackNameLabel.hidden = NO;
    #else
        _videoOptionsControlBar.alpha = 0.0f;
        _videoOptionsControlBar.hidden = YES;
        _mediaNavigationBar.alpha = 0.0f;
        _mediaNavigationBar.hidden = YES;
    #endif

        _artistNameLabel.hidden = NO;
        _albumNameLabel.hidden = NO;
    }

    void (^animationBlock)(void) = ^() {
        self->_controllerPanel.alpha = alpha;
        self->_videoFilterView.alpha = alpha;
        self->_playbackSpeedView.alpha = alpha;
        self->_trackSelectorContainer.alpha = alpha;
        
        CGFloat metaInfoAlpha = self->_audioOnly ? 1.0f : alpha;
        self->_artistNameLabel.alpha = metaInfoAlpha;
        self->_albumNameLabel.alpha = metaInfoAlpha;
        
       #if !NEW_UI
            self->_multiSelectionView.alpha = alpha;
            self.navigationController.navigationBar.alpha = alpha;
            self->_trackNameLabel.alpha = [self->_vpc isPlayingOnExternalScreen] ? 0.f : metaInfoAlpha;
       #else
            self->_videoOptionsControlBar.alpha = alpha;
            self->_mediaNavigationBar.alpha = alpha;
       #endif
        
        self->_equalizerView.alpha = alpha;
        if (self->_sleepTimerContainer)
            self->_sleepTimerContainer.alpha = alpha;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        self->_controllerPanel.hidden = self->_videoFiltersHidden ? self->_controlsHidden : NO;
        self->_videoFilterView.hidden = self->_videoFiltersHidden;
        self->_playbackSpeedView.hidden = self->_playbackSpeedViewHidden;
        self->_trackSelectorContainer.hidden = YES;
        self->_equalizerView.hidden = YES;
        if (self->_sleepTimerContainer)
            self->_sleepTimerContainer.hidden = YES;
        
        #if !NEW_UI
            self->_multiSelectionView.hidden = YES;
            self.navigationController.navigationBar.hidden = self->_controlsHidden;
            self->_trackNameLabel.hidden =  self->_audioOnly ? NO : self->_controlsHidden;
        #else
            self->_videoOptionsControlBar.hidden = NO;
            self->_mediaNavigationBar.hidden = self->_controlsHidden;
        #endif

        self->_artistNameLabel.hidden = self->_audioOnly ? NO : self->_controlsHidden;
        self->_albumNameLabel.hidden =  self->_audioOnly ? NO : self->_controlsHidden;
    };

    NSTimeInterval animationDuration = animated? 0.3 : 0.0;
    [UIView animateWithDuration:animationDuration animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];

    [UIView animateWithDuration:animationDuration animations:animationBlock completion:completionBlock];
}

- (BOOL)prefersStatusBarHidden
{
    return _viewAppeared ? _controlsHidden : NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

- (void)toggleControlsVisible
{
    if (!_trackSelectorContainer.hidden) {
        for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers)
            [recognizer setEnabled:YES];
    }

    if (_controlsHidden && !_videoFiltersHidden)
        _videoFiltersHidden = YES;

    if (_controlsHidden && !_playbackSpeedViewHidden)
        _playbackSpeedViewHidden = YES;

    if (_isTapSeeking)
        _numberOfTapSeek = 0;

    [self setControlsHidden:!_controlsHidden animated:YES];
}

- (void)updateActivityIndicatorForState:(VLCMediaPlayerState)state
{
    if (state == VLCMediaPlayerStatePlaying || state == VLCMediaPlayerStatePaused) {
        _previousPlayerStateWasPaused = state == VLCMediaPlayerStatePaused;
    }
    BOOL shouldAnimate = state == VLCMediaPlayerStateBuffering && !_previousPlayerStateWasPaused;
    if (self.activityIndicator.isAnimating != shouldAnimate) {
        self.activityIndicator.alpha = shouldAnimate ? 1.0 : 0.0;
        shouldAnimate ? [self.activityIndicator startAnimating] : [self.activityIndicator stopAnimating];
    }
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

    int seekDuration = (int)_numberOfTapSeek * SHORT_JUMP_DURATION;

    if (seekDuration > 0) {
        [_vpc jumpForward:SHORT_JUMP_DURATION];
        [hudString appendString:@"⇒ "];
        _previousJumpState = VLCMovieJumpStateForward;
    } else {
        [_vpc jumpBackward:SHORT_JUMP_DURATION];
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

- (VLCDeviceMotion *)deviceMotion
{
    if (!_deviceMotion) {
        _deviceMotion = [VLCDeviceMotion new];
        _deviceMotion.delegate = self;
    }
    return _deviceMotion;
}

- (void)setupForMediaProjection
{
    BOOL mediaHasProjection = [_vpc currentMediaIs360Video];
    _fov = mediaHasProjection ? DEFAULT_FOV : 0.f;

    [_swipeRecognizerUp setEnabled:!mediaHasProjection];
    [_swipeRecognizerDown setEnabled:!mediaHasProjection];
    [_swipeRecognizerLeft setEnabled:!mediaHasProjection];
    [_swipeRecognizerRight setEnabled:!mediaHasProjection];

    if (mediaHasProjection) {
        [self.deviceMotion startDeviceMotion];
    }
}

- (void)applyYaw:(CGFloat)diffYaw pitch:(CGFloat)diffPitch;
{
    //Add and limit new pitch and yaw
    self.deviceMotion.yaw += diffYaw;
    self.deviceMotion.pitch += diffPitch;

    [_vpc updateViewpoint:self.deviceMotion.yaw pitch:self.deviceMotion.pitch roll:0 fov:_fov absolute:YES];
}

- (void)deviceMotionHasAttitudeWithDeviceMotion:(VLCDeviceMotion *)deviceMotion pitch:(double)pitch yaw:(double)yaw
{
    if (_panRecognizer.state != UIGestureRecognizerStateChanged || UIGestureRecognizerStateBegan) {
        [self applyYaw:yaw pitch:pitch];
    }
}

#pragma mark - keyboard controls

- (NSArray<UIKeyCommand *> *)keyCommands
{
    NSMutableArray<UIKeyCommand *> *commands = [NSMutableArray arrayWithObjects:
                                                [UIKeyCommand keyCommandWithInput:@" " modifierFlags:0 action:@selector(playPause) discoverabilityTitle:@"Play/Pause"],
                                                [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:0 action:@selector(playPause) discoverabilityTitle:@"Play/Pause"],
                                                [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:@selector(keyBackward) discoverabilityTitle:@"Skip Back"],
                                                [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:0 action:@selector(keyForward) discoverabilityTitle:@"Skip Forward"],
                                                [UIKeyCommand keyCommandWithInput:@"[" modifierFlags:0 action:@selector(keyLeftBracket) discoverabilityTitle:@"Decrease playback speed"],
                                                [UIKeyCommand keyCommandWithInput:@"]" modifierFlags:0 action:@selector(keyRightBracket) discoverabilityTitle:@"Increase playback speed"],
                                                nil];

    bool playbackRateIsOne = ((fabsf(_vpc.playbackRate) - 1) < FLT_EPSILON);
    if (playbackRateIsOne) {
        UIKeyCommand *resetPlaybackCommand = [UIKeyCommand keyCommandWithInput:@"=" modifierFlags:0 action:@selector(keyEqual) discoverabilityTitle:@"Reset playback speed"];
        [commands addObject:resetPlaybackCommand];
    }

    return commands;
}

- (void)keyForward
{
    [_vpc jumpForward:FORWARD_SWIPE_DURATION];
}

- (void)keyBackward
{
    [_vpc jumpBackward:BACKWARD_SWIPE_DURATION];
}

- (void)keyEqual
{
    [_vpc setPlaybackRate:1];
}

- (void)keyLeftBracket
{
    [_vpc setPlaybackRate:_vpc.playbackRate * 0.75];
}

- (void)keyRightBracket
{
    [_vpc setPlaybackRate:_vpc.playbackRate * 1.5];
}

#pragma mark - controls

- (void)closePlayback:(id)sender
{
    _playbackWillClose = YES;
    [_vpc stopPlayback];
}

- (IBAction)minimizePlayback:(id)sender
{
    [_delegate movieViewControllerDidSelectMinimize:self];
}

- (IBAction)positionSliderAction:(UISlider *)sender
{
    /* we need to limit the number of events sent by the slider, since otherwise, the user
     * wouldn't see the I-frames when seeking on current mobile devices. This isn't a problem
     * within the Simulator, but especially on older ARMv7 devices, it's clearly noticeable. */
    [self performSelector:@selector(_setPositionForReal) withObject:nil afterDelay:0.3];
    if (_mediaDuration > 0) {
        VLCTime *newPosition = [VLCTime timeWithInt:(int)(sender.value * _mediaDuration)];
        [self.timeNavigationTitleView.timeDisplayButton setTitle:newPosition.stringValue forState:UIControlStateNormal];
        [self.timeNavigationTitleView setNeedsLayout];
        self.timeNavigationTitleView.timeDisplayButton.accessibilityLabel = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"PLAYBACK_POSITION", nil), newPosition.stringValue];
    }
    _positionSet = NO;
    [self _resetIdleTimer];
}

- (void)_setPositionForReal
{
    if (!_positionSet) {
        [_vpc setPlaybackPosition:self.timeNavigationTitleView.positionSlider.value];
        [_vpc setNeedsMetadataUpdate];
        _positionSet = YES;
    }
}

- (IBAction)positionSliderTouchDown:(id)sender
{
    [self _updateScrubLabel];
    self.scrubIndicatorView.hidden = NO;
    _isScrubbing = YES;
}

- (IBAction)positionSliderTouchUp:(id)sender
{
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
    [self _updateScrubLabel];
}

- (void)volumeSliderAction:(id)sender
{
    [self _resetIdleTimer];
}

- (void)updateTimeDisplayButton
{
    UIButton *timeDisplayButton = self.timeNavigationTitleView.timeDisplayButton;
    if (_displayRemainingTime)
        [timeDisplayButton setTitle:[[_vpc remainingTime] stringValue] forState:UIControlStateNormal];
    else
        [timeDisplayButton setTitle:[[_vpc playedTime] stringValue] forState:UIControlStateNormal];
    [self.timeNavigationTitleView setNeedsLayout];
}

#pragma mark - playback controller delegation

- (void)playbackPositionUpdated:(VLCPlaybackService *)playbackService
{
    // FIXME: hard coded state since the state in mediaPlayer is incorrectly still buffering
    [self updateActivityIndicatorForState:VLCMediaPlayerStatePlaying];

    if (!_isScrubbing) {
        self.timeNavigationTitleView.positionSlider.value = [playbackService playbackPosition];
    }

    [self updateTimeDisplayButton];
}

- (void)prepareForMediaPlayback:(VLCPlaybackService *)playbackService
{
    #if !NEW_UI
        self.trackNameLabel.text = @"";
    #else
        [_mediaNavigationBar setMediaTitleLabelText:@""];
    #endif
    self.artistNameLabel.text = self.albumNameLabel.text = @"";
    self.timeNavigationTitleView.positionSlider.value = 0.;
    [self.timeNavigationTitleView.timeDisplayButton setTitle:@"" forState:UIControlStateNormal];
    self.timeNavigationTitleView.timeDisplayButton.accessibilityLabel = @"";
    [_equalizerView reloadData];

    [_playbackSpeedView prepareForMediaPlaybackWithController:playbackService];

    [self _resetIdleTimer];
}

- (void)playbackDidStop:(NSNotification *)notification
{
    [self minimizePlayback:nil];
    // reset toggleButton to default icon when movieviewcontroller is dismissed
    _videoOptionsControlBar.isInFullScreen = NO;
}

- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
currentMediaHasTrackToChooseFrom:(BOOL)currentMediaHasTrackToChooseFrom
        currentMediaHasChapters:(BOOL)currentMediaHasChapters
             forPlaybackService:(VLCPlaybackService *)playbackService
{
    [self updateActivityIndicatorForState:currentState];

    if (currentState == VLCMediaPlayerStateBuffering)
        _mediaDuration = playbackService.mediaDuration;

    if (currentState == VLCMediaPlayerStateError)
        [self.statusLabel showStatusMessage:NSLocalizedString(@"PLAYBACK_FAILED", nil)];

    [_controllerPanel updateButtons];
    
    #if !NEW_UI
        _multiSelectionView.mediaHasChapters = currentMediaHasChapters;
    #endif
}

- (void)savePlaybackState:(VLCPlaybackService *)playbackService
{
    [_services.medialibraryService savePlaybackStateFrom:playbackService];
}

- (VLCMLMedia *)mediaForPlayingMedia:(VLCMedia *)media
{
    return [_services.medialibraryService fetchMediaWith:media.url];
}

- (void)showStatusMessage:(NSString *)statusMessage
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

- (void) playbackServiceDidSwitchAspectRatio:(VLCAspectRatio)aspectRatio
{
    _videoOptionsControlBar.isInFullScreen = aspectRatio == VLCAspectRatioFillToScreen;

    if (@available(iOS 11, *)) {
        [self adaptMovieViewToNotch];
    }
}

- (void)displayMetadataForPlaybackService:(VLCPlaybackService *)playbackService
                                 metadata:(VLCMetaData *)metadata
{
    if (!_viewAppeared)
        return;

    #if !NEW_UI
        self.trackNameLabel.text = metadata.title;
    #else
        [_mediaNavigationBar setMediaTitleLabelText:metadata.title];
    #endif
    
    self.artworkImageView.image = metadata.artworkImage;
    if (!metadata.artworkImage) {
        self.artistNameLabel.text = metadata.artist;
        self.albumNameLabel.text = metadata.albumName;
    } else
        self.artistNameLabel.text = self.albumNameLabel.text = nil;

    [self hideShowAspectratioButton:metadata.isAudioOnly];
    [_controllerPanel updateButtons];
    [_playingExternalView updateUIWithRendererItem:_vpc.renderer title:metadata.title];

    _audioOnly = metadata.isAudioOnly;
    _artworkImageView.hidden = !_audioOnly;

    #if NEW_UI
        _videoOptionsControlBar.toggleFullScreenButton.hidden = _audioOnly;
    #endif
}

- (IBAction)playPause
{
    [_vpc playPause];
}

- (IBAction)forward:(id)sender
{
    [_vpc next];
}

- (IBAction)backward:(id)sender
{
    [_vpc previous];
}

- (IBAction)switchTrack:(id)sender
{
    if (_trackSelectorContainer.hidden == YES || _trackSelectorContainer.switchingTracksNotChapters == NO) {
        _trackSelectorContainer.switchingTracksNotChapters = YES;

        _trackSelectorContainer.hidden = NO;
        _trackSelectorContainer.alpha = 1.;

        [_trackSelectorContainer updateView];

        if (_equalizerView.hidden == NO)
            _equalizerView.hidden = YES;

        if (!_playbackSpeedViewHidden)
            self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

        self.videoFilterView.hidden = _videoFiltersHidden = YES;

        for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers)
            [recognizer setEnabled:NO];
        [_tapOnVideoRecognizer setEnabled:YES];

    } else {
        _trackSelectorContainer.hidden = YES;
        _trackSelectorContainer.switchingTracksNotChapters = NO;
    }
}

- (IBAction)toggleTimeDisplay:(id)sender
{
    _displayRemainingTime = !_displayRemainingTime;
    [self updateTimeDisplayButton];

    [self _resetIdleTimer];
}

- (void)showSleepTimer
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

    [_playbackSpeedView setupSleepTimerIfNecessary];
    [self.statusLabel showStatusMessage:NSLocalizedString(@"SLEEP_TIMER_UPDATED", nil)];
    [self setControlsHidden:YES animated:YES];
}

- (void)toggleMultiSelectionView:(UIButton *)sender {
    if (_multiSelectionView.hidden == NO) {
        [UIView animateWithDuration:.3
                         animations:^{
                             self->_multiSelectionView.hidden = YES;
                         }
                         completion:nil];
        return;
    }
    
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
    BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    _multiSelectionView.showsEqualizer = (isLandscape && isIphone) || !isIphone;
    
    CGRect workFrame = _multiSelectionView.frame;
    workFrame.size = [_multiSelectionView proposedDisplaySize];
    workFrame.origin.x = CGRectGetMaxX(sender.frame) - workFrame.size.width;
    
    _multiSelectionView.alpha = 1.0f;
    
    /* animate */
    _multiSelectionView.frame = CGRectMake(workFrame.origin.x, workFrame.origin.y + workFrame.size.height, workFrame.size.width, 0.);
    [UIView animateWithDuration:.3
                     animations:^{
                         self->_multiSelectionView.frame = workFrame;
                         self->_multiSelectionView.hidden = NO;
                     }
                     completion:nil];
}

- (void)moreActions:(UIButton *)sender
{
    #if !NEW_UI
        [self toggleMultiSelectionView:sender];
    #endif
    [self _resetIdleTimer];
}

#pragma mark - multi-select delegation

- (void)toggleUILock
{
    _interfaceIsLocked = !_interfaceIsLocked;
    if (_interfaceIsLocked) {
        _lockedOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    }

    NSArray *items = [self itemsForInterfaceLock];

    for (NSObject *item in items) {
        if ([item isKindOfClass:[UIControl class]]) {
            UIControl *control = (UIControl *)item;
            if (NEW_UI && item == _mediaNavigationBar.chromeCastButton) {
                control.enabled = !_interfaceIsLocked;
            } else {
                control.enabled = !_interfaceIsLocked;
            }
        } else if ([item isKindOfClass:[UIGestureRecognizer class]]){
            UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)item;
            gestureRecognizer.enabled = !_interfaceIsLocked;
        } else if ([item isKindOfClass:[VLCVolumeView class]]) {
            //The MPVolumeview doesn't adjust it's UI when disabled so we need to set the alpha by hand
            VLCVolumeView *view = (VLCVolumeView *)item;
            view.userInteractionEnabled = !_interfaceIsLocked;
            view.alpha = _interfaceIsLocked ? 0.5 : 1;
        } else if(@available(iOS 11.0, *)){
            if ([item isKindOfClass:[AVRoutePickerView class]]) {
                AVRoutePickerView *airplayView = (AVRoutePickerView *)item;
                airplayView.userInteractionEnabled = !_interfaceIsLocked;
                airplayView.alpha = _interfaceIsLocked ? 0.5 : 1;
            }
        } else {
             NSAssert(NO, @"class not handled");
        }
    }
    
    #if !NEW_UI
        _multiSelectionView.displayLock = _interfaceIsLocked;
    #else
        _videoOptionsControlBar.interfaceDisabled = _interfaceIsLocked;
        _moreOptionsActionSheet.interfaceDisabled = _interfaceIsLocked;
    #endif
}

- (void)toggleEqualizer
{
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
    if (_trackSelectorContainer.hidden == YES || _trackSelectorContainer.switchingTracksNotChapters == YES) {
        _trackSelectorContainer.switchingTracksNotChapters = NO;
        [_trackSelectorContainer updateView];

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
    [[VLCPlaybackService sharedInstance] toggleRepeatMode];
    #if !NEW_UI
        _multiSelectionView.repeatMode = [VLCPlaybackService sharedInstance].repeatMode;
    #else
        _videoOptionsControlBar.repeatMode = [VLCPlaybackService sharedInstance].repeatMode;
    #endif
}

- (void)toggleShuffleMode
{
    _vpc.shuffleMode = !_vpc.isShuffleMode;
    #if !NEW_UI
        _multiSelectionView.shuffleMode = _vpc.isShuffleMode;
    #endif
}

- (void)hideMenu
{
    [UIView animateWithDuration:.2
                     animations:^{
                    #if !NEW_UI
                         self->_multiSelectionView.hidden = YES;
                    #else
                         self->_videoOptionsControlBar.hidden = YES;
                    #endif
                     }
                     completion:nil];
    [self _resetIdleTimer];
}

#pragma mark - multi-touch gestures

- (void)togglePlayPause
{
    if (!_playPauseGestureEnabled)
        return;

    if (_vpc.isPlaying) {
        [_vpc pause];
        [self setControlsHidden:NO animated:_controlsHidden];
    } else {
        [_vpc play];
    }
}


- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
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
    if ([deviceType isEqualToString:@"iPad"] && location.y < 110) {
        panType = VLCPanTypeSeek;
    }

    if ([_vpc currentMediaIs360Video]) {
        panType = VLCPanTypeProjection;
    }

    return panType;
}

- (void)panRecognized:(UIPanGestureRecognizer*)panRecognizer
{
    CGFloat panDirectionX = [panRecognizer velocityInView:self.view].x;
    CGFloat panDirectionY = [panRecognizer velocityInView:self.view].y;
    if (panRecognizer.state == UIGestureRecognizerStateBegan) {
        _currentPanType = [self detectPanTypeForPan:panRecognizer];
        if ([_vpc currentMediaIs360Video]) {
            _saveLocation =  [panRecognizer locationInView:self.view];
            [_deviceMotion stopDeviceMotion];
        }
    }
    
    switch (_currentPanType) {
        case VLCPanTypeSeek: {
            if (!_swipeSeekGestureEnabled)
                return;
            double timeRemainingDouble = (-[_vpc remainingTime].intValue*0.001);
            int timeRemaining = timeRemainingDouble;

            if (panDirectionX > 0) {
                if (timeRemaining > 2 ) // to not go outside duration , video will stop
                    [_vpc jumpForward:1];
            } else
                [_vpc jumpBackward:1];

            break;
        case VLCPanTypeVolume:

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
        } break;
        case VLCPanTypeBrightness: {
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

            NSString *brightnessHUD = [NSString stringWithFormat:@"%@: %@ %%", NSLocalizedString(@"VFILTER_BRIGHTNESS", nil), [[[NSString stringWithFormat:@"%f",(brightness*100)] componentsSeparatedByString:@"."] objectAtIndex:0]];
            [self.statusLabel showStatusMessage:brightnessHUD];
        } break;
        case VLCPanTypeProjection: {
            [self updateProjectionWithPanRecognizer:panRecognizer];
        } break;
        case VLCPanTypeNone: {
        } break;
    }

    if (panRecognizer.state == UIGestureRecognizerStateEnded) {
        _currentPanType = VLCPanTypeNone;
        if ([_vpc currentMediaIs360Video]) {
            [_deviceMotion startDeviceMotion];
        }
    }
}

- (void)updateProjectionWithPanRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint newLocationInView = [panGestureRecognizer locationInView:self.view];
    
    CGFloat diffX = newLocationInView.x - _saveLocation.x;
    CGFloat diffY = newLocationInView.y - _saveLocation.y;
    _saveLocation = newLocationInView;

    //screenSizePixel width is used twice to get a constant speed on the movement.
    CGFloat diffYaw = _fov * -diffX / _screenPixelSize.width;
    CGFloat diffPitch = _fov * -diffY / _screenPixelSize.width;

    [self applyYaw:diffYaw pitch:diffPitch];
}

- (void)swipeRecognized:(UISwipeGestureRecognizer*)swipeRecognizer
{
    if (!_swipeSeekGestureEnabled)
        return;

    NSString *hudString = @" ";

    int swipeForwardDuration = (_variableJumpDurationEnabled) ? ((int)(_mediaDuration*0.001*0.05)) : FORWARD_SWIPE_DURATION;
    int swipeBackwardDuration = (_variableJumpDurationEnabled) ? ((int)(_mediaDuration*0.001*0.05)) : BACKWARD_SWIPE_DURATION;

    if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        double timeRemainingDouble = (-[_vpc remainingTime].intValue*0.001);
        int timeRemaining = timeRemainingDouble;

        if (swipeForwardDuration < timeRemaining) {
            if (swipeForwardDuration < 1)
                swipeForwardDuration = 1;
            [_vpc jumpForward:swipeForwardDuration];
            hudString = [NSString stringWithFormat:@"⇒ %is", swipeForwardDuration];
        } else {
            [_vpc jumpForward:(timeRemaining - 5)];
            hudString = [NSString stringWithFormat:@"⇒ %is",(timeRemaining - 5)];
        }
    } else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        [_vpc jumpBackward:swipeBackwardDuration];
        hudString = [NSString stringWithFormat:@"⇐ %is",swipeBackwardDuration];
    } else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionUp) {
        [self backward:self];
        hudString = NSLocalizedString(@"BWD_BUTTON", "");
    } else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionDown) {
        [self forward:self];
        hudString = NSLocalizedString(@"FWD_BUTTON", "");
    }

    if (swipeRecognizer.state == UIGestureRecognizerStateEnded) {

        [self.statusLabel showStatusMessage:hudString];
    }
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) {
        return;
    }

    // safeAreaInsets can take some time to get set.
    // Once updated, check if we need to update the constraints for notches
    [self adaptMovieViewToNotch];
}

- (void)adaptMovieViewToNotch API_AVAILABLE(ios(11))
{
    // Ignore the constraint updates for iPads and notchless devices.
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone
        || (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && self.view.safeAreaInsets.bottom == 0)) {
        return;
    }

    // Ignore if playing on a external screen since there is no notches.
    if ([_vpc isPlayingOnExternalScreen]) {
        return;
    }

    // 30.0 represents the exact size of the notch
    CGFloat constant = _vpc.currentAspectRatio != VLCAspectRatioFillToScreen ? 30.0 : 0.0;

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    if (orientation == UIInterfaceOrientationLandscapeLeft
        || orientation == UIInterfaceOrientationLandscapeRight) {
        [_movieViewLeadingConstraint setConstant:constant];
        [_movieViewTrailingConstraint setConstant:-constant];
    } else {
        // Reset when in portrait
        [_movieViewLeadingConstraint setConstant:0];
        [_movieViewTrailingConstraint setConstant:0];
    }
    [_movieView layoutIfNeeded];
}

- (void)doubleTapRecognized:(UITapGestureRecognizer *)tapRecognizer
{
    CGFloat screenWidth = self.view.frame.size.width;
    CGFloat backwardBoundary = screenWidth / 3.0;
    CGFloat forwardBoundary = 2 * screenWidth / 3.0;

    CGPoint tapPosition = [tapRecognizer locationInView:self.view];

    //Handling seek reset if tap orientation changes.
    if (tapPosition.x < backwardBoundary) {
        _numberOfTapSeek = _previousJumpState == VLCMovieJumpStateForward ? -1 : _numberOfTapSeek - 1;
    } else if (tapPosition.x > forwardBoundary){
        _numberOfTapSeek = _previousJumpState == VLCMovieJumpStateBackward ? 1 : _numberOfTapSeek + 1;
    } else {
        [_vpc switchAspectRatio:YES];
        return;
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
    if (!_playbackSpeedViewHidden)
        self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    self.videoFilterView.hidden = !_videoFiltersHidden;
    _videoFiltersHidden = self.videoFilterView.hidden;
}

- (IBAction)videoFilterSliderAction:(id)sender
{
    if (sender == self.hueSlider)
        _vpc.hue = self.hueSlider.value;
    else if (sender == self.contrastSlider)
        _vpc.contrast = self.contrastSlider.value;
    else if (sender == self.brightnessSlider)
        _vpc.brightness = self.brightnessSlider.value;
    else if (sender == self.saturationSlider)
        _vpc.saturation = self.saturationSlider.value;
    else if (sender == self.gammaSlider)
        _vpc.gamma = self.gammaSlider.value;
    else if (sender == self.resetVideoFilterButton) {
        [self resetVideoFiltersSliders];
        [_vpc resetFilters];
    } else
        APLog(@"unknown sender for videoFilterSliderAction");
    [self _resetIdleTimer];
}

- (void)appBecameActive:(NSNotification *)aNotification
{
    if ([_delegate movieViewControllerShouldBeDisplayed:self]) {
        [_vpc recoverDisplayedMetadata];
        if (_vpc.videoOutputView != self.movieView) {
            _vpc.videoOutputView = self.movieView;
        }
    }
}

#pragma mark - playback view

- (IBAction)videoDimensionAction:(id)sender
{
    if (sender == self.timeNavigationTitleView.aspectRatioButton) {
        [[VLCPlaybackService sharedInstance] switchAspectRatio:NO];
    }
}

- (IBAction)showPlaybackSpeedView {
    if (!_videoFiltersHidden)
        self.videoFilterView.hidden = _videoFiltersHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    self.playbackSpeedView.hidden = !_playbackSpeedViewHidden;
    _playbackSpeedViewHidden = self.playbackSpeedView.hidden;
    [self _resetIdleTimer];
}

#pragma mark - autorotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    BOOL orientationIslocked = _interfaceIsLocked || [_vpc currentMediaIs360Video];
    UIInterfaceOrientationMask maskFromOrientation = 1 << _lockedOrientation;
    return orientationIslocked ? maskFromOrientation :  UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
           || toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            if (self.artworkImageView.image)
                #if !NEW_UI
                    self.trackNameLabel.hidden = YES;
                #endif

            if (!self->_equalizerView.hidden)
                self->_equalizerView.hidden = YES;

        } completion:nil];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if (_vpc.isPlaying && _controlsHidden)
        [self setControlsHidden:NO animated:YES];
}

- (NSArray *)getVideoOptionsConstraints
{
    return @[
             [_videoOptionsControlBar.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
             [_videoOptionsControlBar.bottomAnchor constraintEqualToAnchor:_controllerPanel.topAnchor constant:-50],
             ];
}

#pragma mark - External Display

- (void)showOnDisplay:(UIView *)view
{
    // if we don't have a renderer we're mirroring and don't want to show the dialog
    BOOL displayExternally = view != _movieView;
    [_playingExternalView shouldDisplay:displayExternally movieView:_movieView];
    _artworkImageView.hidden = displayExternally;

    UIView *displayView = _playingExternalView.displayView;

    if (displayExternally && displayView
        && _movieView.superview == displayView) {
        // Adjust constraints for external display
        [NSLayoutConstraint activateConstraints:@[
            [_movieView.leadingAnchor constraintEqualToAnchor:displayView.leadingAnchor],
            [_movieView.trailingAnchor constraintEqualToAnchor:displayView.trailingAnchor],
            [_movieView.topAnchor constraintEqualToAnchor:displayView.topAnchor],
            [_movieView.bottomAnchor constraintEqualToAnchor:displayView.bottomAnchor],
        ]];
    }

    if (!displayExternally && _movieView.superview != self.view) {
        [self.view addSubview:_movieView];
        [self.view sendSubviewToBack:_movieView];
        _movieView.frame = self.view.frame;
        _artworkImageView.hidden = !_audioOnly;

        // Adjust constraint for local display
        [self setupMovieViewConstraints];
        if (@available(iOS 11, *)) {
            [self adaptMovieViewToNotch];
        }
    }
}

- (void)handleExternalScreenDidConnect:(NSNotification *)notification
{
    [self showOnDisplay:_playingExternalView.displayView];
}

- (void)handleExternalScreenDidDisconnect:(NSNotification *)notification
{
    [self showOnDisplay:_movieView];
}

#pragma mark - Renderers

- (void)setupRendererDiscovererManager
{
    // Create a renderer button for VLCMovieViewController
    _rendererButton = [_services.rendererDiscovererManager setupRendererButton];
    // Setting rendererIcons to white since default is orange
    _rendererButton.tintColor = [UIColor whiteColor];
    [_rendererButton setImage:[UIImage imageNamed:@"renderer"] forState:UIControlStateNormal];
    [_rendererButton setImage:[UIImage imageNamed:@"rendererFull"] forState:UIControlStateSelected];
    __weak typeof(self) weakSelf = self;
    [_services.rendererDiscovererManager addSelectionHandler:^(VLCRendererItem * item) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (item) {
            [strongSelf showOnDisplay:strongSelf->_playingExternalView.displayView];
        } else {
            [strongSelf removedCurrentRendererItem:strongSelf->_vpc.renderer];
        }
    }];
}

#pragma mark - VLCRendererDiscovererManagerDelegate

- (void)removedCurrentRendererItem:(VLCRendererItem *)item
{
    [self showOnDisplay:_movieView];
}

#pragma mark - PlaybackSpeedViewDelegate

- (void)playbackSpeedViewShouldResetIdleTimer:(PlaybackSpeedView *)playbackSpeedView
{
    [self _resetIdleTimer];
}

- (void)playbackSpeedViewSleepTimerHit:(PlaybackSpeedView *)playbackSpeedView
{
    [self showSleepTimer];
}

#pragma mark - VLCVideoOptionsControlBarDelegate

- (void)didSelectMoreOptions:(VLCVideoOptionsControlBar * _Nonnull)optionsBar {
    [self toggleMoreOptionsActionSheet];
}

- (void)didSelectSubtitle:(VLCVideoOptionsControlBar * _Nonnull)optionsBar {
    NSAssert(0, @"didSelectSubtitle not implemented");
}

- (void)didToggleFullScreen:(VLCVideoOptionsControlBar * _Nonnull)optionsBar {
    [_vpc switchAspectRatio:YES];
}

- (void)didToggleInterfaceLock:(VLCVideoOptionsControlBar * _Nonnull)optionsBar {
    [self toggleUILock];
}

- (void)didToggleRepeat:(VLCVideoOptionsControlBar * _Nonnull)optionsBar {
    [self toggleRepeatMode];
}

#pragma mark - VLCMediaMoreOptionsActionSheetDelegate

- (void)toggleMoreOptionsActionSheet
{
    [self presentViewController:_moreOptionsActionSheet animated:false completion:^{
        self->_moreOptionsActionSheet.interfaceDisabled = self->_interfaceIsLocked;
    }];
}

#pragma mark - VLCMediaMoreOptionsActionSheetDelegate

- (void) mediaMoreOptionsActionSheetDidToggleInterfaceLockWithState:(BOOL)state
{
    [self toggleUILock];
}

#pragma mark - VLCMediaNavigationBarDelegate

- (void)mediaNavigationBarDidTapMinimize:(VLCMediaNavigationBar * _Nonnull)mediaNavigationBar {
    [_delegate movieViewControllerDidSelectMinimize:self];
}

- (void)mediaNavigationBarDidLongPressMinimize:(VLCMediaNavigationBar * _Nonnull)mediaNavigationBar {
    [self closePlayback:mediaNavigationBar.minimizePlaybackButton];
}

- (void)mediaNavigationBarDidToggleChromeCast:(VLCMediaNavigationBar * _Nonnull)mediaNavigationBar {
    // TODO: Add current renderer functionality to chromeCast Button
    NSAssert(0, @"didToggleChromeCast not implemented");
}
@end
