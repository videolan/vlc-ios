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

@interface VLCMiniPlaybackView () <VLCPlaybackControllerDelegate, UIGestureRecognizerDelegate>
{
    UIImageView *_artworkView;
    UIView *_videoView;
    UIButton *_previousButton;
    UIButton *_playPauseButton;
    UIButton *_nextButton;
    UIButton *_expandButton;
    UILabel *_metaDataLabel;
    UITapGestureRecognizer *_labelTapRecognizer;
    UITapGestureRecognizer *_artworkTapRecognizer;
}
@property (nonatomic, weak) VLCPlaybackController *playbackController;

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
    _playPauseButton.accessibilityLabel = NSLocalizedString(@"PLAY_PAUSE_BUTTON", nil);
    _playPauseButton.accessibilityHint = NSLocalizedString(@"LONGPRESS_TO_STOP", nil);
    _playPauseButton.isAccessibilityElement = YES;
    _playPauseButton.frame = previousRect = CGRectMake(previousRect.origin.x - buttonSize, (viewFrame.size.height - buttonSize) / 2., buttonSize, buttonSize);
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(playPauseLongPress:)];
    [_playPauseButton addGestureRecognizer:longPressRecognizer];
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

    _labelTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized)];
    _labelTapRecognizer.delegate = self;
    _labelTapRecognizer.numberOfTouchesRequired = 1;
    [_metaDataLabel addGestureRecognizer:_labelTapRecognizer];
    _metaDataLabel.userInteractionEnabled = YES;

    _artworkTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized)];
    _artworkTapRecognizer.delegate = self;
    _artworkTapRecognizer.numberOfTouchesRequired = 1;
    [_artworkView addGestureRecognizer:_artworkTapRecognizer];
    _artworkView.userInteractionEnabled = YES;

    return self;
}

- (void)tapRecognized
{
    [self pushFullPlaybackView:nil];
}

- (void)previousAction:(id)sender
{
    [self.playbackController backward];
}

- (void)playPauseAction:(id)sender
{
    [self.playbackController playPause];
}

- (void)playPauseLongPress:(UILongPressGestureRecognizer *)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [_playPauseButton setImage:[UIImage imageNamed:@"stopIcon"] forState:UIControlStateNormal];
            break;
        case UIGestureRecognizerStateEnded:
            [self.playbackController stopPlayback];
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self updatePlayPauseButton];
            break;
        default:
            break;
    }
}

- (void)nextAction:(id)sender
{
    [self.playbackController forward];
}

- (void)pushFullPlaybackView:(id)sender
{
    [[UIApplication sharedApplication] sendAction:@selector(showFullscreenPlayback) to:nil from:self forEvent:nil];
}


- (void)updatePlayPauseButton
{
    const BOOL isPlaying = self.playbackController.isPlaying;
    UIImage *playPauseImage = isPlaying ? [UIImage imageNamed:@"pauseIcon"] : [UIImage imageNamed:@"playIcon"];
    [_playPauseButton setImage:playPauseImage forState:UIControlStateNormal];
}

- (void)setupForWork:(VLCPlaybackController *)playbackController
{
    self.playbackController = playbackController;
    [self updatePlayPauseButton];
    playbackController.delegate = self;
    [playbackController recoverDisplayedMetadata];
}

- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
currentMediaHasTrackToChooseFrom:(BOOL)currentMediaHasTrackToChooseFrom
        currentMediaHasChapters:(BOOL)currentMediaHasChapters
          forPlaybackController:(VLCPlaybackController *)controller
{
    [self updatePlayPauseButton];
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
        [_artworkView addGestureRecognizer:_artworkTapRecognizer];
    } else {
        _artworkView.image = nil;
        if (_videoView) {
            [_videoView removeFromSuperview];
            _videoView = nil;
        }
        _videoView = [[UIView alloc] initWithFrame:_artworkView.frame];
        [_videoView setClipsToBounds:YES];
        [_videoView addGestureRecognizer:_artworkTapRecognizer];
        _videoView.userInteractionEnabled = YES;
        [self addSubview:_videoView];
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

@end
