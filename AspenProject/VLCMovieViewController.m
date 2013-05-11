//
//  VLCMovieViewController.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCMovieViewController.h"
#import "VLCExternalDisplayController.h"

@interface VLCMovieViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIPopoverController *masterPopoverController;
@property (nonatomic, strong) UIWindow *externalWindow;
@end

@implementation VLCMovieViewController

- (void)dealloc
{
    [_mediaPlayer stop];
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
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toogleControlsVisible)];
    recognizer.delegate = self;
    [self.view addGestureRecognizer:recognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;

    if (!self.mediaItem)
        return;

    self.title = [self.mediaItem title];

    [_mediaPlayer setMedia:[VLCMedia mediaWithURL:[NSURL URLWithString:self.mediaItem.url]]];
    [_mediaPlayer play];

    if (self.mediaItem.lastPosition && [self.mediaItem.lastPosition floatValue] < 0.99)
        [_mediaPlayer setPosition:[self.mediaItem.lastPosition floatValue]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [_mediaPlayer pause];
    [super viewWillDisappear:animated];
    self.mediaItem.lastPosition = @([_mediaPlayer position]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
        self.title = @"Video Playback";
    return self;
}

#pragma mark - controls visibility

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view != self.view)
        return NO;

    return YES;
}

- (void)toogleControlsVisible
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
        _videoFilterButton.alpha = 0.0f;
        _videoFilterButton.hidden = NO;
    }

    void (^animationBlock)() = ^() {
        _controllerPanel.alpha = alpha;
        _toolbar.alpha = alpha;
        _videoFilterView.alpha = alpha;
        _videoFilterButton.alpha = alpha;
        _videoFilterButton.hidden = NO;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        if (_videoFiltersHidden)
            _controllerPanel.hidden = _controlsHidden;
        else
            _controllerPanel.hidden = YES;
        _toolbar.hidden = _controlsHidden;
        _videoFilterView.hidden = _videoFiltersHidden;
        _videoFilterButton.hidden = _controlsHidden;
    };

    [UIView animateWithDuration:0.3f animations:animationBlock completion:completionBlock];
    [[UIApplication sharedApplication] setStatusBarHidden:_controlsHidden withAnimation:UIStatusBarAnimationFade];
}

#pragma mark - controls

- (IBAction)closePlayback:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)positionSliderAction:(UISlider *)sender
{
    _mediaPlayer.position = sender.value;
}

- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification {
    self.positionSlider.value = [_mediaPlayer position];
    self.timeDisplay.title = [[_mediaPlayer remainingTime] stringValue];
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    // TODO
}

- (IBAction)play:(id)sender
{
    if ([_mediaPlayer isPlaying]) {
        [_mediaPlayer pause];
        _playPauseButton.titleLabel.text = @"Pse";
    } else {
        [_mediaPlayer play];
        _playPauseButton.titleLabel.text = @"Play";
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
    _audiotrackActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Audio Track", @"audio track selector") delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    NSArray *audioTracks = [_mediaPlayer audioTrackNames];
    NSUInteger count = [audioTracks count];
    for (NSUInteger i = 0; i < count; i++)
        [_audiotrackActionSheet addButtonWithTitle:audioTracks[i]];
    [_audiotrackActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"audio track selector")];
    [_audiotrackActionSheet setCancelButtonIndex:[_audiotrackActionSheet numberOfButtons] - 1];
    [_audiotrackActionSheet showFromRect:[self.audioSwitcherButton frame] inView:self.audioSwitcherButton animated:YES];
}

- (IBAction)switchSubtitleTrack:(id)sender
{
    NSArray *spuTracks = [_mediaPlayer videoSubTitlesNames];
    NSUInteger count = [spuTracks count];
    if (count <= 1)
        return;
    _subtitleActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Subtitle Track", @"subtitle track selector") delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (NSUInteger i = 0; i < count; i++)
        [_subtitleActionSheet addButtonWithTitle:spuTracks[i]];
    [_subtitleActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"subtitle track selector")];
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
    } else {
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
    else if (sender == self.brightnessSlider)
        _mediaPlayer.brightness = self.brightnessSlider.value;
    else if (sender == self.saturationSlider)
        _mediaPlayer.saturation = self.saturationSlider.value;
    else if (sender == self.gammaSlider)
        _mediaPlayer.gamma = self.gammaSlider.value;
    else
        APLog(@"unknown sender for videoFilterSliderAction");
}

#pragma mark -

- (void)appWillResign:(NSNotification *)aNotification
{
    self.mediaItem.lastPosition = @([_mediaPlayer position]);
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
