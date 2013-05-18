//
//  VLCMovieViewController.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCMovieViewController.h"
#import "VLCExternalDisplayController.h"

#define INPUT_RATE_DEFAULT  1000.

@interface VLCMovieViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIPopoverController *masterPopoverController;
@property (nonatomic, strong) UIWindow *externalWindow;
@end

@implementation VLCMovieViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Managing the media item

- (void)setMediaItem:(id)newMediaItem
{
    if (_mediaItem != newMediaItem)
        _mediaItem = newMediaItem;

    if (self.masterPopoverController != nil)
        [self.masterPopoverController dismissPopoverAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.wantsFullScreenLayout = YES;

    _mediaPlayer = [[VLCMediaPlayer alloc] init];
    [_mediaPlayer setDelegate:self];
    [_mediaPlayer setDrawable:self.movieView];

    self.videoFilterView.hidden = YES;
    _videoFiltersHidden = YES;
    _hueLabel.text = NSLocalizedString(@"VFILTER_HUE", @"");
    _contrastLabel.text = NSLocalizedString(@"VFILTER_CONTRAST", @"");
    _brightnessLabel.text = NSLocalizedString(@"VFILTER_BRIGHTNESS", @"");
    _saturationLabel.text = NSLocalizedString(@"VFILTER_SATURATION", @"");
    _gammaLabel.text = NSLocalizedString(@"VFILTER_GAMMA", @"");

    self.playbackSpeedView.hidden = YES;
    _playbackSpeedViewHidden = YES;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(handleExternalScreenDidConnect:)
                   name:UIScreenDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(handleExternalScreenDidDisconnect:)
                   name:UIScreenDidDisconnectNotification object:nil];
    [center addObserver:self selector:@selector(appWillResign:) name:UIApplicationWillResignActiveNotification object:nil];

    _playingExternallyTitle.text = NSLocalizedString(@"PLAYING_EXTERNALLY_TITLE", @"");
    _playingExternallyDescription.text = NSLocalizedString(@"PLAYING_EXTERNALLY_DESC", @"");
    if ([self hasExternalDisplay])
        [self showOnExternalDisplay];

    _movieView.userInteractionEnabled = NO;
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControlsVisible)];
    recognizer.delegate = self;
    [self.view addGestureRecognizer:recognizer];

    _cropRatios = @[@"Default", @"16:10", @"16:9", @"2:39:1", @"5:3", @"4:3", @"5:4", @"1:1"];
    _aspectRatios = @[@"Default", @"1:1", @"4:3", @"16:9", @"16:10", @"2.21:1", @"2:35:1", @"2.39:1", @"5:4"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;

    if (!self.mediaItem && !self.url)
        return;

    if (self.mediaItem) {
        self.title = [self.mediaItem title];
        [_mediaPlayer setMedia:[VLCMedia mediaWithURL:[NSURL URLWithString:self.mediaItem.url]]];
    } else {
        [_mediaPlayer setMedia:[VLCMedia mediaWithURL:self.url]];
        self.title = @"Network Stream";
    }

    self.positionSlider.value = 0.;

    [_mediaPlayer play];

    if (self.mediaItem.lastPosition && [self.mediaItem.lastPosition floatValue] < 0.99)
        [_mediaPlayer setPosition:[self.mediaItem.lastPosition floatValue]];
    self.playbackSpeedSlider.value = [self _playbackSpeed];
    [self _updatePlaybackSpeedIndicator];

    _currentAspectRatioMask = _currentCropMask = 0;
    _mediaPlayer.videoAspectRatio = _mediaPlayer.videoCropGeometry = NULL;

    [super viewWillAppear:animated];

    [self resetIdleTimer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (_idleTimer)
        [_idleTimer invalidate];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [_mediaPlayer pause];
    [super viewWillDisappear:animated];
    self.mediaItem.lastPosition = @([_mediaPlayer position]);
    [_mediaPlayer stop];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
        self.title = @"Video Playback";
    return self;
}

#pragma mark - remote events

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
            [_mediaPlayer play];
            break;

        case UIEventSubtypeRemoteControlPause:
            [_mediaPlayer pause];
            break;

        case UIEventSubtypeRemoteControlTogglePlayPause:
            [self playPause];
            break;

        default:
            break;
    }
}

#pragma mark - controls visibility

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view != self.view)
        return NO;

    return YES;
}

- (void)toggleControlsVisible
{
    _controlsHidden = !_controlsHidden;
    CGFloat alpha = _controlsHidden? 0.0f: 1.0f;

    if (!_controlsHidden) {
        _controllerPanel.alpha = 0.0f;
        _controllerPanel.hidden = !_videoFiltersHidden;
        _toolbar.alpha = 0.0f;
        _toolbar.hidden = NO;
        _videoFilterView.alpha = 0.0f;
        _videoFilterView.hidden = _videoFiltersHidden;
        _playbackSpeedView.alpha = 0.0f;
        _playbackSpeedView.hidden = _playbackSpeedViewHidden;
        _playbackSpeedButton.alpha = 0.0f;
        _playbackSpeedButton.hidden = NO;
        _videoFilterButton.alpha = 0.0f;
        _videoFilterButton.hidden = NO;
        _cropButton.alpha = 0.0f;
        _cropButton.hidden = NO;
        _aspectRatioButton.alpha = 0.0f;
        _aspectRatioButton.hidden = NO;
    }

    void (^animationBlock)() = ^() {
        _controllerPanel.alpha = alpha;
        _toolbar.alpha = alpha;
        _videoFilterView.alpha = alpha;
        _videoFilterButton.alpha = alpha;
        _playbackSpeedView.alpha = alpha;
        _playbackSpeedButton.alpha = alpha;
        _videoFilterButton.alpha = alpha;
        _cropButton.alpha = alpha;
        _aspectRatioButton.alpha = alpha;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        if (_videoFiltersHidden) {
            _controllerPanel.hidden = _controlsHidden;
            _playbackSpeedButton.hidden = _controlsHidden;
            _videoFilterButton.hidden = _controlsHidden;
            _cropButton.hidden = _controlsHidden;
            _aspectRatioButton.hidden = _controlsHidden;
        } else {
            _controllerPanel.hidden = NO;
            _playbackSpeedButton.hidden = NO;
            _videoFilterButton.hidden = NO;
            _cropButton.hidden = NO;
            _aspectRatioButton.hidden = NO;
        }
        _toolbar.hidden = _controlsHidden;
        _videoFilterView.hidden = _videoFiltersHidden;
        if (_controlsHidden)
            _playbackSpeedView.hidden = YES;
        else
            _playbackSpeedView.hidden = _playbackSpeedViewHidden;
    };

    [UIView animateWithDuration:0.3f animations:animationBlock completion:completionBlock];
    [[UIApplication sharedApplication] setStatusBarHidden:_controlsHidden withAnimation:UIStatusBarAnimationFade];
}

- (void)resetIdleTimer
{
    if (!_idleTimer)
        _idleTimer = [NSTimer scheduledTimerWithTimeInterval:2.
                                                      target:self
                                                    selector:@selector(idleTimerExceeded)
                                                    userInfo:nil
                                                     repeats:NO];
    else {
        if (fabs([_idleTimer.fireDate timeIntervalSinceNow]) < 2.)
            [_idleTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:2.]];
    }
}

- (void)idleTimerExceeded
{
    _idleTimer = nil;
    if (!_controlsHidden)
        [self toggleControlsVisible];
}

- (UIResponder *)nextResponder
{
    [self resetIdleTimer];
    return [super nextResponder];
}

#pragma mark - controls

- (IBAction)closePlayback:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)positionSliderAction:(UISlider *)sender
{
    _mediaPlayer.position = sender.value;
    [self resetIdleTimer];
}

- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification {
    self.positionSlider.value = [_mediaPlayer position];
    self.timeDisplay.title = [[_mediaPlayer remainingTime] stringValue];
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    VLCMediaPlayerState currentState = _mediaPlayer.state;

    if (currentState == VLCMediaPlayerStateError) {
        [self.statusLabel showStatusMessage:NSLocalizedString(@"PLAYBACK_FAILED", @"")];
        [self performSelector:@selector(dismiss:) withObject:nil afterDelay:2.];
    }

    UIImage *playPauseImage = [_mediaPlayer isPlaying]? [UIImage imageNamed:@"pause"] : [UIImage imageNamed:@"play"];
    [_playPauseButton setImage:playPauseImage forState:UIControlStateNormal];

    if ([[_mediaPlayer audioTrackIndexes] count] > 2)
        self.audioSwitcherButton.hidden = NO;
    else
        self.audioSwitcherButton.hidden = YES;

    if ([[_mediaPlayer videoSubTitlesIndexes] count] > 1)
        self.subtitleSwitcherButton.hidden = NO;
    else
        self.subtitleSwitcherButton.hidden = YES;
}

- (IBAction)playPause
{
    if ([_mediaPlayer isPlaying]) {
        [_mediaPlayer pause];
    } else {
        [_mediaPlayer play];
    }
}

- (IBAction)forward:(id)sender
{
    [_mediaPlayer mediumJumpForward];
}

- (IBAction)backward:(id)sender
{
    [_mediaPlayer mediumJumpBackward];
}

- (IBAction)switchAudioTrack:(id)sender
{
    _audiotrackActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"CHOOSE_AUDIO_TRACK", @"audio track selector") delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    NSArray *audioTracks = [_mediaPlayer audioTrackNames];
    NSUInteger count = [audioTracks count];
    for (NSUInteger i = 0; i < count; i++)
        [_audiotrackActionSheet addButtonWithTitle:audioTracks[i]];
    [_audiotrackActionSheet addButtonWithTitle:NSLocalizedString(@"BUTTON_CANCEL", @"cancel button")];
    [_audiotrackActionSheet setCancelButtonIndex:[_audiotrackActionSheet numberOfButtons] - 1];
    [_audiotrackActionSheet showFromRect:[self.audioSwitcherButton frame] inView:self.audioSwitcherButton animated:YES];
}

- (IBAction)switchSubtitleTrack:(id)sender
{
    NSArray *spuTracks = [_mediaPlayer videoSubTitlesNames];
    NSUInteger count = [spuTracks count];
    if (count <= 1)
        return;
    _subtitleActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"CHOOSE_SUBTITLE_TRACK", @"subtitle track selector") delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (NSUInteger i = 0; i < count; i++)
        [_subtitleActionSheet addButtonWithTitle:spuTracks[i]];
    [_subtitleActionSheet addButtonWithTitle:NSLocalizedString(@"BUTTON_CANCEL", @"cancel button")];
    [_subtitleActionSheet setCancelButtonIndex:[_subtitleActionSheet numberOfButtons] - 1];
    [_subtitleActionSheet showFromRect:[self.subtitleSwitcherButton frame] inView:self.subtitleSwitcherButton animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSUInteger arrayIndex = 0;
    NSArray *indexArray;
    NSArray *namesArray;
    if (actionSheet == _subtitleActionSheet) {
        namesArray = _mediaPlayer.videoSubTitlesNames;
        arrayIndex = [namesArray indexOfObject:[actionSheet buttonTitleAtIndex:buttonIndex]];
        if (arrayIndex != NSNotFound) {
            indexArray = _mediaPlayer.videoSubTitlesIndexes;
            _mediaPlayer.currentVideoSubTitleIndex = [indexArray[arrayIndex] intValue];
        }
    } else if (actionSheet == _audiotrackActionSheet) {
        namesArray = _mediaPlayer.audioTrackNames;
        arrayIndex = [namesArray indexOfObject:[actionSheet buttonTitleAtIndex:buttonIndex]];
        if (arrayIndex != NSNotFound) {
            indexArray = _mediaPlayer.audioTrackIndexes;
            _mediaPlayer.currentAudioTrackIndex = [indexArray[arrayIndex] intValue];
        }
    }
}

#pragma mark - Video Filter UI

- (IBAction)videoFilterToggle:(id)sender
{
    if (!_playbackSpeedViewHidden)
        self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

    self.videoFilterView.hidden = !_videoFiltersHidden;
    _videoFiltersHidden = self.videoFilterView.hidden;
    self.controllerPanel.hidden = !_videoFiltersHidden;
}

- (IBAction)videoFilterSliderAction:(id)sender
{
    if (sender == self.hueSlider)
        _mediaPlayer.hue = (int)self.hueSlider.value;
    else if (sender == self.contrastSlider)
        _mediaPlayer.contrast = self.contrastSlider.value;
    else if (sender == self.brightnessSlider) {
        if ([self hasExternalDisplay])
            _mediaPlayer.brightness = self.brightnessSlider.value;
        else
            [[UIScreen mainScreen] setBrightness:(self.brightnessSlider.value / 2.)];
    } else if (sender == self.saturationSlider)
        _mediaPlayer.saturation = self.saturationSlider.value;
    else if (sender == self.gammaSlider)
        _mediaPlayer.gamma = self.gammaSlider.value;
    else if (sender == self.resetVideoFilterButton) {
        _mediaPlayer.hue = self.hueSlider.value = 0.;
        _mediaPlayer.contrast = self.contrastSlider.value = 1.;
        _mediaPlayer.brightness = self.brightnessSlider.value = 1.;
        _mediaPlayer.saturation = self.saturationSlider.value = 1.;
        _mediaPlayer.gamma = self.gammaSlider.value = 1.;
    } else
        APLog(@"unknown sender for videoFilterSliderAction");
    [self resetIdleTimer];
}

#pragma mark - playback view
- (IBAction)playbackSpeedSliderAction:(UISlider *)sender
{
    double speed = pow(2, sender.value / 17.);
    float rate = INPUT_RATE_DEFAULT / speed;
    if (_currentPlaybackRate != rate)
        [_mediaPlayer setRate:INPUT_RATE_DEFAULT / rate];
    _currentPlaybackRate = rate;
    [self _updatePlaybackSpeedIndicator];
    [self resetIdleTimer];
}

- (void)_updatePlaybackSpeedIndicator
{
    float f_value = self.playbackSpeedSlider.value;
    double speed =  pow(2, f_value / 17.);
    self.playbackSpeedIndicator.text = [NSString stringWithFormat:@"%.2fx", speed];
}

- (float)_playbackSpeed
{
    float f_rate = _mediaPlayer.rate;

    double value = 17 * log(f_rate) / log(2.);
    float returnValue = (int) ((value > 0) ? value + .5 : value - .5);

    if (returnValue < -34.)
        returnValue = -34.;
    else if (returnValue > 34.)
        returnValue = 34.;

    _currentPlaybackRate = returnValue;
    return returnValue;
}

- (IBAction)videoDimensionAction:(id)sender
{
    if (sender == self.playbackSpeedButton) {
        if (!_videoFiltersHidden)
            self.videoFilterView.hidden = _videoFiltersHidden = YES;

        self.playbackSpeedView.hidden = !_playbackSpeedViewHidden;
        _playbackSpeedViewHidden = self.playbackSpeedView.hidden;
    } else if (sender == self.aspectRatioButton) {
        NSUInteger count = [_aspectRatios count];

        if (_currentAspectRatioMask + 1 > count - 1) {
            _mediaPlayer.videoAspectRatio = NULL;
            _currentAspectRatioMask = 0;
            [self.statusLabel showStatusMessage:[NSString stringWithFormat:NSLocalizedString(@"AR_CHANGED", @""), NSLocalizedString(@"DEFAULT", @"")]];
        } else {
            _currentAspectRatioMask++;
            _mediaPlayer.videoAspectRatio = (char *)[_aspectRatios[_currentAspectRatioMask] UTF8String];
            [self.statusLabel showStatusMessage:[NSString stringWithFormat:NSLocalizedString(@"AR_CHANGED", @""), _aspectRatios[_currentAspectRatioMask]]];
        }
    } else if (sender == self.cropButton) {
        NSUInteger count = [_cropRatios count];

        if (_currentCropMask + 1 > count - 1) {
            _mediaPlayer.videoCropGeometry = NULL;
            _currentCropMask = 0;
            [self.statusLabel showStatusMessage:[NSString stringWithFormat:NSLocalizedString(@"CROP_CHANGED", @""), NSLocalizedString(@"DEFAULT", @"")]];
        } else {
            _currentCropMask++;
            _mediaPlayer.videoCropGeometry = (char *)[_cropRatios[_currentCropMask] UTF8String];
            [self.statusLabel showStatusMessage:[NSString stringWithFormat:NSLocalizedString(@"CROP_CHANGED", @""), _cropRatios[_currentCropMask]]];
        }
    }
}

#pragma mark -

- (void)appWillResign:(NSNotification *)aNotification
{
    self.mediaItem.lastPosition = @([_mediaPlayer position]);
}

#pragma mark - autorotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
           || toInterfaceOrientation != UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark - External Display

- (BOOL)hasExternalDisplay
{
    return ([[UIScreen screens] count] > 1);
}

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
