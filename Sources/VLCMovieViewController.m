/*****************************************************************************
 * VLCMovieViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
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

#import "VLCStatusLabel.h"

#define FORWARD_SWIPE_DURATION 30
#define BACKWARD_SWIPE_DURATION 10

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
};

@interface VLCMovieViewController () <UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, VLCMultiSelectionViewDelegate, VLCEqualizerViewUIDelegate>
{
    BOOL _controlsHidden;
    BOOL _videoFiltersHidden;
    BOOL _playbackSpeedViewHidden;

    UIActionSheet *_subtitleActionSheet;
    UIActionSheet *_audiotrackActionSheet;

    NSTimer *_idleTimer;
    NSTimer *_sleepTimer;

    BOOL _viewAppeared;
    BOOL _displayRemainingTime;
    BOOL _positionSet;
    BOOL _playerIsSetup;
    BOOL _isScrubbing;
    BOOL _interfaceIsLocked;
    BOOL _switchingTracksNotChapters;
    BOOL _audioOnly;

    BOOL _swipeGesturesEnabled;
    BOOL _variableJumpDurationEnabled;
    UIPinchGestureRecognizer *_pinchRecognizer;
    VLCPanType _currentPanType;
    UIPanGestureRecognizer *_panRecognizer;
    UISwipeGestureRecognizer *_swipeRecognizerLeft;
    UISwipeGestureRecognizer *_swipeRecognizerRight;
    UISwipeGestureRecognizer *_swipeRecognizerUp;
    UISwipeGestureRecognizer *_swipeRecognizerDown;
    UITapGestureRecognizer *_tapRecognizer;
    UITapGestureRecognizer *_tapOnVideoRecognizer;

    UIView *_trackSelectorContainer;
    UITableView *_trackSelectorTableView;

    VLCEqualizerView *_equalizerView;
    VLCMultiSelectionMenuView *_multiSelectionView;

    UIView *_sleepTimerContainer;
    UIDatePicker *_sleepTimeDatePicker;

    NSInteger _mediaDuration;
}

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
    [self.view removeGestureRecognizer:_tapOnVideoRecognizer];

    _tapRecognizer = nil;
    _swipeRecognizerLeft = nil;
    _swipeRecognizerRight = nil;
    _swipeRecognizerUp = nil;
    _swipeRecognizerDown = nil;
    _panRecognizer = nil;
    _pinchRecognizer = nil;
    _tapOnVideoRecognizer = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect rect;

    self.wantsFullScreenLayout = YES;

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

    _trackSwitcherButton.accessibilityLabel = NSLocalizedString(@"OPEN_TRACK_PANEL", nil);
    _trackSwitcherButton.isAccessibilityElement = YES;
    _trackSwitcherButtonLandscape.accessibilityLabel = NSLocalizedString(@"OPEN_TRACK_PANEL", nil);
    _trackSwitcherButtonLandscape.isAccessibilityElement = YES;
    _playbackSpeedButton.accessibilityLabel = _playbackSpeedLabel.text;
    _playbackSpeedButton.isAccessibilityElement = YES;
    _playbackSpeedButtonLandscape.accessibilityLabel = _playbackSpeedLabel.text;
    _playbackSpeedButtonLandscape.isAccessibilityElement = YES;
    _videoFilterButton.accessibilityLabel = NSLocalizedString(@"VIDEO_FILTER", nil);
    _videoFilterButton.isAccessibilityElement = YES;
    _videoFilterButtonLandscape.accessibilityLabel = NSLocalizedString(@"VIDEO_FILTER", nil);
    _videoFilterButtonLandscape.isAccessibilityElement = YES;
    _resetVideoFilterButton.accessibilityLabel = NSLocalizedString(@"VIDEO_FILTER_RESET_BUTTON", nil);
    _resetVideoFilterButton.isAccessibilityElement = YES;
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(playPauseLongPress:)];
    [_playPauseButton addGestureRecognizer:longPressRecognizer];
    _playPauseButton.accessibilityLabel = NSLocalizedString(@"PLAY_PAUSE_BUTTON", nil);
    _playPauseButton.accessibilityHint = NSLocalizedString(@"LONGPRESS_TO_STOP", nil);
    _playPauseButton.isAccessibilityElement = YES;
    UILongPressGestureRecognizer *longPressRecognizerLandscape = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(playPauseLongPress:)];
    [_playPauseButton addGestureRecognizer:longPressRecognizerLandscape];
    _playPauseButtonLandscape.accessibilityLabel = NSLocalizedString(@"PLAY_PAUSE_BUTTON", nil);
    _playPauseButtonLandscape.accessibilityHint = NSLocalizedString(@"LONGPRESS_TO_STOP", nil);
    _playPauseButtonLandscape.isAccessibilityElement = YES;
    _bwdButton.accessibilityLabel = NSLocalizedString(@"BWD_BUTTON", nil);
    _bwdButton.isAccessibilityElement = YES;
    _bwdButtonLandscape.accessibilityLabel = NSLocalizedString(@"BWD_BUTTON", nil);
    _bwdButtonLandscape.isAccessibilityElement = YES;
    _fwdButton.accessibilityLabel = NSLocalizedString(@"FWD_BUTTON", nil);
    _fwdButton.isAccessibilityElement = YES;
    _fwdButtonLandscape.accessibilityLabel = NSLocalizedString(@"FWD_BUTTON", nil);
    _fwdButtonLandscape.isAccessibilityElement = YES;
    _sleepTimerButton.accessibilityLabel = NSLocalizedString(@"BUTTON_SLEEP_TIMER", nil);
    _sleepTimerButton.isAccessibilityElement = YES;
    [_sleepTimerButton setTitle:NSLocalizedString(@"BUTTON_SLEEP_TIMER", nil) forState:UIControlStateNormal];
    if (!SYSTEM_RUNS_IOS7_OR_LATER)
        _sleepTimerButton.hidden = YES;

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

    _playingExternallyTitle.text = NSLocalizedString(@"PLAYING_EXTERNALLY_TITLE", nil);
    _playingExternallyDescription.text = NSLocalizedString(@"PLAYING_EXTERNALLY_DESC", nil);
    if ([[UIDevice currentDevice] hasExternalDisplay])
        [self showOnExternalDisplay];

    self.trackNameLabel.text = self.artistNameLabel.text = self.albumNameLabel.text = @"";

    _movieView.userInteractionEnabled = NO;
    _tapOnVideoRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControlsVisible)];
    _tapOnVideoRecognizer.delegate = self;
    [self.view addGestureRecognizer:_tapOnVideoRecognizer];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _displayRemainingTime = [[defaults objectForKey:kVLCShowRemainingTime] boolValue];
    _swipeGesturesEnabled = [[defaults objectForKey:kVLCSettingPlaybackGestures] boolValue];
    _variableJumpDurationEnabled = [[defaults objectForKey:kVLCSettingVariableJumpDuration] boolValue];

    _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    _pinchRecognizer.delegate = self;
    [self.view addGestureRecognizer:_pinchRecognizer];

    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized)];
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

    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        self.backButton.tintColor = [UIColor colorWithRed:(190.0f/255.0f) green:(190.0f/255.0f) blue:(190.0f/255.0f) alpha:1.];
        self.toolbar.tintColor = [UIColor whiteColor];
        self.toolbar.barStyle = UIBarStyleBlack;

        rect = self.resetVideoFilterButton.frame;
        rect.origin.y = rect.origin.y + 5.;
        self.resetVideoFilterButton.frame = rect;
        rect = self.toolbar.frame;
        rect.size.height = rect.size.height + rect.origin.y;
        rect.origin.y = 0;
        self.toolbar.frame = rect;
    } else {
        [self.toolbar setBackgroundImage:[UIImage imageNamed:@"seekbarBg"] forBarMetrics:UIBarMetricsDefault];
        [self.backButton setBackgroundImage:[UIImage imageNamed:@"playbackDoneButton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self.backButton setBackgroundImage:[UIImage imageNamed:@"playbackDoneButtonHighlight"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    }

    /* FIXME: there is a saner iOS 6+ API for this! */
    /* this looks a bit weird, but we need to support iOS 5 and should show the same appearance */
    void (^initVolumeSlider)(MPVolumeView *) = ^(MPVolumeView *volumeView){
        UISlider *volumeSlider = nil;
        for (id aView in volumeView.subviews){
            if ([[[aView class] description] isEqualToString:@"MPVolumeSlider"]){
                volumeSlider = (UISlider *)aView;
                break;
            }
        }
        if (!SYSTEM_RUNS_IOS7_OR_LATER) {
            [volumeSlider setMinimumTrackImage:[[UIImage imageNamed:@"sliderminiValue"]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 0)] forState:UIControlStateNormal];
            [volumeSlider setMaximumTrackImage:[[UIImage imageNamed:@"slidermaxValue"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 4)] forState:UIControlStateNormal];
            [volumeSlider setThumbImage:[UIImage imageNamed:@"volumeballslider"] forState:UIControlStateNormal];
        } else
            [volumeView setVolumeThumbImage:[UIImage imageNamed:@"modernSliderKnob"] forState:UIControlStateNormal];
        [volumeSlider addTarget:self
                         action:@selector(volumeSliderAction:)
               forControlEvents:UIControlEventValueChanged];
    };

    initVolumeSlider(self.volumeView);
    initVolumeSlider(self.volumeViewLandscape);

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

    if ([[UIDevice currentDevice] speedCategory] >= 3) {
        _trackSelectorTableView.opaque = NO;
        _trackSelectorTableView.backgroundColor = [UIColor clearColor];
    } else
        _trackSelectorTableView.backgroundColor = [UIColor blackColor];
    _trackSelectorTableView.allowsMultipleSelection = YES;

    [self.view addSubview:_trackSelectorContainer];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _equalizerView = [[VLCEqualizerView alloc] initWithFrame:CGRectMake((rect.size.width - 450.) / 2., self.controllerPanel.frame.origin.y - 200., 450., 240.)];
    } else {
        _equalizerView = [[VLCEqualizerView alloc] initWithFrame:CGRectMake((rect.size.width - 450.) / 2., self.controllerPanel.frame.origin.y - 240., 450., 240.)];
    }
    _equalizerView.delegate = self.playbackController;
    _equalizerView.UIdelegate = self;
    _equalizerView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    _equalizerView.hidden = YES;
    [self.view addSubview:_equalizerView];

    /* add sleep timer UI, requires iOS 7 or later */
    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        _sleepTimerContainer = [[VLCFrostedGlasView alloc] initWithFrame:CGRectMake(0., 0., 300., 162.)];
        _sleepTimerContainer.center = self.view.center;
        _sleepTimerContainer.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;

        _sleepTimeDatePicker = [[UIDatePicker alloc] init];
        if ([[UIDevice currentDevice] speedCategory] >= 3) {
            _sleepTimeDatePicker.opaque = NO;
            _sleepTimeDatePicker.backgroundColor = [UIColor clearColor];
        } else
            _sleepTimeDatePicker.backgroundColor = [UIColor blackColor];
        _sleepTimeDatePicker.tintColor = [UIColor VLCLightTextColor];
        _sleepTimeDatePicker.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [_sleepTimerContainer addSubview:_sleepTimeDatePicker];

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
        _sleepTimeDatePicker.minuteInterval = 5;
        _sleepTimeDatePicker.minimumDate = [NSDate date];
        _sleepTimeDatePicker.countDownDuration = 1200.;
        [_sleepTimeDatePicker addTarget:self action:@selector(sleepTimerAction:) forControlEvents:UIControlEventValueChanged];

        [self.view addSubview:_sleepTimerContainer];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidStop:) name:VLCPlaybackControllerPlaybackDidStop object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    /* reset audio meta data views */
    self.artworkImageView.image = nil;
    self.trackNameLabel.text = nil;
    self.artistNameLabel.text = nil;
    self.albumNameLabel.text = nil;

    _swipeGesturesEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingPlaybackGestures] boolValue];
    _variableJumpDurationEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingVariableJumpDuration] boolValue];

    [self.navigationController setNavigationBarHidden:YES animated:YES];

    if (!SYSTEM_RUNS_IOS7_OR_LATER) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    }

    VLCPlaybackController *vpc = self.playbackController;
    vpc.delegate = self;
    [vpc recoverPlaybackState];

    [self setControlsHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _viewAppeared = YES;

    VLCPlaybackController *vpc = self.playbackController;
    [vpc recoverDisplayedMetadata];
    vpc.videoOutputView = nil;
    vpc.videoOutputView = self.movieView;
}

- (void)viewWillLayoutSubviews
{
    CGRect multiSelectionFrame;
    CGRect controllerPanelFrame;

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) {
        controllerPanelFrame = _controllerPanel.frame;
        multiSelectionFrame = (CGRect){CGPointMake(0., 0.), [_multiSelectionView proposedDisplaySize]};
        multiSelectionFrame.origin.x = controllerPanelFrame.size.width - multiSelectionFrame.size.width;
        multiSelectionFrame.origin.y = controllerPanelFrame.origin.y - multiSelectionFrame.size.height;
        _multiSelectionView.frame = multiSelectionFrame;
        _multiSelectionView.showsEqualizer = YES;
        return;
    }

    CGSize viewSize = self.view.frame.size;

    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        [_controllerPanel removeFromSuperview];
        controllerPanelFrame = (CGRect){CGPointMake(0, viewSize.height - _controllerPanelLandscape.frame.size.height), CGSizeMake(viewSize.width, _controllerPanelLandscape.frame.size.height)};
        _controllerPanelLandscape.frame = controllerPanelFrame;
        [self.view addSubview:_controllerPanelLandscape];
        _multiSelectionView.showsEqualizer = YES;
        multiSelectionFrame = (CGRect){CGPointMake(0., 0.), [_multiSelectionView proposedDisplaySize]};
        multiSelectionFrame.origin.x = controllerPanelFrame.size.width - multiSelectionFrame.size.width;
        multiSelectionFrame.origin.y = controllerPanelFrame.origin.y - multiSelectionFrame.size.height;
    } else {
        [_controllerPanelLandscape removeFromSuperview];
        controllerPanelFrame = (CGRect){CGPointMake(0, viewSize.height - _controllerPanel.frame.size.height), CGSizeMake(viewSize.width, _controllerPanel.frame.size.height)};
        _controllerPanel.frame = controllerPanelFrame;
        [self.view addSubview:_controllerPanel];
        _multiSelectionView.showsEqualizer = NO;
        multiSelectionFrame = (CGRect){CGPointMake(0., 0.), [_multiSelectionView proposedDisplaySize]};
        multiSelectionFrame.origin.x = controllerPanelFrame.size.width - multiSelectionFrame.size.width;
        multiSelectionFrame.origin.y = controllerPanelFrame.origin.y - multiSelectionFrame.size.height;
    }

    _multiSelectionView.frame = multiSelectionFrame;
}

- (void)viewWillDisappear:(BOOL)animated
{
    VLCPlaybackController *vpc = self.playbackController;
    if (vpc.videoOutputView == self.movieView) {
        vpc.videoOutputView = nil;
    }

    _viewAppeared = NO;
    if (_idleTimer) {
        [_idleTimer invalidate];
        _idleTimer = nil;
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if (!SYSTEM_RUNS_IOS7_OR_LATER)
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [super viewWillDisappear:animated];

    // hide filter UI for next run
    if (!_videoFiltersHidden)
        _videoFiltersHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    if (!_playbackSpeedViewHidden)
        _playbackSpeedViewHidden = YES;

    [[NSUserDefaults standardUserDefaults] setBool:_displayRemainingTime forKey:kVLCShowRemainingTime];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - controls visibility

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    LOCKCHECK;

    if (!_swipeGesturesEnabled)
        return;

    if (recognizer.velocity < 0.)
        [self closePlayback:nil];
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
        _controllerPanelLandscape.alpha = 0.0f;
        _controllerPanelLandscape.hidden = !_videoFiltersHidden;
        _toolbar.alpha = 0.0f;
        _toolbar.hidden = NO;
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
        _controllerPanel.alpha = alpha;
        _controllerPanelLandscape.alpha = alpha;
        _toolbar.alpha = alpha;
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
        _controllerPanelLandscape.hidden = _videoFiltersHidden ? _controlsHidden : NO;
        _toolbar.hidden = _controlsHidden;
        _videoFilterView.hidden = _videoFiltersHidden;
        _playbackSpeedView.hidden = _playbackSpeedViewHidden;
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

    _volumeView.hidden = _volumeViewLandscape.hidden = _controllerPanel.hidden;
}

- (void)toggleControlsVisible
{
    if (!_trackSelectorContainer.hidden) {
        for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers)
            [recognizer setEnabled:YES];
    }

    if (_controlsHidden && !_videoFiltersHidden)
        _videoFiltersHidden = YES;

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

- (void)idleTimerExceeded
{
    _idleTimer = nil;
    if (!_controlsHidden)
        [self toggleControlsVisible];

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

#pragma mark - controls

- (IBAction)closePlayback:(id)sender
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
        self.playbackController.mediaPlayer.position = self.timeNavigationTitleView.positionSlider.value;
        [self.playbackController setNeedsMetadataUpdate];
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

- (IBAction)volumeSliderAction:(id)sender
{
    LOCKCHECK;

    [self _resetIdleTimer];
}

- (void)playPauseLongPress:(UILongPressGestureRecognizer *)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        {   UIImage *image = [UIImage imageNamed:@"stopIcon"];
            [_playPauseButton setImage:image forState:UIControlStateNormal];
            [_playPauseButtonLandscape setImage:image forState:UIControlStateNormal];
        }
            break;
        case UIGestureRecognizerStateEnded:
            [self.playbackController stopPlayback];
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self updatePlayPauseButton];
            break;
        default:
            break;
    }
}

- (void)updatePlayPauseButton
{
    const BOOL isPlaying = self.playbackController.isPlaying;
    UIImage *playPauseImage = isPlaying ? [UIImage imageNamed:@"pauseIcon"] : [UIImage imageNamed:@"playIcon"];
    [_playPauseButton setImage:playPauseImage forState:UIControlStateNormal];
    [_playPauseButtonLandscape setImage:playPauseImage forState:UIControlStateNormal];
}

#pragma mark - playback controller delegation

- (VLCPlaybackController *)playbackController
{
    if (!_playbackController) {
        _playbackController = [VLCPlaybackController sharedInstance];
    }
    return _playbackController;
}

- (void)playbackPositionUpdated:(VLCPlaybackController *)controller
{
    VLCMediaPlayer *mediaPlayer = controller.mediaPlayer;
    if (!_isScrubbing) {
        self.timeNavigationTitleView.positionSlider.value = [mediaPlayer position];
    }

    if (_displayRemainingTime)
        [self.timeNavigationTitleView.timeDisplayButton setTitle:[[mediaPlayer remainingTime] stringValue] forState:UIControlStateNormal];
    else
        [self.timeNavigationTitleView.timeDisplayButton setTitle:[[mediaPlayer time] stringValue] forState:UIControlStateNormal];
    [self.timeNavigationTitleView setNeedsLayout];
}

- (void)prepareForMediaPlayback:(VLCPlaybackController *)controller
{
    self.trackNameLabel.text = self.artistNameLabel.text = self.albumNameLabel.text = @"";
    self.timeNavigationTitleView.positionSlider.value = 0.;
    [self.timeNavigationTitleView.timeDisplayButton setTitle:@"" forState:UIControlStateNormal];
    self.timeNavigationTitleView.timeDisplayButton.accessibilityLabel = @"";
    if (![[UIDevice currentDevice] hasExternalDisplay])
        self.brightnessSlider.value = [UIScreen mainScreen].brightness * 2.;
    [_equalizerView reloadData];

    float playbackRate = controller.playbackRate;
    self.playbackSpeedSlider.value = log2(playbackRate);
    self.playbackSpeedIndicator.text = [NSString stringWithFormat:@"%.2fx", playbackRate];

    float audioDelay = controller.audioDelay;
    self.audioDelaySlider.value = audioDelay;
    self.audioDelayIndicator.text = [NSString stringWithFormat:@"%1.00f s", audioDelay];

    float subtitleDelay = controller.subtitleDelay;
    self.spuDelaySlider.value = subtitleDelay;
    self.spuDelayIndicator.text = [NSString stringWithFormat:@"%1.00f s", subtitleDelay];

    [self _resetIdleTimer];
}

- (void)playbackDidStop:(NSNotification *)notification
{
    [self closePlayback:nil];
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

    [self updatePlayPauseButton];

    if (currentMediaHasTrackToChooseFrom) {
        self.trackSwitcherButton.hidden = NO;
        self.trackSwitcherButtonLandscape.hidden = NO;
    } else {
        self.trackSwitcherButton.hidden = YES;
        self.trackSwitcherButtonLandscape.hidden = YES;
    }

    if (currentMediaHasChapters)
        _multiSelectionView.mediaHasChapters = YES;
    else
        _multiSelectionView.mediaHasChapters = NO;
}

- (void)showStatusMessage:(NSString *)statusMessage forPlaybackController:(VLCPlaybackController *)controller
{
    [self showStatusMessage:statusMessage];
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

    self.timeNavigationTitleView.hideAspectRatio = audioOnly;
    self.timeNavigationTitleView.positionSlider.hidden = NO;

    self.videoFilterButton.hidden = audioOnly;

    _audioOnly = audioOnly;
}

- (IBAction)playPause
{
    LOCKCHECK;

    [self.playbackController playPause];
}

- (IBAction)forward:(id)sender
{
    LOCKCHECK;

    [self.playbackController forward];
}

- (IBAction)backward:(id)sender
{
    LOCKCHECK;

    [self.playbackController backward];
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
                self.controllerPanelLandscape.hidden = YES;
                self.toolbar.hidden = YES;
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
            self.controllerPanelLandscape.hidden = YES;
        }
    }

    self.videoFilterView.hidden = _videoFiltersHidden = YES;
    _sleepTimerContainer.alpha = 1.;
    _sleepTimerContainer.hidden = NO;
}

- (IBAction)sleepTimerAction:(id)sender
{
    if (_sleepTimer) {
        [_sleepTimer invalidate];
        _sleepTimer = nil;
    }
    _sleepTimer = [NSTimer scheduledTimerWithTimeInterval:_sleepTimeDatePicker.countDownDuration target:self selector:@selector(closePlayback:) userInfo:nil repeats:NO];
}

- (void)moreActions:(id)sender
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
        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
            _multiSelectionView.showsEqualizer = YES;
        else
            _multiSelectionView.showsEqualizer = NO;
    }

    CGRect workFrame = _multiSelectionView.frame;
    workFrame.size = [_multiSelectionView proposedDisplaySize];
    workFrame.origin.x = self.toolbar.frame.size.width - workFrame.size.width;

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

- (void)showStatusMessage:(NSString *)statusMessage
{
    [self.statusLabel showStatusMessage:statusMessage];
}

#pragma mark - multi-select delegation

- (void)toggleUILock
{
    _interfaceIsLocked = !_interfaceIsLocked;

    _multiSelectionView.displayLock = _interfaceIsLocked;
    self.backButton.enabled = !_interfaceIsLocked;
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
                self.controllerPanelLandscape.hidden = YES;
                self.toolbar.hidden = YES;
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
                self.controllerPanelLandscape.hidden = YES;
            }
        }

        self.videoFilterView.hidden = _videoFiltersHidden = YES;
    } else {
        _trackSelectorContainer.hidden = YES;
    }
}

- (void)toggleRepeatMode
{
    LOCKCHECK;

    VLCMediaListPlayer *listPlayer = self.playbackController.listPlayer;

    if (listPlayer.repeatMode == VLCDoNotRepeat) {
        listPlayer.repeatMode = VLCRepeatCurrentItem;
        _multiSelectionView.displayRepeatOne = YES;
    } else {
        listPlayer.repeatMode = VLCDoNotRepeat;
        _multiSelectionView.displayRepeatOne = NO;
    }
}

- (void)toggleShuffleMode
{
    LOCKCHECK;

    // FIXME: missing implementation
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
    VLCMediaPlayer *mediaPlayer = self.playbackController.mediaPlayer;

    if (_switchingTracksNotChapters == YES) {
        if (mediaPlayer.audioTrackIndexes.count > 2)
            ret++;

        if (mediaPlayer.videoSubTitlesIndexes.count > 1)
            ret++;
    } else {
        if ([mediaPlayer countOfTitles] > 1)
            ret++;

        if ([mediaPlayer chaptersForTitleIndex:mediaPlayer.currentTitleIndex].count > 1)
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
    VLCMediaPlayer *mediaPlayer = self.playbackController.mediaPlayer;

    if (_switchingTracksNotChapters == YES) {
        if (mediaPlayer.audioTrackIndexes.count > 2 && section == 0)
            return NSLocalizedString(@"CHOOSE_AUDIO_TRACK", nil);

        if (mediaPlayer.videoSubTitlesIndexes.count > 1)
            return NSLocalizedString(@"CHOOSE_SUBTITLE_TRACK", nil);
    } else {
        if ([mediaPlayer countOfTitles] > 1 && section == 0)
            return NSLocalizedString(@"CHOOSE_TITLE", nil);

        if ([mediaPlayer chaptersForTitleIndex:mediaPlayer.currentTitleIndex].count > 1)
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
    VLCMediaPlayer *mediaPlayer = self.playbackController.mediaPlayer;
    BOOL cellShowsCurrentTrack = NO;

    if (_switchingTracksNotChapters == YES) {
        NSArray *indexArray;
        if ([mediaPlayer numberOfAudioTracks] > 2 && section == 0) {
            indexArray = mediaPlayer.audioTrackIndexes;

            if ([indexArray indexOfObject:[NSNumber numberWithInt:mediaPlayer.currentAudioTrackIndex]] == row)
                cellShowsCurrentTrack = YES;

            cell.textLabel.text = [NSString stringWithFormat:@"%@", mediaPlayer.audioTrackNames[row]];
        } else {
            indexArray = mediaPlayer.videoSubTitlesIndexes;

            if ([indexArray indexOfObject:[NSNumber numberWithInt:mediaPlayer.currentVideoSubTitleIndex]] == row)
                cellShowsCurrentTrack = YES;

            cell.textLabel.text = [NSString stringWithFormat:@"%@", mediaPlayer.videoSubTitlesNames[row]];
        }
    } else {
        if ([mediaPlayer countOfTitles] > 1 && section == 0) {
            cell.textLabel.text = mediaPlayer.titles[row];

            if (row == mediaPlayer.currentTitleIndex)
                cellShowsCurrentTrack = YES;
        } else {
            cell.textLabel.text = [mediaPlayer chaptersForTitleIndex:mediaPlayer.currentTitleIndex][row];

            if (row == mediaPlayer.currentChapterIndex)
                cellShowsCurrentTrack = YES;
        }
    }
    [cell setShowsCurrentTrack:cellShowsCurrentTrack];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    VLCMediaPlayer *mediaPlayer = self.playbackController.mediaPlayer;

    if (_switchingTracksNotChapters == YES) {
        NSInteger audioTrackCount = mediaPlayer.audioTrackIndexes.count;

        if (audioTrackCount > 2 && section == 0)
            return audioTrackCount;

        return mediaPlayer.videoSubTitlesIndexes.count;
    } else {
        if ([mediaPlayer countOfTitles] > 1 && section == 0)
            return [mediaPlayer countOfTitles];
        else
            return [mediaPlayer chaptersForTitleIndex:mediaPlayer.currentTitleIndex].count;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSInteger index = indexPath.row;
    VLCMediaPlayer *mediaPlayer = self.playbackController.mediaPlayer;

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
        if ([mediaPlayer countOfTitles] > 1 && indexPath.section == 0)
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

- (void)tapRecognized
{
    LOCKCHECK;

    if (!_swipeGesturesEnabled)
        return;

    VLCPlaybackController *vpc = self.playbackController;

    if ([vpc.mediaPlayer isPlaying]) {
        [vpc.listPlayer pause];
        [self.statusLabel showStatusMessage:@"  ▌▌"];
    } else {
        [vpc.listPlayer play];
        [self.statusLabel showStatusMessage:@" ►"];
    }
}

- (VLCPanType)detectPanTypeForPan:(UIPanGestureRecognizer*)panRecognizer
{
    NSString *deviceType = [[UIDevice currentDevice] model];
    CGPoint location = [panRecognizer locationInView:self.view];
    CGFloat position = location.x;

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = .0;
    if (orientation == UIDeviceOrientationPortrait)
        screenWidth = screenRect.size.width;
    else
        screenWidth = screenRect.size.height;

    VLCPanType panType = VLCPanTypeVolume; // default or right side of the screen
    if (position < screenWidth / 2)
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

    if (!_swipeGesturesEnabled)
        return;

    CGFloat panDirectionX = [panRecognizer velocityInView:self.view].x;
    CGFloat panDirectionY = [panRecognizer velocityInView:self.view].y;

    if (panRecognizer.state == UIGestureRecognizerStateBegan) // Only detect panType when began to allow more freedom
        _currentPanType = [self detectPanTypeForPan:panRecognizer];

    if (_currentPanType == VLCPanTypeSeek) {
        VLCMediaPlayer *mediaPlayer = self.playbackController.mediaPlayer;
        double timeRemainingDouble = (-mediaPlayer.remainingTime.intValue*0.001);
        int timeRemaining = timeRemainingDouble;

        if (panDirectionX > 0) {
            if (timeRemaining > 2 ) // to not go outside duration , video will stop
                [mediaPlayer jumpForward:1];
        } else
            [mediaPlayer jumpBackward:1];
    } else if (_currentPanType == VLCPanTypeVolume) {
        MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
        if (panDirectionY > 0)
            musicPlayer.volume -= 0.01;
        else
            musicPlayer.volume += 0.01;
    } else if (_currentPanType == VLCPanTypeBrightness) {
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
    }

    if (panRecognizer.state == UIGestureRecognizerStateEnded) {
        VLCPlaybackController *vpc = self.playbackController;
        _currentPanType = VLCPanTypeNone;
        if ([vpc.mediaPlayer isPlaying])
            [vpc.listPlayer play];
    }
}

- (void)swipeRecognized:(UISwipeGestureRecognizer*)swipeRecognizer
{
    LOCKCHECK;

    if (!_swipeGesturesEnabled)
        return;

    NSString * hudString = @" ";
    VLCPlaybackController *vpc = self.playbackController;
    VLCMediaPlayer *mediaPlayer = vpc.mediaPlayer;
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
            [vpc.listPlayer play];

        [self.statusLabel showStatusMessage:hudString];
    }
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
            self.controllerPanelLandscape.hidden = YES;
        }
    }

    self.videoFilterView.hidden = !_videoFiltersHidden;
    _videoFiltersHidden = self.videoFilterView.hidden;
}

- (IBAction)videoFilterSliderAction:(id)sender
{
    VLCMediaPlayer *mediaPlayer = self.playbackController.mediaPlayer;

    if (sender == self.hueSlider)
        mediaPlayer.hue = (int)self.hueSlider.value;
    else if (sender == self.contrastSlider)
        mediaPlayer.contrast = self.contrastSlider.value;
    else if (sender == self.brightnessSlider) {
        if ([[UIDevice currentDevice] hasExternalDisplay])
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
    self.brightnessSlider.value = [(UIScreen *)notification.object brightness] * 2.;
}

#pragma mark - playback view
- (IBAction)playbackSliderAction:(UISlider *)sender
{
    LOCKCHECK;
    VLCPlaybackController *vpc = self.playbackController;

    if (sender == _playbackSpeedSlider) {
        double speed = exp2(sender.value);
        vpc.playbackRate = speed;
        self.playbackSpeedIndicator.text = [NSString stringWithFormat:@"%.2fx", speed];
    } else if (sender == _audioDelaySlider) {
        double delay = sender.value;
        vpc.audioDelay = delay;
        _audioDelayIndicator.text = [NSString stringWithFormat:@"%1.2f s", delay];
    } else if (sender == _spuDelaySlider) {
        double delay = sender.value;
        vpc.subtitleDelay = delay;
        _spuDelayIndicator.text = [NSString stringWithFormat:@"%1.00f s", delay];
    }

    [self _resetIdleTimer];
}

- (IBAction)videoDimensionAction:(id)sender
{
    LOCKCHECK;

    if (sender == self.playbackSpeedButton || sender == self.playbackSpeedButtonLandscape) {
        if (!_videoFiltersHidden)
            self.videoFilterView.hidden = _videoFiltersHidden = YES;

        if (_equalizerView.hidden == NO)
            _equalizerView.hidden = YES;

        self.playbackSpeedView.hidden = !_playbackSpeedViewHidden;
        _playbackSpeedViewHidden = self.playbackSpeedView.hidden;
        [self _resetIdleTimer];
    } else if (sender == self.timeNavigationTitleView.aspectRatioButton) {
        [self.playbackController switchAspectRatio];
    }
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (self.artworkImageView.image)
            self.trackNameLabel.hidden = UIInterfaceOrientationIsLandscape(toInterfaceOrientation);

        if (!_equalizerView.hidden)
            _equalizerView.hidden = YES;
    }
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
