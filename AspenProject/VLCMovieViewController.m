//
//  VLCMovieViewController.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCMovieViewController.h"

@interface VLCMovieViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@end

@implementation VLCMovieViewController
@synthesize movieView=_movieView, tapBarView=_tapBarView, backButton=_backButton, positionSlider=_positionSlider, timeDisplay=_timeDisplay, playPauseButton = _playPauseButton, bwdButton = _bwdButton, fwdButton = _fwdButton, subtitleSwitcherButton = _subtitleSwitcherButton, audioSwitcherButton = _audioSwitcherButton, controllerPanel = _controllerPanel;

- (void)dealloc
{
    [_mediaItem release];
    [_masterPopoverController release];
    [super dealloc];
}

#pragma mark - Managing the media item

- (void)setMediaItem:(id)newMediaItem
{
    if (_mediaItem != newMediaItem) {
        [_mediaItem release];
        _mediaItem = [newMediaItem retain];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _mediaPlayer = [[VLCMediaPlayer alloc] init];
    [_mediaPlayer setDelegate:self];
    [_mediaPlayer setDrawable:self.movieView];
    self.navigationItem.leftBarButtonItem = self.backButton;
    self.navigationItem.titleView = self.positionSlider;
    self.navigationItem.rightBarButtonItem = self.timeDisplay;
    self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStylePlain;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.mediaItem) {
        self.title = [self.mediaItem title];

        [_mediaPlayer setMedia:[VLCMedia mediaWithURL:[NSURL URLWithString:self.mediaItem.url]]];
        if (self.mediaItem.lastPosition && [self.mediaItem.lastPosition floatValue] < 0.99)
            [_mediaPlayer setPosition:[self.mediaItem.lastPosition floatValue]];
        [_mediaPlayer play];

        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }
    self.tapBarView.hidden = NO;
    self.tapBarView.alpha = 1.0f;
}

- (void)viewWillDisappear:(BOOL)animated
{
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
    NSArray * audioTracks = [_mediaPlayer audioTracks];
    NSUInteger count = [audioTracks count];
    for (NSUInteger i = 1; i < count; i++) // skip the "Disable menu item"
        [_audiotrackActionSheet addButtonWithTitle:[audioTracks objectAtIndex:i]];
    [_audiotrackActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"audio track selector")];
    [_audiotrackActionSheet setCancelButtonIndex:[_audiotrackActionSheet numberOfButtons] - 1];
    [_audiotrackActionSheet showFromRect:[self.audioSwitcherButton frame] inView:self.audioSwitcherButton animated:YES];
}

- (IBAction)switchSubtitleTrack:(id)sender
{
    _subtitleActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Subtitle Track", @"subtitle track selector") delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    NSArray * spuTracks = [_mediaPlayer videoSubTitles];
    NSUInteger count = [spuTracks count];
    for (NSUInteger i = 0; i < count; i++)
        [_subtitleActionSheet addButtonWithTitle:[spuTracks objectAtIndex:i]];
    [_subtitleActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"subtitle track selector")];
    [_subtitleActionSheet setCancelButtonIndex:[_subtitleActionSheet numberOfButtons] - 1];
    [_subtitleActionSheet showFromRect:[self.subtitleSwitcherButton frame] inView:self.subtitleSwitcherButton animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { // "Cancel" button
        APLog(@"action sheet was canceled");
        return;
    }
    if (actionSheet == _subtitleActionSheet) {
        _mediaPlayer.currentVideoSubTitleIndex = buttonIndex;
        [_subtitleActionSheet release];
    } else {
        _mediaPlayer.currentAudioTrackIndex = buttonIndex;
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

@end
