/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFullscreenMovieTVViewController.h"
#import "VLCPlaybackControlsFocusView.h"
#import "VLCPlayerControlsBar.h"
#import "VLCIRTVTapGestureRecognizer.h"
#import "VLCHTTPUploaderController.h"
#import "VLCSiriRemoteGestureRecognizer.h"
#import "VLCNetworkImageView.h"
#import "VLCMetaData.h"
#import "VLCActivityManager.h"
#import "VLCStatusLabel.h"
#import "VLC-Swift.h"

typedef NS_ENUM(NSInteger, VLCPlayerScanState)
{
    VLCPlayerScanStateNone,
    VLCPlayerScanStateForward2,
    VLCPlayerScanStateForward4,
};

@interface VLCFullscreenMovieTVViewController () <UIGestureRecognizerDelegate>
{
    VLCPlayerControlsBar *_controlsBar;
    UIView *_scrimView;
    BOOL _controlsRowFocused;
    NSArray<UIGestureRecognizer *> *_transportGestureRecognizers;
    VLCStatusLabel *_statusLabel;
}

@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) NSTimer *audioDescriptionScrollTimer;
@property (nonatomic) NSTimer *hidePlaybackControlsViewAfterDelayTimer;
@property (nonatomic) NSNumber *scanSavedPlaybackRate;
@property (nonatomic) VLCPlayerScanState scanState;
@property (nonatomic) NSString *lastArtist;

@property (nonatomic, readonly, getter=isSeekable) BOOL seekable;

@property (nonatomic) NSSet<UIGestureRecognizer *> *simultaneousGestureRecognizers;
@property (nonatomic) BOOL disabledIdleTimer;

@property (nonatomic) BOOL playbackUIShouldHide;

@property (nonatomic) GameControllerManager *gameControllerManager;
// 360 Support
@property (nonatomic) CGPoint projectionLocation;
@property (nonatomic) CGFloat yaw;
@property (nonatomic) CGFloat pitch;

@end

@interface VLCGradientScrimView : UIView
@end

@implementation VLCGradientScrimView

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
        gradientLayer.colors = @[(id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor,
                                 (id)[UIColor colorWithWhite:0.0 alpha:0.7].CGColor];
        gradientLayer.locations = @[@0.0, @1.0];
        self.userInteractionEnabled = NO;
    }
    return self;
}

@end

@implementation VLCFullscreenMovieTVViewController

+ (instancetype)fullscreenMovieTVViewController
{
    return [[self alloc] initWithNibName:nil bundle:nil];
}

- (void)viewDidLoad
{
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(playbackDidStop)
                   name:VLCPlaybackServicePlaybackDidStop
                 object:nil];
    [center addObserver:self
               selector:@selector(playbackDidStop)
                   name:VLCPlaybackServicePlaybackDidFail
                 object:nil];

    _movieView.userInteractionEnabled = NO;

    self.titleLabel.text = @"";

    self.transportBar.bufferStartFraction = 0.0;
    self.transportBar.bufferEndFraction = 1.0;
    self.transportBar.playbackFraction = 0.0;
    self.transportBar.scrubbingFraction = 0.0;

    self.dimmingView.alpha = 0.0;
    self.bottomOverlayView.alpha = 0.0;

    self.bufferingLabel.text = NSLocalizedString(@"PLEASE_WAIT", nil);

    self.pitch = 0;
    self.yaw = 0;

     self.gameControllerManager = [[GameControllerManager alloc] init];
    
    _disabledIdleTimer = NO;

    NSMutableSet<UIGestureRecognizer *> *simultaneousGestureRecognizers = [NSMutableSet set];

    // Panning and Swiping
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    panGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:panGestureRecognizer];
    [simultaneousGestureRecognizers addObject:panGestureRecognizer];

    // Button presses
    UITapGestureRecognizer *playpauseGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPausePressed)];
    playpauseGesture.allowedPressTypes = @[@(UIPressTypePlayPause)];
    [self.view addGestureRecognizer:playpauseGesture];

    UITapGestureRecognizer *menuTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuButtonPressed:)];
    menuTapGestureRecognizer.allowedPressTypes = @[@(UIPressTypeMenu)];
    menuTapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:menuTapGestureRecognizer];

    //  IR only recognizer
    UITapGestureRecognizer *upArrowRecognizer = [[VLCIRTVTapGestureRecognizer alloc] initWithTarget:self action:@selector(handleIRPressUp)];
    upArrowRecognizer.allowedPressTypes = @[@(UIPressTypeUpArrow)];
    [self.view addGestureRecognizer:upArrowRecognizer];

    UITapGestureRecognizer *downArrowRecognizer = [[VLCIRTVTapGestureRecognizer alloc] initWithTarget:self action:@selector(handleIRPressDown)];
    downArrowRecognizer.allowedPressTypes = @[@(UIPressTypeDownArrow)];
    [self.view addGestureRecognizer:downArrowRecognizer];

    UITapGestureRecognizer *leftArrowRecognizer = [[VLCIRTVTapGestureRecognizer alloc] initWithTarget:self action:@selector(handleIRPressLeft)];
    leftArrowRecognizer.allowedPressTypes = @[@(UIPressTypeLeftArrow)];
    [self.view addGestureRecognizer:leftArrowRecognizer];

    UITapGestureRecognizer *rightArrowRecognizer = [[VLCIRTVTapGestureRecognizer alloc] initWithTarget:self action:@selector(handleIRPressRight)];
    rightArrowRecognizer.allowedPressTypes = @[@(UIPressTypeRightArrow)];
    [self.view addGestureRecognizer:rightArrowRecognizer];

    UILongPressGestureRecognizer *rightLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightLongPress:)];
    rightLongPressGestureRecognizer.allowedPressTypes = @[@(UIPressTypeRightArrow)];
    rightLongPressGestureRecognizer.minimumPressDuration = 0.5;
    [self.view addGestureRecognizer:rightLongPressGestureRecognizer];

    UILongPressGestureRecognizer *leftLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftLongPress:)];
    leftLongPressGestureRecognizer.allowedPressTypes = @[@(UIPressTypeLeftArrow)];
    leftLongPressGestureRecognizer.minimumPressDuration = 0.5;
    [self.view addGestureRecognizer:leftLongPressGestureRecognizer];

    // Siri remote arrow presses
    VLCSiriRemoteGestureRecognizer *siriArrowRecognizer = [[VLCSiriRemoteGestureRecognizer alloc] initWithTarget:self action:@selector(handleSiriRemote:)];
    siriArrowRecognizer.delegate = self;
    [self.view addGestureRecognizer:siriArrowRecognizer];
    [simultaneousGestureRecognizers addObject:siriArrowRecognizer];

    // Reveal / dismiss the controls row
    UISwipeGestureRecognizer *revealRowRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(focusControlsRow)];
    revealRowRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    revealRowRecognizer.delegate = self;
    [self.view addGestureRecognizer:revealRowRecognizer];
    [simultaneousGestureRecognizers addObject:revealRowRecognizer];

    UISwipeGestureRecognizer *dismissRowRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(unfocusControlsRow)];
    dismissRowRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    dismissRowRecognizer.delegate = self;
    [self.view addGestureRecognizer:dismissRowRecognizer];
    [simultaneousGestureRecognizers addObject:dismissRowRecognizer];

    self.simultaneousGestureRecognizers = simultaneousGestureRecognizers;

    _transportGestureRecognizers = @[panGestureRecognizer,
                                     leftArrowRecognizer,
                                     rightArrowRecognizer,
                                     rightLongPressGestureRecognizer,
                                     leftLongPressGestureRecognizer,
                                     siriArrowRecognizer];

    [self setupScrimGradient];
    [self setupControlButtonsRow];

    self.gameControllerManager.delegate = self;
    [super viewDidLoad];

    _statusLabel = [[VLCStatusLabel alloc] init];
    [_statusLabel setHidden:YES];
    [_statusLabel setTextColor:PresentationTheme.current.colors.lightTextColor];
    [self.view addSubview:_statusLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - view events

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.audioView.hidden = YES;
    self.audioDescriptionTextView.hidden = YES;
    self.audioTitleLabel.hidden = YES;
    self.audioArtistLabel.hidden = YES;
    self.audioAlbumNameLabel.hidden = YES;

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    vpc.delegate = self;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kVLCPlayerShouldRememberState]) {
        vpc.shuffleMode = [defaults boolForKey:kVLCPlayerIsShuffleEnabled];
        vpc.repeatMode = [defaults integerForKey:kVLCPlayerIsRepeatEnabled];
    }

    self.playbackUIShouldHide = [defaults boolForKey:kVLCPlayerUIShouldHide];
    if (self.playbackUIShouldHide) {
        [self.coneLoadingView stopAnimating];
        self.bufferingLabel.hidden = YES;
        self.audioArtworkImageView.image = nil;
        self.audioLargeBackgroundImageView.image = nil;
    } else {
        [self updateThumbnailImageViewsWith:[UIImage imageNamed:@"about-app-icon"]];
    }

    [vpc recoverPlaybackState];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    [vpc recoverDisplayedMetadata];
    vpc.videoOutputView = nil;
    vpc.videoOutputView = self.movieView;
    [vpc disableSubtitlesIfNeeded];
    [self.gameControllerManager startMonitoring];
}

- (void)viewWillDisappear:(BOOL)animated
{
    /* Only tear playback down when we are actually going away. */
    if (!self.isBeingDismissed && !self.isMovingFromParentViewController) {
        [super viewWillDisappear:animated];
        return;
    }

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    if (vpc.videoOutputView == self.movieView) {
        vpc.videoOutputView = nil;
    }

    [vpc stopPlayback];

    [self stopAudioDescriptionAnimation];

    /* delete potentially downloaded subs */
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* tempSubsDirPath = [searchPaths[0] stringByAppendingPathComponent:@"tempsubs"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:tempSubsDirPath])
        [fileManager removeItemAtPath:tempSubsDirPath error:nil];

    [self enableIdleTimer];

    self.lastArtist = nil;

    [super viewWillDisappear:animated];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - UIActions
- (void)playPausePressed
{
    [self showPlaybackControlsIfNeededForUserInteraction];

    [self setScanState:VLCPlayerScanStateNone];

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    if (self.transportBar.scrubbing) {
        [self selectButtonPressed];
    } else {
        [vpc playPause];
    }
}

- (void)panGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMediaPlayerTitleDescription *title = [vpc currentTitleDescription];
    if (title != nil) {
        if (title.menu) {
            return;
        }
    }

    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            return;
        default:
            break;
    }

    VLCTransportBar *bar = self.transportBar;

    UIView *view = self.view;
    CGPoint translation = [panGestureRecognizer translationInView:view];
    BOOL canScrub = self.canScrub;

    if (!bar.scrubbing) {
        if (ABS(translation.x) > 150.0) {
            if (self.isSeekable && canScrub) {
                [self startScrubbing];
            } else {
                return;
            }
        } else {
            return;
        }
    }

    if (!canScrub) {
        return;
    }

    [self showPlaybackControlsIfNeededForUserInteraction];
    [self setScanState:VLCPlayerScanStateNone];

    const CGFloat scaleFactor = 8.0;
    CGFloat fractionInView = translation.x / CGRectGetWidth(view.bounds) / scaleFactor;
    CGFloat scrubbingFraction = MAX(0.0, MIN(bar.scrubbingFraction + fractionInView,1.0));

    if (ABS(scrubbingFraction - bar.playbackFraction)<0.005) {
        scrubbingFraction = bar.playbackFraction;
    } else {
        translation.x = 0.0;
        [panGestureRecognizer setTranslation:translation inView:view];
    }

    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        bar.scrubbingFraction = scrubbingFraction;
    }
                     completion:nil];
    [self updateTimeLabelsForScrubbingFraction:scrubbingFraction];
}

- (void)selectButtonPressed
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMediaPlayerTitleDescription *title = [vpc currentTitleDescription];
    if (title != nil) {
        if (title.menu) {
            [vpc performNavigationAction:VLCMediaPlaybackNavigationActionActivate];
            return;
        }
    }

    [self showPlaybackControlsIfNeededForUserInteraction];
    [self setScanState:VLCPlayerScanStateNone];

    VLCTransportBar *bar = self.transportBar;
    if (bar.scrubbing) {
        bar.playbackFraction = bar.scrubbingFraction;
        [self stopScrubbing];
        [vpc setPlaybackPosition:bar.scrubbingFraction];
    } else {
        [vpc playPause];
    }
}

- (void)menuButtonPressed:(UITapGestureRecognizer *)recognizer
{
    VLCTransportBar *bar = self.transportBar;
    if (bar.scrubbing) {
        [UIView animateWithDuration:0.3 animations:^{
            bar.scrubbingFraction = bar.playbackFraction;
            [bar layoutIfNeeded];
        }];
        [self updateTimeLabelsForScrubbingFraction:bar.playbackFraction];
        [self stopScrubbing];
        [self hidePlaybackControlsIfNeededAfterDelay];
    }
}

- (void)handleIRPressUp
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMediaPlayerTitleDescription *title = [vpc currentTitleDescription];
    if (title.menu) {
        [vpc performNavigationAction:VLCMediaPlaybackNavigationActionUp];
        return;
    }
    [self focusControlsRow];
}

- (void)handleIRPressDown
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMediaPlayerTitleDescription *title = [vpc currentTitleDescription];
    if (title.menu) {
        [vpc performNavigationAction:VLCMediaPlaybackNavigationActionDown];
        return;
    }
    [self unfocusControlsRow];
}

- (void)handleIRPressLeft
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMediaPlayerTitleDescription *title = [vpc currentTitleDescription];
    if (title != nil) {
        if (title.menu) {
            [vpc performNavigationAction:VLCMediaPlaybackNavigationActionLeft];
            return;
        }
    }

    [self showPlaybackControlsIfNeededForUserInteraction];

    [self jumpBackward:1];
}

- (void)handleIRPressRight
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMediaPlayerTitleDescription *title = [vpc currentTitleDescription];
    if (title != nil) {
        if (title.menu) {
            [vpc performNavigationAction:VLCMediaPlaybackNavigationActionRight];
            return;
        }
    }

    [self showPlaybackControlsIfNeededForUserInteraction];

    [self jumpForward:1];
}

- (void)handleRightLongPress:(UILongPressGestureRecognizer *)recognizer
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];

    if (!vpc.isPlaying || !self.isSeekable || recognizer.state == UIGestureRecognizerStateEnded) {
        return;
    }

    [self showPlaybackControlsIfNeededForUserInteraction];

    [self scanForwardNext];
}

- (void)handleLeftLongPress:(UILongPressGestureRecognizer *)recognizer
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];

    if (!vpc.isPlaying || !self.isSeekable || recognizer.state == UIGestureRecognizerStateEnded) {
        return;
    }

    if (_scanState == VLCPlayerScanStateNone) {
        return;
    }

    [self showPlaybackControlsIfNeededForUserInteraction];

    [self scanForwardPrevious];
}

- (void)updateProjection:(VLCSiriRemoteGestureRecognizer *)recognizer
{
    CGPoint newLocationInView = [recognizer locationInView:self.view];

    CGFloat diffX = newLocationInView.x - self.projectionLocation.x;
    CGFloat diffY = newLocationInView.y - self.projectionLocation.y;
    self.projectionLocation = newLocationInView;

    CGSize screenPixelSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);

    CGFloat diffYaw = 85 * -diffX / screenPixelSize.width;
    CGFloat diffPitch = 85 * -diffY / screenPixelSize.width;

    [self applyYaw:diffYaw pitch:diffPitch];
}

- (void)applyYaw:(CGFloat)yaw pitch:(CGFloat)pitch
{
    self.yaw += yaw;
    self.pitch = self.pitch  + MIN(MAX(pitch, -90), 90);

    [self setPitch: self.pitch + pitch];

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    [vpc updateViewpoint:self.yaw pitch:self.pitch roll:0 fov:85 absolute:YES];
}

- (void)handleSiriRemote:(VLCSiriRemoteGestureRecognizer *)recognizer
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMediaPlayerTitleDescription *title = [vpc currentTitleDescription];
    if (title != nil) {
        if (title.menu) {
            switch (recognizer.state) {
                case UIGestureRecognizerStateBegan:
                case UIGestureRecognizerStateChanged:
                    if (recognizer.isLongPress) {
                        [vpc performNavigationAction:VLCMediaPlaybackNavigationActionActivate];
                        break;
                    }
                    break;
                case UIGestureRecognizerStateEnded:
                    if (recognizer.isClick && !recognizer.isLongPress) {
                        [vpc performNavigationAction:VLCMediaPlaybackNavigationActionActivate];
                    } else {
                        switch (recognizer.touchLocation) {
                            case VLCSiriRemoteTouchLocationLeft:
                                [vpc performNavigationAction:VLCMediaPlaybackNavigationActionLeft];
                                break;
                            case VLCSiriRemoteTouchLocationRight:
                                [vpc performNavigationAction:VLCMediaPlaybackNavigationActionRight];
                                break;
                            case VLCSiriRemoteTouchLocationUp:
                                [vpc performNavigationAction:VLCMediaPlaybackNavigationActionUp];
                                break;
                            case VLCSiriRemoteTouchLocationDown:
                                [vpc performNavigationAction:VLCMediaPlaybackNavigationActionDown];
                                break;
                            case VLCSiriRemoteTouchLocationUnknown:
                                break;
                        }
                    }
                    break;
                default:
                    break;
            }
            return;
        }
    }


    [self showPlaybackControlsIfNeededForUserInteraction];

    VLCTransportBarHint hint = self.transportBar.hint;
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            if ([[VLCPlaybackService sharedInstance] currentMediaIs360Video]) {
                _projectionLocation = [recognizer locationInView:self.view];
                break;
            }
        case UIGestureRecognizerStateChanged:
            if (![[VLCPlaybackService sharedInstance] currentMediaIs360Video]) {
                if (recognizer.isLongPress) {
                    if (!self.isSeekable && recognizer.touchLocation == VLCSiriRemoteTouchLocationRight) {
                        [self setScanState:VLCPlayerScanStateForward2];
                        return;
                    }
                } else {
                    if (self.canJump) {
                        switch (recognizer.touchLocation) {
                            case VLCSiriRemoteTouchLocationLeft:
                                hint = VLCTransportBarHintJumpBackward10;
                                break;
                            case VLCSiriRemoteTouchLocationRight:
                                hint = VLCTransportBarHintJumpForward10;
                                break;
                            default:
                                hint = VLCTransportBarHintNone;
                                break;
                        }
                    } else {
                        hint = VLCTransportBarHintNone;
                    }
                }
            }
            break;
        case UIGestureRecognizerStateEnded:
            if (![[VLCPlaybackService sharedInstance] currentMediaIs360Video]) {
                if (recognizer.isClick && !recognizer.isLongPress) {
                    [self handleSiriPressUpAtLocation:recognizer.touchLocation];
                }
                [self setScanState:VLCPlayerScanStateNone];
            }
            break;
        case UIGestureRecognizerStateCancelled:
            if (![[VLCPlaybackService sharedInstance] currentMediaIs360Video]) {
                hint = VLCTransportBarHintNone;
                [self setScanState:VLCPlayerScanStateNone];
            }
            break;
        default:
            break;
    }

    if (!self.transportBar.isScrubbing) {
        [self updateProjection:recognizer];
    }

    self.transportBar.hint = self.isSeekable ? hint : VLCPlayerScanStateNone;
}

- (void)handleSiriPressUpAtLocation:(VLCSiriRemoteTouchLocation)location
{
    BOOL canJump = [self canJump];
    switch (location) {
        case VLCSiriRemoteTouchLocationLeft:
            if (canJump && self.isSeekable) {
                [self jumpBackward:1];
            }
            break;
        case VLCSiriRemoteTouchLocationRight:
            if (canJump && self.isSeekable) {
                [self jumpForward:1];
            }
            break;
        default:
            [self selectButtonPressed];
            break;
    }
}

#pragma mark -
- (void)jumpForward:(NSInteger)multiplier
{
    if (!self.seekable) {
        APLog(@"Tried to seek while not media is not seekable.");
        return;
    }

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    NSInteger jumpInterval = [[NSUserDefaults standardUserDefaults] integerForKey:kVLCSettingPlaybackForwardSkipLength] * multiplier;

    if (vpc.isPlaying) {
        [self jumpInterval:jumpInterval];
    } else {
        [self scrubbingJumpInterval:jumpInterval];
    }
}
- (void)jumpBackward:(NSInteger)multiplier
{
    if (!self.seekable) {
        APLog(@"Tried to seek while not media is not seekable.");
        return;
    }

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    NSInteger jumpInterval = [[NSUserDefaults standardUserDefaults] integerForKey:kVLCSettingPlaybackBackwardSkipLength] * multiplier;

    if (vpc.isPlaying) {
        [self jumpInterval:-jumpInterval];
    } else {
        [self scrubbingJumpInterval:-jumpInterval];
    }
}

- (void)jumpInterval:(NSInteger)interval
{
    if (!self.seekable) {
        APLog(@"Tried to seek while not media is not seekable.");
        return;
    }

    NSInteger duration = [VLCPlaybackService sharedInstance].mediaDuration;
    if (duration == 0) {
        return;
    }

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];

    if (interval > 0) {
        [vpc jumpForward:(int)interval];
    } else {
        [vpc jumpBackward:(int)-interval];
    }
}

- (void)scrubbingJumpInterval:(NSInteger)interval
{
    if (!self.seekable) {
        APLog(@"Tried to seek while not media is not seekable.");
        return;
    }

    NSInteger duration = [VLCPlaybackService sharedInstance].mediaDuration;
    if (duration==0) {
        return;
    }
    CGFloat intervalFraction = ((CGFloat)interval)/((CGFloat)duration);
    VLCTransportBar *bar = self.transportBar;
    bar.scrubbing = YES;
    CGFloat currentFraction = bar.scrubbingFraction;
    currentFraction += intervalFraction;
    bar.scrubbingFraction = currentFraction;
    [self updateTimeLabelsForScrubbingFraction:currentFraction];
}

- (void)scanForwardNext
{
    if (!self.seekable) {
        APLog(@"Tried to seek while not media is not seekable.");
        return;
    }

    VLCPlayerScanState nextState = self.scanState;
    switch (self.scanState) {
        case VLCPlayerScanStateNone:
            nextState = VLCPlayerScanStateForward2;
            break;
        case VLCPlayerScanStateForward2:
            nextState = VLCPlayerScanStateForward4;
            break;
        case VLCPlayerScanStateForward4:
            return;
        default:
            return;
    }
    [self setScanState:nextState];
}

- (void)scanForwardPrevious
{
    if (!self.seekable) {
        APLog(@"Tried to seek while not media is not seekable.");
        return;
    }

    VLCPlayerScanState nextState = self.scanState;
    switch (self.scanState) {
        case VLCPlayerScanStateNone:
            return;
        case VLCPlayerScanStateForward2:
            nextState = VLCPlayerScanStateNone;
            break;
        case VLCPlayerScanStateForward4:
            nextState = VLCPlayerScanStateForward2;
            break;
        default:
            return;
    }
    [self setScanState:nextState];
}


- (void)setScanState:(VLCPlayerScanState)scanState
{
    if (_scanState == scanState) {
        return;
    }
    if (!self.seekable) {
        APLog(@"Tried to seek while not media is not seekable.");
        return;
    }

    if (_scanState == VLCPlayerScanStateNone) {
        self.scanSavedPlaybackRate = @([VLCPlaybackService sharedInstance].playbackRate);
    }
    _scanState = scanState;
    float rate = 1.0;
    VLCTransportBarHint hint = VLCTransportBarHintNone;
    switch (scanState) {
        case VLCPlayerScanStateForward2:
            rate = 2.0;
            hint = VLCTransportBarHintScanForward;
            break;
        case VLCPlayerScanStateForward4:
            rate = 4.0;
            hint = VLCTransportBarHintScanForward;
            break;

        case VLCPlayerScanStateNone:
        default:
            rate = self.scanSavedPlaybackRate.floatValue ?: 1.0;
            hint = VLCTransportBarHintNone;
            self.scanSavedPlaybackRate = nil;
            break;
    }

    [VLCPlaybackService sharedInstance].playbackRate = rate;
    [self.transportBar setHint:hint];
}

- (BOOL)isSeekable
{
    return [[VLCPlaybackService sharedInstance] isSeekable];
}

- (BOOL)canJump
{
    // to match the AVPlayerViewController behavior only allow jumping when playing.
    return [VLCPlaybackService sharedInstance].isPlaying;
}
- (BOOL)canScrub
{
    // to match the AVPlayerViewController behavior only allow scrubbing when paused.
    return ![VLCPlaybackService sharedInstance].isPlaying;
}

#pragma mark -

- (void)updateTimeLabelsForScrubbingFraction:(CGFloat)scrubbingFraction
{
    VLCTransportBar *bar = self.transportBar;
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    // MAX 1, _ is ugly hack to prevent --:-- instead of 00:00
    int scrubbingTimeInt = MAX(1,vpc.mediaDuration*scrubbingFraction);
    VLCTime *scrubbingTime = [VLCTime timeWithInt:scrubbingTimeInt];
    bar.markerTimeLabel.text = [scrubbingTime stringValue];
    VLCTime *remainingTime = [VLCTime timeWithInt:-(int)(vpc.mediaDuration-scrubbingTime.intValue)];
    bar.remainingTimeLabel.text = [remainingTime stringValue];
}

- (void)startScrubbing
{
    if (!self.seekable) {
        APLog(@"Tried to seek while not media is not seekable.");
        return;
    }

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    self.transportBar.scrubbing = YES;
    [self updateDimmingView];
    if (vpc.isPlaying) {
        [vpc playPause];
    }
}
- (void)stopScrubbing
{
    self.transportBar.scrubbing = NO;
    [self updateDimmingView];
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    [vpc playPause];
}

- (void)updateDimmingView
{
    BOOL shouldBeVisible = self.transportBar.scrubbing;
    BOOL isVisible = self.dimmingView.alpha == 1.0;
    if (shouldBeVisible != isVisible) {
        [UIView animateWithDuration:0.3 animations:^{
            self.dimmingView.alpha = shouldBeVisible ? 1.0 : 0.0;
        }];
    }
}

- (void)mediaPlayerBufferingChanged:(float)progress
                 forPlaybackService:(VLCPlaybackService *)playbackService
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.playbackUIShouldHide) {
            return;
        }
        if (progress < 1.0) {
            [self.coneLoadingView startAnimating];
        } else {
            [self.coneLoadingView stopAnimating];
        }
    });
}

- (void)disableIdleTimer {
    if (self.disabledIdleTimer) return;

    // we should not call disableIdleTimer multiple times and ensure
    // disable/enable calls are synced.
    VLCActivityManager *manager = [VLCActivityManager defaultManager];
    [manager disableIdleTimer];
    self.disabledIdleTimer = YES;
}

- (void)enableIdleTimer {
    if (!self.disabledIdleTimer) return;

    // we should not call activateidleTimer multiple times and ensure
    VLCActivityManager *manager = [VLCActivityManager defaultManager];
    [manager activateIdleTimer];
    self.disabledIdleTimer = NO;
}

- (void)updateThumbnailImageViewsWith:(UIImage *)artworkImage
{
    if (artworkImage == nil && !self.playbackUIShouldHide) {
        artworkImage = [UIImage imageNamed:@"about-app-icon"];
    }

    self.audioArtworkImageView.image = artworkImage;
    self.audioLargeBackgroundImageView.image = artworkImage;
}

#pragma mark - PlaybackControls

- (void)fireHidePlaybackControlsIfNotPlayingTimer:(NSTimer *)timer
{
    if (_controlsRowFocused) {
        return;
    }
    BOOL playing = [[VLCPlaybackService sharedInstance] isPlaying];
    if (playing) {
        [self animatePlaybackControlsToVisibility:NO];
    }
}
- (void)showPlaybackControlsIfNeededForUserInteraction
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMediaPlayerTitleDescription *title = [vpc currentTitleDescription];
    if (title != nil) {
        if (title.menu) {
            return;
        }
    }

    if (self.bottomOverlayView.alpha == 0.0) {
        [self animatePlaybackControlsToVisibility:YES];

        // We need an additional update here because in some cases (e.g. when the playback was
        // paused or started buffering), the transport bar is only updated when it is visible
        // and if the playback is interrupted, no updates of the transport bar are triggered.
        [self updateTransportBarPosition];
    }
    [self hidePlaybackControlsIfNeededAfterDelay];
}
- (void)hidePlaybackControlsIfNeededAfterDelay
{
    self.hidePlaybackControlsViewAfterDelayTimer = [NSTimer scheduledTimerWithTimeInterval:.75
                                                                                     target:self
                                                                                   selector:@selector(fireHidePlaybackControlsIfNotPlayingTimer:)
                                                                                   userInfo:nil repeats:NO];
}


- (void)animatePlaybackControlsToVisibility:(BOOL)visible
{
    NSTimeInterval duration = visible ? 0.3 : 1.0;

    CGFloat alpha = visible ? 1.0 : 0.0;
    [UIView animateWithDuration:duration
                     animations:^{
        self.bottomOverlayView.alpha = alpha;
        _scrimView.alpha = alpha;
    }];
}

#pragma mark - controls row

- (void)setupScrimGradient
{
    _scrimView = [[VLCGradientScrimView alloc] initWithFrame:CGRectZero];
    _scrimView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrimView.alpha = 0.0;
    [self.view insertSubview:_scrimView belowSubview:self.bottomOverlayView];

    [NSLayoutConstraint activateConstraints:@[
        [_scrimView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_scrimView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_scrimView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_scrimView.heightAnchor constraintEqualToConstant:300.0],
    ]];
}

- (void)setupControlButtonsRow
{
    _controlsBar = [[VLCPlayerControlsBar alloc] init];
    _controlsBar.translatesAutoresizingMaskIntoConstraints = NO;
    _controlsBar.presenter = self;
    [self.bottomOverlayView addSubview:_controlsBar];

    [NSLayoutConstraint activateConstraints:@[
        [_controlsBar.trailingAnchor constraintEqualToAnchor:self.transportBar.trailingAnchor],
        [_controlsBar.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor],
        [_controlsBar.heightAnchor constraintEqualToConstant:60.0],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_controlsBar.leadingAnchor constant:-20.0],
    ]];
}

- (void)focusControlsRow
{
    if (_controlsRowFocused || self.transportBar.scrubbing) {
        return;
    }
    VLCMediaPlayerTitleDescription *title = [[VLCPlaybackService sharedInstance] currentTitleDescription];
    if (title.menu) {
        return;
    }

    [self showPlaybackControlsIfNeededForUserInteraction];
    [_controlsBar updateContentVisibility];

    _controlsRowFocused = YES;
    ((VLCPlaybackControlsFocusView *)self.view).preventsFocus = YES;
    for (UIGestureRecognizer *recognizer in _transportGestureRecognizers) {
        recognizer.enabled = NO;
    }

    [self setNeedsFocusUpdate];
    [self updateFocusIfNeeded];
}

- (void)unfocusControlsRow
{
    if (!_controlsRowFocused) {
        return;
    }
    _controlsRowFocused = NO;
    ((VLCPlaybackControlsFocusView *)self.view).preventsFocus = NO;
    for (UIGestureRecognizer *recognizer in _transportGestureRecognizers) {
        recognizer.enabled = YES;
    }

    [self setNeedsFocusUpdate];
    [self updateFocusIfNeeded];
    [self hidePlaybackControlsIfNeededAfterDelay];
}

- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    if (_controlsRowFocused) {
        return @[_controlsBar];
    }
    return @[self.view];
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    if (_controlsRowFocused && ((UIPress *)[presses anyObject]).type == UIPressTypeMenu) {
        [self unfocusControlsRow];
        return;
    }
    [super pressesBegan:presses withEvent:event];
}


#pragma mark - Properties
- (void)setHidePlaybackControlsViewAfterDelayTimer:(NSTimer *)hidePlaybackControlsViewAfterDelayTimer {
    [_hidePlaybackControlsViewAfterDelayTimer invalidate];
    _hidePlaybackControlsViewAfterDelayTimer = hidePlaybackControlsViewAfterDelayTimer;
}

#pragma mark - playback controller delegation

- (void)prepareForMediaPlayback:(VLCPlaybackService *)controller
{
    self.audioView.hidden = YES;
}

- (void)playbackDidStop
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
currentMediaHasTrackToChooseFrom:(BOOL)currentMediaHasTrackToChooseFrom
        currentMediaHasChapters:(BOOL)currentMediaHasChapters
             forPlaybackService:(VLCPlaybackService *)playbackService
{
    if (currentState == VLCMediaPlayerStateError || currentState == VLCMediaPlayerStateStopped) {
        [self.coneLoadingView stopAnimating];
    }

    if (playbackService.isPlaying) {
        // we sometimes don't set the vout correctly if playback stops and restarts without dismising and redisplaying the VC
        // hence, manually reset the vout container here if it doesn't have sufficient children
        if (self.movieView.subviews.count < 2) {
            playbackService.videoOutputView = self.movieView;
        }

        if (!self.bufferingLabel.hidden) {
            [UIView animateWithDuration:.3 animations:^{
                self.bufferingLabel.hidden = YES;
            }];
        }

        [self disableIdleTimer];
    } else {
        [self enableIdleTimer];
    }
}

- (void)displayMetadataForPlaybackService:(VLCPlaybackService *)playbackService
                                 metadata:(VLCMetaData *)metadata
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title = metadata.title;
        NSString *artist = metadata.artist;
        NSString *albumName = metadata.albumName;
        self.titleLabel.text = title;
        if (metadata.isAudioOnly) {
            self.audioDescriptionTextView.hidden = YES;
            [self stopAudioDescriptionAnimation];

            if (artist != nil && albumName != nil) {
                [UIView animateWithDuration:.3 animations:^{
                    self.audioArtistLabel.text = artist;
                    self.audioArtistLabel.hidden = NO;
                    self.audioAlbumNameLabel.text = albumName;
                    self.audioAlbumNameLabel.hidden = NO;
                }];
            } else if (artist != nil) {
                [UIView animateWithDuration:.3 animations:^{
                    self.audioArtistLabel.text = artist;
                    self.audioArtistLabel.hidden = NO;
                    self.audioAlbumNameLabel.hidden = YES;
                }];
            } else if (title != nil) {
                NSRange deviderRange = [title rangeOfString:@" - "];
                if (deviderRange.length != 0) { // for radio stations, all we have is "ARTIST - TITLE"
                    artist = [title substringToIndex:deviderRange.location];
                    title = [title substringFromIndex:deviderRange.location + deviderRange.length];
                }
                [UIView animateWithDuration:.3 animations:^{
                    self.audioArtistLabel.text = artist;
                    self.audioArtistLabel.hidden = NO;
                    self.audioAlbumNameLabel.hidden = YES;
                }];
            }

            UIImage *artworkImage = metadata.artworkImage;

            if ((![self.lastArtist isEqualToString:artist]) ||
                (artworkImage != nil && self.audioArtworkImageView.image != artworkImage)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateThumbnailImageViewsWith:artworkImage];
                });
            }

            self.lastArtist = artist;
            self.audioTitleLabel.text = title;
            self.audioTitleLabel.hidden = NO;

            [UIView animateWithDuration:0.3 animations:^{
                self.audioView.hidden = NO;
            }];
        } else if (!self.audioView.hidden) {
            self.audioView.hidden = YES;
            self.audioArtworkImageView.image = nil;
            [self.audioLargeBackgroundImageView stopAnimating];
        }
    });
}

- (void)showStatusMessage:(NSString *)statusMessage
{
    CGRect frame = _statusLabel.frame;
    frame.origin.y = CGRectGetMidY(self.view.bounds) - frame.size.height / 2.;
    _statusLabel.frame = frame;
    [_statusLabel showStatusMessage:statusMessage];
}

#pragma mark -

- (void)updateTransportBarPosition
{
    VLCPlaybackService *controller = [VLCPlaybackService sharedInstance];
    VLCTransportBar *transportBar = self.transportBar;
    transportBar.remainingTimeLabel.text = [[controller remainingTime] stringValue];
    transportBar.markerTimeLabel.text = [[controller playedTime] stringValue];
    transportBar.playbackFraction = controller.playbackPosition;
}

- (void)playbackPositionUpdated:(VLCPlaybackService *)controller
{
    if (self.bottomOverlayView.alpha != 0.0) {
        [self updateTransportBarPosition];
    }
}

#pragma mark - gesture recognizer delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer.allowedPressTypes containsObject:@(UIPressTypeMenu)]) {
        return self.transportBar.scrubbing;
    }
    return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [self.simultaneousGestureRecognizers containsObject:gestureRecognizer];
}

- (void)scrollAudioDescriptionAnimationToTop
{
    [self stopAudioDescriptionAnimation];
    [self.audioDescriptionTextView setContentOffset:CGPointZero animated:YES];
    [self startAudioDescriptionAnimation];
}

- (void)startAudioDescriptionAnimation
{
    [self.audioDescriptionScrollTimer invalidate];
    self.audioDescriptionScrollTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                                        target:self
                                                                      selector:@selector(animateAudioDescription)
                                                                      userInfo:nil repeats:NO];
}

- (void)stopAudioDescriptionAnimation
{
    [self.audioDescriptionScrollTimer invalidate];
    self.audioDescriptionScrollTimer = nil;
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)animateAudioDescription
{
    [self.displayLink invalidate];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTriggered:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)displayLinkTriggered:(CADisplayLink*)link
{
    UIScrollView *scrollView = self.audioDescriptionTextView;
    CGFloat viewHeight = CGRectGetHeight(scrollView.frame);
    CGFloat maxOffsetY = scrollView.contentSize.height - viewHeight;

    CFTimeInterval secondsPerPage = 8.0;
    CGFloat offset = link.duration/secondsPerPage * viewHeight;

    CGFloat newYOffset = scrollView.contentOffset.y + offset;

    if (newYOffset > maxOffsetY+viewHeight) {
        scrollView.contentOffset = CGPointMake(0, -viewHeight);
    } else {
        scrollView.contentOffset = CGPointMake(0, newYOffset);
    }
}

@end


// Game controllers already have some default behavior built in to tvOS, don't override those controls
@implementation VLCFullscreenMovieTVViewController (VLCGameControllerManagerDelegate)

- (void)gameControllerManagerDelegateDidScrubBackward:(GameControllerManager * _Nonnull)gameControllerManager {
}

- (void)gameControllerManagerDelegateDidScrubForward:(GameControllerManager * _Nonnull)gameControllerManager {
}

- (void)gameControllerManagerDelegateDidTapBackward:(GameControllerManager * _Nonnull)gameControllerManager {
}

- (void)gameControllerManagerDelegateDidTapBackwardLong:(GameControllerManager * _Nonnull)gameControllerManager {
    if (self.canJump && self.isSeekable) {
        [self jumpBackward:3];
    }
}

- (void)gameControllerManagerDelegateDidTapClosePlayer:(GameControllerManager * _Nonnull)gameControllerManager {
}

- (void)gameControllerManagerDelegateDidTapForward:(GameControllerManager * _Nonnull)gameControllerManager {

}

- (void)gameControllerManagerDelegateDidTapForwardLong:(GameControllerManager * _Nonnull)gameControllerManager {
    if (self.canJump && self.isSeekable) {
        [self jumpForward:3];
    }
}

- (void)gameControllerManagerDelegateDidTapNextMedia:(GameControllerManager * _Nonnull)gameControllerManager {
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    [vpc next];
}

- (void)gameControllerManagerDelegateDidTapPlayPause:(GameControllerManager * _Nonnull)gameControllerManager {
}

- (void)gameControllerManagerDelegateDidTapPreviousMedia:(GameControllerManager * _Nonnull)gameControllerManager {
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    [vpc previous];
}

- (void)gameControllerManagerDelegateDidTapVolume:(GameControllerManager * _Nonnull)gameControllerManager :(float)value {
}

- (void)gameControllerManagerDelegateDidTogglePlayerQueue:(GameControllerManager * _Nonnull)gameControllerManager {

}

- (void)gameControllerManagerDelegateDidTogglePlayerOptions:(GameControllerManager * _Nonnull)gameControllerManager {

}
@end
