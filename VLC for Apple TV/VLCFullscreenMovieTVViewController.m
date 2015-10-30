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


@interface VLCFullscreenMovieTVViewController (UIViewControllerTransitioningDelegate) <UIViewControllerTransitioningDelegate>
@end

@interface VLCFullscreenMovieTVViewController ()
{
    BOOL _playerIsSetup;
    BOOL _viewAppeared;
}
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
    _playerIsSetup = NO;

    self.titleLabel.text = @"";

    self.transportBar.bufferStartFraction = 0.0;
    self.transportBar.bufferEndFraction = 1.0;
    self.transportBar.playbackFraction = 0.0;
    self.transportBar.scrubbingFraction = 0.0;

    self.dimmingView.alpha = 0.0;
    self.bottomOverlayView.hidden = YES;

    self.bufferingLabel.text = NSLocalizedString(@"PLEASE_WAIT", nil);


    // Panning and Swiping

    // does not work with pan gesture
//    UISwipeGestureRecognizer *swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDownRecognized:)];
//    swipeDownRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
//    [self.view addGestureRecognizer:swipeDownRecognizer];

    UITapGestureRecognizer *swipeDownRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDownRecognized:)];
    swipeDownRecognizer.allowedPressTypes = @[@(UIPressTypeUpArrow)];
    [self.view addGestureRecognizer:swipeDownRecognizer];

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
    [self.view addGestureRecognizer:menuTapGestureRecognizer];
}

#pragma mark - view events

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:YES animated:animated];

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    vpc.delegate = self;
    [vpc recoverPlaybackState];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _viewAppeared = YES;

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

    _viewAppeared = NO;
    [self.navigationController setNavigationBarHidden:NO animated:YES];

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
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    [vpc playPause];
}

- (void)panGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
    VLCTransportBar *bar = self.transportBar;

    UIView *view = self.view;
    CGPoint translation = [panGestureRecognizer translationInView:view];

    if (!bar.scrubbing) {
        if (ABS(translation.x) > 100.0) {
            [self startScrubbing];
        } else {
            return;
        }
    }

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
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    VLCTransportBar *bar = self.transportBar;
    if (bar.scrubbing) {
        [vpc.mediaPlayer setPosition:bar.scrubbingFraction];
        [self stopScrubbing];
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
    }
}

- (void)swipeDownRecognized:(UITapGestureRecognizer *)recognizer
{
    if (self.transportBar.scrubbing) {
        return;
    }

    VLCPlaybackInfoTVViewController *infoController = [[VLCPlaybackInfoTVViewController alloc] initWithNibName:nil bundle:nil];
    infoController.transitioningDelegate = self;
    infoController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    // TODO: configure with player info
    [self presentViewController:infoController animated:YES completion:nil];
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
    if (controller.isPlaying && !self.bufferingLabel.hidden) {
        [UIView animateWithDuration:.3 animations:^{
            self.bufferingLabel.hidden = YES;
            self.bottomOverlayView.hidden = NO;
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
