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
#import "VLCPlayerDisplayController.h"

@interface VLCFullscreenMovieTVViewController ()
{
    BOOL _playerIsSetup;
    BOOL _viewAppeared;
}
@end

@implementation VLCFullscreenMovieTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(appBecameActive:)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(playbackDidStop:)
                   name:VLCPlaybackControllerPlaybackDidStop
                 object:nil];

    _movieView.userInteractionEnabled = NO;
    _playerIsSetup = NO;

    self.titleLabel.text = self.remainingTimeLabel.text = self.playedTimeLabel.text = @"";
    self.playbackProgressView.progress = .0;
    self.bottomOverlayView.hidden = YES;
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

    [super viewWillDisappear:animated];

    [[UIApplication sharedApplication] sendAction:@selector(closeFullscreenPlayback) to:nil from:self forEvent:nil];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - playback controller delegation

- (void)prepareForMediaPlayback:(VLCPlaybackController *)controller
{
    APLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)appBecameActive:(NSNotification *)aNotification
{
    VLCPlayerDisplayController *pdc = [VLCPlayerDisplayController sharedInstance];
    if (pdc.displayMode == VLCPlayerDisplayControllerDisplayModeFullscreen) {
        VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
        [vpc recoverDisplayedMetadata];
        if (vpc.videoOutputView != self.movieView) {
            vpc.videoOutputView = nil;
            vpc.videoOutputView = self.movieView;
        }
    }
}

- (void)playbackDidStop:(NSNotification *)aNotification
{
    [[UIApplication sharedApplication] sendAction:@selector(closeFullscreenPlayback) to:nil from:self forEvent:nil];
}

- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
currentMediaHasTrackToChooseFrom:(BOOL)currentMediaHasTrackToChooseFrom
        currentMediaHasChapters:(BOOL)currentMediaHasChapters
          forPlaybackController:(VLCPlaybackController *)controller
{
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
    self.remainingTimeLabel.text = [[mediaPlayer remainingTime] stringValue];
    self.playedTimeLabel.text = [[mediaPlayer time] stringValue];
    self.playbackProgressView.progress = mediaPlayer.position;
}

@end
