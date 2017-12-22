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
#import "VLCPlayerDisplayController.h"

#if TARGET_OS_IOS
#import "VLCKeychainCoordinator.h"
#endif

@interface VLCMiniPlaybackView () <UIGestureRecognizerDelegate>
{
    UIImageView *_artworkView;
    UIView *_videoView;
    UIButton *_previousButton;
    UIButton *_playPauseButton;
    UIButton *_nextButton;
    UIButton *_expandButton;
    UILabel *_metaDataLabel;
    UITapGestureRecognizer *_tapRecognizer;
}

@end

@implementation VLCMiniPlaybackView

- (instancetype)initWithFrame:(CGRect)viewFrame
{
    self = [super initWithFrame:viewFrame];
    if (self) {
        [self setupSubviews];

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self
                   selector:@selector(appBecameActive:)
                       name:UIApplicationDidBecomeActiveNotification
                     object:nil];
    }
    return self;
}

- (void)setupSubviews
{
    CGFloat buttonSize = 44.;
    CGFloat videoSize = 60.;
    CGFloat padding = 10.;
    CGFloat buttonPadding = 5.;

    _artworkView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _artworkView.translatesAutoresizingMaskIntoConstraints = NO;
    _artworkView.clipsToBounds = YES;
    _artworkView.backgroundColor = [UIColor VLCDarkBackgroundColor];
    _artworkView.opaque = YES;
    [self addSubview:_artworkView];

    _videoView = [[UIView alloc] initWithFrame:CGRectZero];
    [_videoView setClipsToBounds:YES];
    _videoView.userInteractionEnabled = NO;
    _videoView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_videoView];

    _expandButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_expandButton setImage:[UIImage imageNamed:@"ratioIcon"] forState:UIControlStateNormal];
    _expandButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_expandButton addTarget:self action:@selector(pushFullPlaybackView:) forControlEvents:UIControlEventTouchUpInside];
    _expandButton.accessibilityLabel = NSLocalizedString(@"FULLSCREEN_PLAYBACK", nil);

    _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_nextButton setImage:[UIImage imageNamed:@"forwardIcon"] forState:UIControlStateNormal];
    _nextButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_nextButton addTarget:self action:@selector(nextAction:) forControlEvents:UIControlEventTouchUpInside];
    _nextButton.accessibilityLabel = NSLocalizedString(@"FWD_BUTTON", nil);

    _playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playPauseButton setImage:[UIImage imageNamed:@"playIcon"] forState:UIControlStateNormal];
    _playPauseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_playPauseButton addTarget:self action:@selector(playPauseAction:) forControlEvents:UIControlEventTouchUpInside];
    _playPauseButton.accessibilityLabel = NSLocalizedString(@"PLAY_PAUSE_BUTTON", nil);
    _playPauseButton.accessibilityHint = NSLocalizedString(@"LONGPRESS_TO_STOP", nil);
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(playPauseLongPress:)];
    [_playPauseButton addGestureRecognizer:longPressRecognizer];

    _previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_previousButton setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [_previousButton sizeToFit];
    _previousButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_previousButton addTarget:self action:@selector(previousAction:) forControlEvents:UIControlEventTouchUpInside];
    _previousButton.accessibilityLabel = NSLocalizedString(@"BWD_BUTTON", nil);

    _metaDataLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _metaDataLabel.font = [UIFont systemFontOfSize:12.];
    _metaDataLabel.textColor = [UIColor VLCLightTextColor];
    _metaDataLabel.numberOfLines = 0;
    _metaDataLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_metaDataLabel];

    [self addSubview:_previousButton];
    [self addSubview:_playPauseButton];
    [self addSubview:_nextButton];
    [self addSubview:_expandButton];

    NSObject *guide = self;
    if (@available(iOS 11.0, *)) {
        guide = self.safeAreaLayoutGuide;
    }

    [self addConstraints:@[
                             [NSLayoutConstraint constraintWithItem:_artworkView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeTop multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_artworkView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_artworkView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_metaDataLabel attribute:NSLayoutAttributeLeft multiplier:1 constant:-padding],
                             [NSLayoutConstraint constraintWithItem:_artworkView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_artworkView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:videoSize],
                             [NSLayoutConstraint constraintWithItem:_artworkView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_artworkView attribute:NSLayoutAttributeWidth multiplier:1 constant:0],

                             [NSLayoutConstraint constraintWithItem:_videoView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeTop multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_videoView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_videoView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_metaDataLabel attribute:NSLayoutAttributeLeft multiplier:1 constant:-padding],
                             [NSLayoutConstraint constraintWithItem:_videoView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_videoView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:videoSize],
                             [NSLayoutConstraint constraintWithItem:_videoView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_videoView attribute:NSLayoutAttributeWidth multiplier:1 constant:0],

                             [NSLayoutConstraint constraintWithItem:_metaDataLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeTop multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_metaDataLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:_previousButton attribute:NSLayoutAttributeLeft multiplier:1 constant:-padding],
                             [NSLayoutConstraint constraintWithItem:_metaDataLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeBottom multiplier:1 constant:0],

                             [NSLayoutConstraint constraintWithItem:_previousButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:buttonSize],
                             [NSLayoutConstraint constraintWithItem:_previousButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeTop multiplier:1 constant:padding],
                             [NSLayoutConstraint constraintWithItem:_previousButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeBottom multiplier:1 constant:-padding],
                             [NSLayoutConstraint constraintWithItem:_previousButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_playPauseButton attribute:NSLayoutAttributeLeft multiplier:1 constant:-buttonPadding],

                             [NSLayoutConstraint constraintWithItem:_playPauseButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:buttonSize],
                             [NSLayoutConstraint constraintWithItem:_playPauseButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeTop multiplier:1 constant:padding],
                             [NSLayoutConstraint constraintWithItem:_playPauseButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeBottom multiplier:1 constant:-padding],
                             [NSLayoutConstraint constraintWithItem:_playPauseButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_nextButton attribute:NSLayoutAttributeLeft multiplier:1 constant:-buttonPadding],

                             [NSLayoutConstraint constraintWithItem:_nextButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:buttonSize],
                             [NSLayoutConstraint constraintWithItem:_nextButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeTop multiplier:1 constant:padding],
                             [NSLayoutConstraint constraintWithItem:_nextButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeBottom multiplier:1 constant:-padding],
                             [NSLayoutConstraint constraintWithItem:_nextButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_expandButton attribute:NSLayoutAttributeLeft multiplier:1 constant:-buttonPadding],

                             [NSLayoutConstraint constraintWithItem:_expandButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:buttonSize],
                             [NSLayoutConstraint constraintWithItem:_expandButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeTop multiplier:1 constant:padding],
                             [NSLayoutConstraint constraintWithItem:_expandButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeBottom multiplier:1 constant:-padding],
                             [NSLayoutConstraint constraintWithItem:_expandButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeRight multiplier:1 constant:-buttonPadding],
                             ]];

    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized)];
    _tapRecognizer.delegate = self;
    [self addGestureRecognizer:_tapRecognizer];

#if TARGET_OS_IOS
    _tapRecognizer.numberOfTouchesRequired = 1;
#endif
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)appBecameActive:(NSNotification *)aNotification
{
    VLCPlayerDisplayController *pdc = [VLCPlayerDisplayController sharedInstance];
    if (pdc.displayMode == VLCPlayerDisplayControllerDisplayModeMiniplayer) {
        [[VLCPlaybackController sharedInstance] recoverDisplayedMetadata];
    }
}

- (void)tapRecognized
{
    [self pushFullPlaybackView:nil];
}

- (void)previousAction:(id)sender
{
    [[VLCPlaybackController sharedInstance] backward];
}

- (void)playPauseAction:(id)sender
{
    [[VLCPlaybackController sharedInstance] playPause];
}

- (void)playPauseLongPress:(UILongPressGestureRecognizer *)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [_playPauseButton setImage:[UIImage imageNamed:@"stopIcon"] forState:UIControlStateNormal];
            break;
        case UIGestureRecognizerStateEnded:
            [[VLCPlaybackController sharedInstance] stopPlayback];
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
    [[VLCPlaybackController sharedInstance] forward];
}

- (void)pushFullPlaybackView:(id)sender
{
    [[UIApplication sharedApplication] sendAction:@selector(showFullscreenPlayback) to:nil from:self forEvent:nil];
}

- (void)updatePlayPauseButton
{
    const BOOL isPlaying = [VLCPlaybackController sharedInstance].isPlaying;
    UIImage *playPauseImage = isPlaying ? [UIImage imageNamed:@"pauseIcon"] : [UIImage imageNamed:@"playIcon"];
    [_playPauseButton setImage:playPauseImage forState:UIControlStateNormal];
}

- (void)prepareForMediaPlayback:(VLCPlaybackController *)controller
{
    [self updatePlayPauseButton];
    controller.delegate = self;
    [controller recoverDisplayedMetadata];
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
    _videoView.hidden = YES;
    if (audioOnly) {
        _artworkView.contentMode = UIViewContentModeScaleAspectFill;
        _artworkView.image = artwork?: [UIImage imageNamed:@"no-artwork"];
    } else {
        _artworkView.image = nil;
        VLCPlayerDisplayController *pdc = [VLCPlayerDisplayController sharedInstance];
        if (pdc.displayMode == VLCPlayerDisplayControllerDisplayModeMiniplayer) {
            _videoView.hidden = false;
            controller.videoOutputView = _videoView;
        }
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
