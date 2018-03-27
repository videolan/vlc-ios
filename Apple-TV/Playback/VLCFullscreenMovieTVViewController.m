/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFullscreenMovieTVViewController.h"
#import "VLCPlaybackInfoTVViewController.h"
#import "VLCPlaybackInfoTVAnimators.h"
#import "VLCIRTVTapGestureRecognizer.h"
#import "VLCHTTPUploaderController.h"
#import "VLCSiriRemoteGestureRecognizer.h"
#import "VLCNetworkImageView.h"

typedef NS_ENUM(NSInteger, VLCPlayerScanState)
{
    VLCPlayerScanStateNone,
    VLCPlayerScanStateForward2,
    VLCPlayerScanStateForward4,
};

@interface VLCFullscreenMovieTVViewController (UIViewControllerTransitioningDelegate) <UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate>
@end

@interface VLCFullscreenMovieTVViewController ()

@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) NSTimer *audioDescriptionScrollTimer;
@property (nonatomic) NSTimer *hidePlaybackControlsViewAfterDeleayTimer;
@property (nonatomic) VLCPlaybackInfoTVViewController *infoViewController;
@property (nonatomic) NSNumber *scanSavedPlaybackRate;
@property (nonatomic) VLCPlayerScanState scanState;
@property (nonatomic) NSString *lastArtist;

@property (nonatomic, readonly, getter=isSeekable) BOOL seekable;

@property (nonatomic) NSSet<UIGestureRecognizer *> *simultaneousGestureRecognizers;

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
                   name:VLCPlaybackControllerPlaybackDidStop
                 object:nil];
    [center addObserver:self
               selector:@selector(playbackDidStop)
                   name:VLCPlaybackControllerPlaybackDidFail
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

    // IR only recognizer
    UITapGestureRecognizer *upArrowRecognizer = [[VLCIRTVTapGestureRecognizer alloc] initWithTarget:self action:@selector(handleIRPressUp)];
    upArrowRecognizer.allowedPressTypes = @[@(UIPressTypeUpArrow)];
    [self.view addGestureRecognizer:upArrowRecognizer];

    UITapGestureRecognizer *downArrowRecognizer = [[VLCIRTVTapGestureRecognizer alloc] initWithTarget:self action:@selector(showInfoVCIfNotScrubbing)];
    downArrowRecognizer.allowedPressTypes = @[@(UIPressTypeDownArrow)];
    [self.view addGestureRecognizer:downArrowRecognizer];

    UITapGestureRecognizer *leftArrowRecognizer = [[VLCIRTVTapGestureRecognizer alloc] initWithTarget:self action:@selector(handleIRPressLeft)];
    leftArrowRecognizer.allowedPressTypes = @[@(UIPressTypeLeftArrow)];
    [self.view addGestureRecognizer:leftArrowRecognizer];

    UITapGestureRecognizer *rightArrowRecognizer = [[VLCIRTVTapGestureRecognizer alloc] initWithTarget:self action:@selector(handleIRPressRight)];
    rightArrowRecognizer.allowedPressTypes = @[@(UIPressTypeRightArrow)];
    [self.view addGestureRecognizer:rightArrowRecognizer];

    // Siri remote arrow presses
    VLCSiriRemoteGestureRecognizer *siriArrowRecognizer = [[VLCSiriRemoteGestureRecognizer alloc] initWithTarget:self action:@selector(handleSiriRemote:)];
    siriArrowRecognizer.delegate = self;
    [self.view addGestureRecognizer:siriArrowRecognizer];
    [simultaneousGestureRecognizers addObject:siriArrowRecognizer];

    self.simultaneousGestureRecognizers = simultaneousGestureRecognizers;

    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.infoViewController = nil;
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
    self.audioArtworkImageView.image = [UIImage imageNamed:@"about-app-icon"];
    self.audioLargeBackgroundImageView.image = [UIImage imageNamed:@"about-app-icon"];
    self.audioArtworkImageView.animateImageSetting = YES;
    self.audioLargeBackgroundImageView.animateImageSetting = YES;

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    vpc.delegate = self;
    [vpc recoverPlaybackState];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    [vpc recoverDisplayedMetadata];
    vpc.videoOutputView = nil;
    vpc.videoOutputView = self.movieView;
}

- (void)viewWillDisappear:(BOOL)animated
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
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

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    if (self.transportBar.scrubbing) {
        [self selectButtonPressed];
    } else {
        [vpc playPause];
    }
}

- (void)panGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSInteger currentTitle = [vpc indexOfCurrentTitle];
    if (currentTitle < [vpc numberOfTitles]) {
        NSDictionary *title = [vpc titleDescriptionsDictAtIndex:currentTitle];
        if ([[title objectForKey:VLCTitleDescriptionIsMenu] boolValue]) {
            return;
        }
    }

    if (!self.canScrub) {
        return;
    }

    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            return;
        default:
            break;
    }

    VLCTransportBar *bar = self.transportBar;

    UIView *view = self.view;
    CGPoint translation = [panGestureRecognizer translationInView:view];

    if (!bar.scrubbing) {
        if (ABS(translation.x) > 150.0) {
            if (self.isSeekable) {
                [self startScrubbing];
            } else {
                return;
            }
        } else if (translation.y > 200.0) {
            panGestureRecognizer.enabled = NO;
            panGestureRecognizer.enabled = YES;
            [self showInfoVCIfNotScrubbing];
            return;
        } else {
            return;
        }
    }

    [self showPlaybackControlsIfNeededForUserInteraction];
    [self setScanState:VLCPlayerScanStateNone];


    const CGFloat scaleFactor = 8.0;
    CGFloat fractionInView = translation.x/CGRectGetWidth(view.bounds)/scaleFactor;

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
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSInteger currentTitle = [vpc indexOfCurrentTitle];
    if (currentTitle < [vpc numberOfTitles]) {
        NSDictionary *title = [vpc titleDescriptionsDictAtIndex:currentTitle];
        if ([[title objectForKey:VLCTitleDescriptionIsMenu] boolValue]) {
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

- (void)showInfoVCIfNotScrubbing
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSInteger currentTitle = [vpc indexOfCurrentTitle];
    if (currentTitle < [vpc numberOfTitles]) {
        NSDictionary *title = [vpc titleDescriptionsDictAtIndex:currentTitle];
        if ([[title objectForKey:VLCTitleDescriptionIsMenu] boolValue]) {
            [vpc performNavigationAction:VLCMediaPlaybackNavigationActionDown];
            return;
        }
    }

    if (self.transportBar.scrubbing) {
        return;
    }
    // TODO: configure with player info
    VLCPlaybackInfoTVViewController *infoViewController = self.infoViewController;

    // prevent repeated presentation when users repeatedly and quickly press the arrow button
    if (infoViewController.isBeingPresented) {
        return;
    }
    infoViewController.transitioningDelegate = self;
    [self presentViewController:infoViewController animated:YES completion:nil];
    [self animatePlaybackControlsToVisibility:NO];
}

- (void)handleIRPressUp
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSInteger currentTitle = [vpc indexOfCurrentTitle];
    if (currentTitle < [vpc numberOfTitles]) {
        NSDictionary *title = [vpc titleDescriptionsDictAtIndex:currentTitle];
        if ([[title objectForKey:VLCTitleDescriptionIsMenu] boolValue]) {
            [vpc performNavigationAction:VLCMediaPlaybackNavigationActionUp];
        }
    }
}

- (void)handleIRPressLeft
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSInteger currentTitle = [vpc indexOfCurrentTitle];
    if (currentTitle < [vpc numberOfTitles]) {
        NSDictionary *title = [vpc titleDescriptionsDictAtIndex:currentTitle];
        if ([[title objectForKey:VLCTitleDescriptionIsMenu] boolValue]) {
            [vpc performNavigationAction:VLCMediaPlaybackNavigationActionLeft];
            return;
        }
    }

    [self showPlaybackControlsIfNeededForUserInteraction];

    if (!self.isSeekable) {
        return;
    }

    BOOL paused = ![VLCPlaybackController sharedInstance].isPlaying;
    if (paused) {
        [self jumpBackward];
    } else
    {
        [self scanForwardPrevious];
    }
}

- (void)handleIRPressRight
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSInteger currentTitle = [vpc indexOfCurrentTitle];
    if (currentTitle < [vpc numberOfTitles]) {
        NSDictionary *title = [vpc titleDescriptionsDictAtIndex:currentTitle];
        if ([[title objectForKey:VLCTitleDescriptionIsMenu] boolValue]) {
            [vpc performNavigationAction:VLCMediaPlaybackNavigationActionRight];
            return;
        }
    }

    [self showPlaybackControlsIfNeededForUserInteraction];

    if (!self.isSeekable) {
        return;
    }

    BOOL paused = ![VLCPlaybackController sharedInstance].isPlaying;
    if (paused) {
        [self jumpForward];
    } else {
        [self scanForwardNext];
    }
}

- (void)handleSiriRemote:(VLCSiriRemoteGestureRecognizer *)recognizer
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSInteger currentTitle = [vpc indexOfCurrentTitle];
    if (currentTitle < [vpc numberOfTitles]) {
        NSDictionary *title = [vpc titleDescriptionsDictAtIndex:currentTitle];
        if ([[title objectForKey:VLCTitleDescriptionIsMenu] boolValue]) {
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
        case UIGestureRecognizerStateChanged:
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
            break;
        case UIGestureRecognizerStateEnded:
            if (recognizer.isClick && !recognizer.isLongPress) {
                [self handleSiriPressUpAtLocation:recognizer.touchLocation];
            }
            [self setScanState:VLCPlayerScanStateNone];
            break;
        case UIGestureRecognizerStateCancelled:
            hint = VLCTransportBarHintNone;
            [self setScanState:VLCPlayerScanStateNone];
            break;
        default:
            break;
    }
    self.transportBar.hint = self.isSeekable ? hint : VLCPlayerScanStateNone;
}

- (void)handleSiriPressUpAtLocation:(VLCSiriRemoteTouchLocation)location
{
    BOOL canJump = [self canJump];
    switch (location) {
        case VLCSiriRemoteTouchLocationLeft:
            if (canJump && self.isSeekable) {
                [self jumpBackward];
            }
            break;
        case VLCSiriRemoteTouchLocationRight:
            if (canJump && self.isSeekable) {
                [self jumpForward];
            }
            break;
        default:
            [self selectButtonPressed];
            break;
    }
}

#pragma mark -
static const NSInteger VLCJumpInterval = 10000; // 10 seconds
- (void)jumpForward
{
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];

    if (vpc.isPlaying) {
        [self jumpInterval:VLCJumpInterval];
    } else {
        [self scrubbingJumpInterval:VLCJumpInterval];
    }
}
- (void)jumpBackward
{
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];

    if (vpc.isPlaying) {
        [self jumpInterval:-VLCJumpInterval];
    } else {
        [self scrubbingJumpInterval:-VLCJumpInterval];
    }
}

- (void)jumpInterval:(NSInteger)interval
{
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");

    NSInteger duration = [VLCPlaybackController sharedInstance].mediaDuration;
    if (duration==0) {
        return;
    }
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];

    CGFloat intervalFraction = ((CGFloat)interval)/((CGFloat)duration);
    CGFloat currentFraction = vpc.playbackPosition;
    currentFraction += intervalFraction;
    vpc.playbackPosition = currentFraction;
}

- (void)scrubbingJumpInterval:(NSInteger)interval
{
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");

    NSInteger duration = [VLCPlaybackController sharedInstance].mediaDuration;
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
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");

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
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");

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

    NSAssert(self.isSeekable || scanState == VLCPlayerScanStateNone, @"Tried to seek while media not seekable.");

    if (_scanState == VLCPlayerScanStateNone) {
        self.scanSavedPlaybackRate = @([VLCPlaybackController sharedInstance].playbackRate);
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

    [VLCPlaybackController sharedInstance].playbackRate = rate;
    [self.transportBar setHint:hint];
}

- (BOOL)isSeekable
{
    return [[VLCPlaybackController sharedInstance] isSeekable];
}

- (BOOL)canJump
{
    // to match the AVPlayerViewController behavior only allow jumping when playing.
    return [VLCPlaybackController sharedInstance].isPlaying;
}
- (BOOL)canScrub
{
    // to match the AVPlayerViewController behavior only allow scrubbing when paused.
    return ![VLCPlaybackController sharedInstance].isPlaying;
}

#pragma mark -

- (void)updateTimeLabelsForScrubbingFraction:(CGFloat)scrubbingFraction
{
    VLCTransportBar *bar = self.transportBar;
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    // MAX 1, _ is ugly hack to prevent --:-- instead of 00:00
    int scrubbingTimeInt = MAX(1,vpc.mediaDuration*scrubbingFraction);
    VLCTime *scrubbingTime = [VLCTime timeWithInt:scrubbingTimeInt];
    bar.markerTimeLabel.text = [scrubbingTime stringValue];
    VLCTime *remainingTime = [VLCTime timeWithInt:-(int)(vpc.mediaDuration-scrubbingTime.intValue)];
    bar.remainingTimeLabel.text = [remainingTime stringValue];
}

- (void)startScrubbing
{
    NSAssert(self.isSeekable, @"Tried to seek while not media is not seekable.");

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
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
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
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

- (void)updateActivityIndicatorForState:(VLCMediaPlayerState)state {
    UIActivityIndicatorView *indicator = self.activityIndicator;
    switch (state) {
        case VLCMediaPlayerStateBuffering:
            if (!indicator.isAnimating) {
                self.activityIndicator.alpha = 1.0;
                [self.activityIndicator startAnimating];
            }
            break;
        default:
            if (indicator.isAnimating) {
                [self.activityIndicator stopAnimating];
                self.activityIndicator.alpha = 0.0;
            }
            break;
    }
}

#pragma mark - PlaybackControls

- (void)fireHidePlaybackControlsIfNotPlayingTimer:(NSTimer *)timer
{
    BOOL playing = [[VLCPlaybackController sharedInstance] isPlaying];
    if (playing) {
        [self animatePlaybackControlsToVisibility:NO];
    }
}
- (void)showPlaybackControlsIfNeededForUserInteraction
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSInteger currentTitle = [vpc indexOfCurrentTitle];
    if (currentTitle < [vpc numberOfTitles]) {
        NSDictionary *title = [vpc titleDescriptionsDictAtIndex:currentTitle];
        if ([[title objectForKey:VLCTitleDescriptionIsMenu] boolValue]) {
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
    self.hidePlaybackControlsViewAfterDeleayTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
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
                     }];
}


#pragma mark - Properties
- (void)setHidePlaybackControlsViewAfterDeleayTimer:(NSTimer *)hidePlaybackControlsViewAfterDeleayTimer {
    [_hidePlaybackControlsViewAfterDeleayTimer invalidate];
    _hidePlaybackControlsViewAfterDeleayTimer = hidePlaybackControlsViewAfterDeleayTimer;
}

- (VLCPlaybackInfoTVViewController *)infoViewController
{
    if (!_infoViewController) {
        _infoViewController = [[VLCPlaybackInfoTVViewController alloc] initWithNibName:nil bundle:nil];
    }
    return _infoViewController;
}



#pragma mark - playback controller delegation

- (void)prepareForMediaPlayback:(VLCPlaybackController *)controller
{
    self.audioView.hidden = YES;
}

- (void)playbackDidStop
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
currentMediaHasTrackToChooseFrom:(BOOL)currentMediaHasTrackToChooseFrom
        currentMediaHasChapters:(BOOL)currentMediaHasChapters
          forPlaybackController:(VLCPlaybackController *)controller
{

    [self updateActivityIndicatorForState:currentState];

    if (controller.isPlaying) {
        // we sometimes don't set the vout correctly if playback stops and restarts without dismising and redisplaying the VC
        // hence, manually reset the vout container here if it doesn't have sufficient children
        if (self.movieView.subviews.count < 2) {
            controller.videoOutputView = self.movieView;
        }

        if (!self.bufferingLabel.hidden) {
            [UIView animateWithDuration:.3 animations:^{
                self.bufferingLabel.hidden = YES;
            }];
        }
    }
}

- (void)displayMetadataForPlaybackController:(VLCPlaybackController *)controller
                                       title:(NSString *)title
                                     artwork:(UIImage *)artwork
                                      artist:(NSString *)artist
                                       album:(NSString *)album
                                   audioOnly:(BOOL)audioOnly
{
    self.titleLabel.text = title;

    if (audioOnly) {
        self.audioArtworkImageView.image = nil;
        self.audioDescriptionTextView.hidden = YES;
        [self stopAudioDescriptionAnimation];

        if (artist != nil && album != nil) {
            [UIView animateWithDuration:.3 animations:^{
                self.audioArtistLabel.text = artist;
                self.audioArtistLabel.hidden = NO;
                self.audioAlbumNameLabel.text = album;
                self.audioAlbumNameLabel.hidden = NO;
            }];
            APLog(@"Audio-only track meta changed, tracing artist '%@' and album '%@'", artist, album);
        } else if (artist != nil) {
            [UIView animateWithDuration:.3 animations:^{
                self.audioArtistLabel.text = artist;
                self.audioArtistLabel.hidden = NO;
                self.audioAlbumNameLabel.hidden = YES;
            }];
            APLog(@"Audio-only track meta changed, tracing artist '%@'", artist);
        } else if (title != nil) {
            NSRange deviderRange = [title rangeOfString:@" - "];
            if (deviderRange.length != 0) { // for radio stations, all we have is "ARTIST - TITLE"
                artist = [title substringToIndex:deviderRange.location];
                title = [title substringFromIndex:deviderRange.location + deviderRange.length];
            }
            APLog(@"Audio-only track meta changed, tracing artist '%@'", artist);
            [UIView animateWithDuration:.3 animations:^{
                self.audioArtistLabel.text = artist;
                self.audioArtistLabel.hidden = NO;
                self.audioAlbumNameLabel.hidden = YES;
            }];
        }
        if (![self.lastArtist isEqualToString:artist]) {
            UIImage *dummyImage = [UIImage imageNamed:@"about-app-icon"];
            [UIView animateWithDuration:.3 animations:^{
                self.audioArtworkImageView.image = dummyImage;
                self.audioLargeBackgroundImageView.image = dummyImage;
            }];
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
}

#pragma mark -

- (void)updateTransportBarPosition
{
    VLCPlaybackController *controller = [VLCPlaybackController sharedInstance];
    VLCTransportBar *transportBar = self.transportBar;
    transportBar.remainingTimeLabel.text = [[controller remainingTime] stringValue];
    transportBar.markerTimeLabel.text = [[controller playedTime] stringValue];
    transportBar.playbackFraction = controller.playbackPosition;
}

- (void)playbackPositionUpdated:(VLCPlaybackController *)controller
{
    // FIXME: hard coded state since the state in mediaPlayer is incorrectly still buffering
    [self updateActivityIndicatorForState:VLCMediaPlayerStatePlaying];

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


@implementation VLCFullscreenMovieTVViewController (UIViewControllerTransitioningDelegate)

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [[VLCPlaybackInfoTVTransitioningAnimator alloc] init];
}
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[VLCPlaybackInfoTVTransitioningAnimator alloc] init];
}
@end
