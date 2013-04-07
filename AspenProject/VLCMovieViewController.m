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
@property (nonatomic, retain) UIPopoverController *masterPopoverController;
@property (nonatomic, retain) UIWindow *externalWindow;
@end

@implementation VLCMovieViewController
@synthesize movieView=_movieView, backButton=_backButton, positionSlider=_positionSlider, timeDisplay=_timeDisplay, playPauseButton = _playPauseButton, bwdButton = _bwdButton, fwdButton = _fwdButton, subtitleSwitcherButton = _subtitleSwitcherButton, audioSwitcherButton = _audioSwitcherButton;
@synthesize toolbar = _toolbar,  controllerPanel = _controllerPanel;

- (void)dealloc
{
    [_mediaItem release];
    [_masterPopoverController release];
    [_externalWindow release];
    [_toolbar release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark - Managing the media item

- (void)setMediaItem:(id)newMediaItem
{
    if (_mediaItem != newMediaItem) {
        [_mediaItem release];
        _mediaItem = [newMediaItem retain];
    }

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

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(handleExternalScreenDidConnect:)
                   name:UIScreenDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(handleExternalScreenDidDisconnect:)
                   name:UIScreenDidDisconnectNotification object:nil];

    if ([self hasExternalDisplay]) {
        [self showOnExternalDisplay];
    }

    _movieView.userInteractionEnabled = NO;
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toogleControlsVisible)];
    recognizer.delegate = self;
    [self.view addGestureRecognizer:recognizer];
    [recognizer release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];

    if (self.mediaItem) {
        self.title = [self.mediaItem title];

        [_mediaPlayer setMedia:[VLCMedia mediaWithURL:[NSURL URLWithString:self.mediaItem.url]]];
        if (self.mediaItem.lastPosition && [self.mediaItem.lastPosition floatValue] < 0.99)
            [_mediaPlayer setPosition:[self.mediaItem.lastPosition floatValue]];
        [_mediaPlayer play];

        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    [_mediaPlayer pause];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [super viewWillDisappear:animated];
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
    if (touch.view != self.view) {
        return NO;
    }

    return YES;
}

- (void)toogleControlsVisible
{
    _controlsHidden = !_controlsHidden;
    CGFloat alpha = _controlsHidden? 0.0f: 1.0f;

    if (!_controlsHidden) {
        _controllerPanel.hidden = NO;
        _controllerPanel.alpha = 0.0f;
    }

    void (^animationBlock)() = ^() {
        _controllerPanel.alpha = alpha;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        _controllerPanel.hidden = _controlsHidden;
    };

    [UIView animateWithDuration:0.3f animations:animationBlock completion:completionBlock];
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
    NSArray * audioTracks = [_mediaPlayer audioTrackNames];
    NSUInteger count = [audioTracks count];
    for (NSUInteger i = 0; i < count; i++)
        [_audiotrackActionSheet addButtonWithTitle:[audioTracks objectAtIndex:i]];
    [_audiotrackActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"audio track selector")];
    [_audiotrackActionSheet setCancelButtonIndex:[_audiotrackActionSheet numberOfButtons] - 1];
    [_audiotrackActionSheet showFromRect:[self.audioSwitcherButton frame] inView:self.audioSwitcherButton animated:YES];
}

- (IBAction)switchSubtitleTrack:(id)sender
{
    NSArray * spuTracks = [_mediaPlayer videoSubTitlesNames];
    NSUInteger count = [spuTracks count];
    if (count <= 1)
        return;
    _subtitleActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Subtitle Track", @"subtitle track selector") delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (NSUInteger i = 0; i < count; i++)
        [_subtitleActionSheet addButtonWithTitle:[spuTracks objectAtIndex:i]];
    [_subtitleActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"subtitle track selector")];
    [_subtitleActionSheet setCancelButtonIndex:[_subtitleActionSheet numberOfButtons] - 1];
    [_subtitleActionSheet showFromRect:[self.subtitleSwitcherButton frame] inView:self.subtitleSwitcherButton animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSUInteger arrayIndex = 0;
    NSArray * indexArray;
    NSArray * namesArray;
    if (actionSheet == _subtitleActionSheet) {
        namesArray = _mediaPlayer.videoSubTitlesNames;
        arrayIndex = [namesArray indexOfObject:[actionSheet buttonTitleAtIndex:buttonIndex]];
        if (arrayIndex != NSNotFound) {
            indexArray = _mediaPlayer.videoSubTitlesIndexes;
            _mediaPlayer.currentVideoSubTitleIndex = [[indexArray objectAtIndex:arrayIndex] intValue];
        }
        [_subtitleActionSheet release];
    } else {
        namesArray = _mediaPlayer.audioTrackNames;
        arrayIndex = [namesArray indexOfObject:[actionSheet buttonTitleAtIndex:buttonIndex]];
        if (arrayIndex != NSNotFound) {
            indexArray = _mediaPlayer.audioTrackIndexes;
            _mediaPlayer.currentAudioTrackIndex = [[indexArray objectAtIndex:arrayIndex] intValue];
        }
        [_audiotrackActionSheet release];
    }
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark - External Display

- (BOOL)hasExternalDisplay
{
    return ([[UIScreen screens] count] > 1);
}

- (void)showOnExternalDisplay
{
    UIScreen *screen = [[UIScreen screens] objectAtIndex:1];
    screen.overscanCompensation = UIScreenOverscanCompensationInsetApplicationFrame;

    self.externalWindow = [[UIWindow alloc] initWithFrame:screen.bounds];

    UIViewController *controller = [[VLCExternalDisplayController alloc] init];
    self.externalWindow.rootViewController = controller;
    [controller.view addSubview:_movieView];
    controller.view.frame = screen.bounds;
    _movieView.frame = screen.bounds;


    self.externalWindow.screen = screen;
    self.externalWindow.hidden = NO;
}

- (void)hideFromExternalDisplay
{
    [self.view addSubview:_movieView];
    [self.view sendSubviewToBack:_movieView];
    _movieView.frame = self.view.frame;

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
