/*****************************************************************************
 * VLCMiniPlaybackView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMiniPlaybackView.h"
#import "VLCPlaybackController.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"

@interface VLCMiniPlaybackView () <VLCPlaybackControllerDelegate>
{
    UIImageView *_artworkView;
    UIView *_videoView;
    UIButton *_previousButton;
    UIButton *_playPauseButton;
    UIButton *_nextButton;
    UIButton *_expandButton;
    UILabel *_metaDataLabel;
}

@end

@implementation VLCMiniPlaybackView

- (instancetype)initWithFrame:(CGRect)viewFrame
{
    self = [super initWithFrame:viewFrame];
    if (!self)
        return self;

    CGRect previousRect;
    CGFloat buttonSize = 44.;

    _artworkView = [[UIImageView alloc] initWithFrame:CGRectMake(0., 0., 60., 60.)];
    _artworkView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    _artworkView.backgroundColor = [UIColor VLCDarkBackgroundColor];
    _artworkView.opaque = YES;
    [self addSubview:_artworkView];

    /* build buttons from right to left */
    _expandButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_expandButton setImage:[UIImage imageNamed:@"ratioIcon"] forState:UIControlStateNormal];
    _expandButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [_expandButton addTarget:self action:@selector(pushFullPlaybackView:) forControlEvents:UIControlEventTouchUpInside];
    _expandButton.frame = previousRect = CGRectMake(viewFrame.size.width - buttonSize, (viewFrame.size.height - buttonSize) / 2., buttonSize, buttonSize);
    [self addSubview:_expandButton];

    _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_nextButton setImage:[UIImage imageNamed:@"forwardIcon"] forState:UIControlStateNormal];
    [_nextButton sizeToFit];
    _nextButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [_nextButton addTarget:self action:@selector(nextAction:) forControlEvents:UIControlEventTouchUpInside];
    _nextButton.frame = previousRect = CGRectMake(previousRect.origin.x - buttonSize, (viewFrame.size.height - buttonSize) / 2., buttonSize, buttonSize);
    [self addSubview:_nextButton];

    _playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playPauseButton setImage:[UIImage imageNamed:@"playIcon"] forState:UIControlStateNormal];
    [_playPauseButton sizeToFit];
    _playPauseButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [_playPauseButton addTarget:self action:@selector(playPauseAction:) forControlEvents:UIControlEventTouchUpInside];
    _playPauseButton.frame = previousRect = CGRectMake(previousRect.origin.x - buttonSize, (viewFrame.size.height - buttonSize) / 2., buttonSize, buttonSize);
    [self addSubview:_playPauseButton];

    _previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_previousButton setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [_previousButton sizeToFit];
    _previousButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [_previousButton addTarget:self action:@selector(previousAction:) forControlEvents:UIControlEventTouchUpInside];
    _previousButton.frame = previousRect = CGRectMake(previousRect.origin.x - buttonSize, (viewFrame.size.height - buttonSize) / 2., buttonSize, buttonSize);
    [self addSubview:_previousButton];

    CGFloat artworkViewWidth = _artworkView.frame.size.width;
    _metaDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(artworkViewWidth + 10., 0., previousRect.origin.x - artworkViewWidth - 10., viewFrame.size.height)];
    _metaDataLabel.font = [UIFont systemFontOfSize:12.];
    _metaDataLabel.textColor = [UIColor VLCLightTextColor];
    _metaDataLabel.numberOfLines = 0;
    _metaDataLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:_metaDataLabel];

    return self;
}

- (void)previousAction:(id)sender
{
    [[VLCPlaybackController sharedInstance] backward];
}

- (void)playPauseAction:(id)sender
{
    [[VLCPlaybackController sharedInstance] playPause];
}

- (void)nextAction:(id)sender
{
    [[VLCPlaybackController sharedInstance] forward];
}

- (void)pushFullPlaybackView:(id)sender
{
    [VLCPlaybackController sharedInstance].videoOutputView = nil;

    VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate presentMovieViewController];
}

- (void)setupForWork
{
    VLCPlaybackController *playbackController = [VLCPlaybackController sharedInstance];
    if (playbackController.isPlaying)
        [_playPauseButton setImage:[UIImage imageNamed:@"pauseIcon"] forState:UIControlStateNormal];
    else
        [_playPauseButton setImage:[UIImage imageNamed:@"playIcon"] forState:UIControlStateNormal];
    playbackController.delegate = self;
    [playbackController recoverDisplayedMetadata];
}

- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
currentMediaHasTrackToChooseFrom:(BOOL)currentMediaHasTrackToChooseFrom
        currentMediaHasChapters:(BOOL)currentMediaHasChapters
          forPlaybackController:(VLCPlaybackController *)controller
{
    UIImage *playPauseImage = isPlaying ? [UIImage imageNamed:@"pauseIcon"] : [UIImage imageNamed:@"playIcon"];
    [_playPauseButton setImage:playPauseImage forState:UIControlStateNormal];
}

- (void)displayMetadataForPlaybackController:(VLCPlaybackController *)controller
                                       title:(NSString *)title
                                     artwork:(UIImage *)artwork
                                      artist:(NSString *)artist
                                       album:(NSString *)album
                                   audioOnly:(BOOL)audioOnly
{
    if (audioOnly) {
        _artworkView.contentMode = UIViewContentModeScaleAspectFill;
        _artworkView.image = artwork ? artwork : [UIImage imageNamed:@"no-artwork"];
        if (_videoView) {
            [_videoView removeFromSuperview];
            _videoView = nil;
        }
    } else {
        _artworkView.image = nil;
        if (_videoView) {
            [_videoView removeFromSuperview];
            _videoView = nil;
        }
        _videoView = [[UIView alloc] initWithFrame:_artworkView.frame];
        [self addSubview:_videoView];

        if (!controller.presentingMovieViewController)
            controller.videoOutputView = _videoView;
    }

    NSString *metaDataString;
    if (artist)
        metaDataString = artist;
    if (album)
        metaDataString = [metaDataString stringByAppendingFormat:@" — %@", album];
    if (metaDataString)
        metaDataString = [metaDataString stringByAppendingFormat:@"\n%@", title];
    else
        metaDataString = title;

    _metaDataLabel.text = metaDataString;
}

- (void)presentingViewControllerShouldBeClosed:(VLCPlaybackController *)controller
{
    VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.playlistViewController displayMiniPlaybackViewIfNeeded];
}

- (void)presentingViewControllerShouldBeClosedAfterADelay:(VLCPlaybackController *)controller
{
    [self presentingViewControllerShouldBeClosed:controller];
}

@end
