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

    self.bottomOverlayView.hidden = YES;

    UITapGestureRecognizer *playpauseGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPausePressed)];
    playpauseGesture.allowedPressTypes = @[@(UIPressTypePlayPause)];
    [self.view addGestureRecognizer:playpauseGesture];

    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self.view addGestureRecognizer:panGestureRecognizer];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectTap:)];
    tapGestureRecognizer.allowedPressTypes = @[@(UIPressTypeSelect)];
    [self.view addGestureRecognizer:tapGestureRecognizer];

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
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    VLCTransportBar *bar = self.transportBar;

    UIView *view = self.view;
    CGPoint translation = [panGestureRecognizer translationInView:view];

    if (!bar.scrubbing) {
        if (translation.x > 100.0) {
            bar.scrubbing = YES;
            if (vpc.isPlaying) {
                [vpc playPause];
            }
        } else {
            return;
        }
    }

    const CGFloat scaleFactor = 8.0;
    CGFloat fractionInView = translation.x/CGRectGetWidth(view.bounds)/scaleFactor;
    translation.x = 0.0;
    [panGestureRecognizer setTranslation:translation inView:view];

    CGFloat scrubbinFraction = MAX(0.0, MIN(bar.scrubbingFraction + fractionInView,1.0));
    bar.scrubbingFraction = scrubbinFraction;
    // MAX 1, _ is ugly hack to prevent --:-- instead of 00:00
    int scrubbingTimeInt = MAX(1,vpc.mediaDuration*scrubbinFraction);
    VLCTime *scrubbingTime = [VLCTime timeWithInt:scrubbingTimeInt];
    bar.markerTimeLabel.text = [scrubbingTime stringValue];
    VLCTime *remainingTime = [VLCTime timeWithInt:(int)vpc.mediaDuration-scrubbingTime.intValue];
    bar.remainingTimeLabel.text = [remainingTime stringValue];
}

- (void)selectTap:(UITapGestureRecognizer *)recognizer
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    VLCTransportBar *bar = self.transportBar;
    if (bar.scrubbing) {
        bar.scrubbing = NO;
        [vpc.mediaPlayer setPosition:bar.scrubbingFraction];
        [vpc.mediaPlayer play];
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

    switch (currentState) {
        case VLCMediaPlayerStateBuffering:
            [self.activityIndicator startAnimating];
            self.activityIndicator.alpha = 1.0;
            break;

        default:
            [self.activityIndicator stopAnimating];
            self.activityIndicator.alpha = 0.0;
            break;
    }

    if (controller.isPlaying && !self.bufferingLabel.hidden) {
        [self.activityIndicator stopAnimating];
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

    VLCTransportBar *transportBar = self.transportBar;
    transportBar.remainingTimeLabel.text = [[mediaPlayer remainingTime] stringValue];
    transportBar.markerTimeLabel.text = [[mediaPlayer time] stringValue];
    transportBar.playbackFraction = mediaPlayer.position;
}

@end
