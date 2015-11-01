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

@interface VLCFullscreenMovieTVViewController (UIViewControllerTransitioningDelegate) <UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate>
@end

@interface VLCFullscreenMovieTVViewController ()

@property (nonatomic) NSTimer *hidePlaybackControlsViewAfterDeleayTimer;
@property (nonatomic) VLCPlaybackInfoTVViewController *infoViewController;
@end

@implementation VLCFullscreenMovieTVViewController

+ (instancetype)fullscreenMovieTVViewController
{
    return [[self alloc] initWithNibName:nil bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(playbackDidStop:)
                   name:VLCPlaybackControllerPlaybackDidStop
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


    // Panning and Swiping

    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self.view addGestureRecognizer:panGestureRecognizer];

    // Button presses
    UITapGestureRecognizer *playpauseGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPausePressed)];
    playpauseGesture.allowedPressTypes = @[@(UIPressTypePlayPause)];
    [self.view addGestureRecognizer:playpauseGesture];

    UITapGestureRecognizer *selectTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectButtonPressed:)];
    selectTapGestureRecognizer.allowedPressTypes = @[@(UIPressTypeSelect)];
    [self.view addGestureRecognizer:selectTapGestureRecognizer];

    UITapGestureRecognizer *menuTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuButtonPressed:)];
    menuTapGestureRecognizer.allowedPressTypes = @[@(UIPressTypeMenu)];
    menuTapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:menuTapGestureRecognizer];

    UITapGestureRecognizer *upArrowRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showInfoVCIfNotScrubbing)];
    upArrowRecognizer.allowedPressTypes = @[@(UIPressTypeUpArrow)];
    [self.view addGestureRecognizer:upArrowRecognizer];

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

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    if (vpc.videoOutputView == self.movieView) {
        vpc.videoOutputView = nil;
    }

    [vpc stopPlayback];

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

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    if (self.transportBar.scrubbing) {
        [self selectButtonPressed:nil];
    } else {
        [vpc playPause];
    }
}

- (void)panGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
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
            [self startScrubbing];
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


    const CGFloat scaleFactor = 8.0;
    CGFloat fractionInView = translation.x/CGRectGetWidth(view.bounds)/scaleFactor;
    translation.x = 0.0;
    [panGestureRecognizer setTranslation:translation inView:view];

    CGFloat scrubbingFraction = MAX(0.0, MIN(bar.scrubbingFraction + fractionInView,1.0));
    bar.scrubbingFraction = scrubbingFraction;
    [self updateTimeLabelsForScrubbingFraction:scrubbingFraction];
}

- (void)selectButtonPressed:(UITapGestureRecognizer *)recognizer
{
    [self showPlaybackControlsIfNeededForUserInteraction];

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    VLCTransportBar *bar = self.transportBar;
    if (bar.scrubbing) {
        bar.playbackFraction = bar.scrubbingFraction;
        [vpc.mediaPlayer setPosition:bar.scrubbingFraction];
        [self stopScrubbing];
    } else if(vpc.mediaPlayer.playing) {
        [vpc.mediaPlayer pause];
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
    if (self.transportBar.scrubbing) {
        return;
    }
    // TODO: configure with player info
    VLCPlaybackInfoTVViewController *infoViewController = self.infoViewController;
    infoViewController.transitioningDelegate = self;
    [self presentViewController:infoViewController animated:YES completion:nil];
    [self animatePlaybackControlsToVisibility:NO];
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
    VLCTime *remainingTime = [VLCTime timeWithInt:(int)vpc.mediaDuration-scrubbingTime.intValue];
    bar.remainingTimeLabel.text = [remainingTime stringValue];
}

- (void)startScrubbing
{
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
    [vpc.mediaPlayer play];
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
    if (self.bottomOverlayView.alpha == 0.0) {
        [self animatePlaybackControlsToVisibility:YES];
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
    APLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)playbackDidStop:(NSNotification *)aNotification
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
        [self hidePlaybackControlsIfNeededAfterDelay];
    } else {
        [self showPlaybackControlsIfNeededForUserInteraction];
    }

    if (controller.isPlaying && !self.bufferingLabel.hidden) {
        [UIView animateWithDuration:.3 animations:^{
            self.bufferingLabel.hidden = YES;
        }];
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
}

#pragma mark -

- (void)playbackPositionUpdated:(VLCPlaybackController *)controller
{
    VLCMediaPlayer *mediaPlayer = [VLCPlaybackController sharedInstance].mediaPlayer;
    // FIXME: hard coded state since the state in mediaPlayer is incorrectly still buffering
    [self updateActivityIndicatorForState:VLCMediaPlayerStatePlaying];

    VLCTransportBar *transportBar = self.transportBar;
    transportBar.remainingTimeLabel.text = [[mediaPlayer remainingTime] stringValue];
    transportBar.markerTimeLabel.text = [[mediaPlayer time] stringValue];
    transportBar.playbackFraction = mediaPlayer.position;
}

#pragma mark - gesture recognizer delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer.allowedPressTypes containsObject:@(UIPressTypeMenu)]) {
        return self.transportBar.scrubbing;
    }
    return YES;
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
