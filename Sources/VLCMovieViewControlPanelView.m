/*****************************************************************************
 * VLCMovieViewControlPanelView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan@tobias-conradi.de>
 *          Carola Nitz <nitz.carola@googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMovieViewControlPanelView.h"
#import "VLCPlaybackController.h"
#import "VLCMetadata.h"

@interface VLCMovieViewControlPanelView ()

@property (nonatomic, strong) UIView *playbackControls;
@property (nonatomic, strong) UIView *spacer1;
@property (nonatomic, strong) UIView *spacer2;
@property (nonatomic, strong) NSMutableArray *constraints;
@property (nonatomic, assign) BOOL compactMode;
@property (nonatomic, strong) VLCPlaybackController *playbackController;
@end

@implementation VLCMovieViewControlPanelView

static const CGFloat maxControlsWidth = 474.0;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
        [self setupConstraints];
        _compactMode = YES;
        [self setupConstraints:_compactMode];
    }
    return self;
}

- (void)setupSubviews
{
    _playbackSpeedButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_playbackSpeedButton setImage:[UIImage imageNamed:@"speedIcon"] forState:UIControlStateNormal];
    _playbackSpeedButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_playbackSpeedButton];

    _trackSwitcherButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_trackSwitcherButton setImage:[UIImage imageNamed:@"audioTrackIcon"] forState:UIControlStateNormal];
    _trackSwitcherButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_trackSwitcherButton];

    _playbackControls = [[UIView alloc] initWithFrame:CGRectZero];
    _playbackControls.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_playbackControls];

    _bwdButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_bwdButton setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    _bwdButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_playbackControls addSubview:_bwdButton];

    _spacer1 = [UIView new];
    _spacer1.backgroundColor = [UIColor clearColor];
    _spacer1.translatesAutoresizingMaskIntoConstraints = NO;
    [_playbackControls addSubview:_spacer1];

    _spacer2 = [UIView new];
    _spacer2.backgroundColor = [UIColor clearColor];
    _spacer2.translatesAutoresizingMaskIntoConstraints = NO;
    [_playbackControls addSubview:_spacer2];

    _playPauseButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_playPauseButton setImage:[UIImage imageNamed:@"playIcon"] forState:UIControlStateNormal];
    _playPauseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_playbackControls addSubview:_playPauseButton];

    _fwdButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_fwdButton setImage:[UIImage imageNamed:@"forwardIcon"] forState:UIControlStateNormal];
    _fwdButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_playbackControls addSubview:_fwdButton];

    _videoFilterButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_videoFilterButton setImage:[UIImage imageNamed:@"videoEffectsIcon"] forState:UIControlStateNormal];
    _videoFilterButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_videoFilterButton];

    _moreActionsButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_moreActionsButton setImage:[UIImage imageNamed:@"More"] forState:UIControlStateNormal];
    _moreActionsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_moreActionsButton];

    _volumeView = [[VLCVolumeView alloc] initWithFrame:CGRectZero];
    _volumeView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_volumeView];

    _playbackSpeedButton.accessibilityLabel = NSLocalizedString(@"PLAYBACK_SPEED", nil);
    _trackSwitcherButton.accessibilityLabel = NSLocalizedString(@"OPEN_TRACK_PANEL", nil);
    _bwdButton.accessibilityLabel = NSLocalizedString(@"BWD_BUTTON", nil);
    _playPauseButton.accessibilityLabel = NSLocalizedString(@"PLAY_PAUSE_BUTTON", nil);
    _playPauseButton.accessibilityHint = NSLocalizedString(@"LONGPRESS_TO_STOP", nil);
    _fwdButton.accessibilityLabel = NSLocalizedString(@"FWD_BUTTON", nil);
    _videoFilterButton.accessibilityLabel = NSLocalizedString(@"VIDEO_FILTER", nil);

    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(playPauseLongPress:)];
    [_playPauseButton addGestureRecognizer:longPressRecognizer];

    [self.volumeView setVolumeThumbImage:[UIImage imageNamed:@"sliderKnob"] forState:UIControlStateNormal];
}

- (void)setupConstraints
{
    NSDictionary *viewsDict = @{
                                @"forward" : self.fwdButton,
                                @"backward" : self.bwdButton,
                                @"playpause" : self.playPauseButton,
                                @"speed" : self.playbackSpeedButton,
                                @"track" : self.trackSwitcherButton,
                                @"more" : self.moreActionsButton,
                                @"filter" : self.videoFilterButton,
                                @"volume" : self.volumeView,
                                @"spacer1" : _spacer1,
                                @"spacer2" : _spacer2,
                                };
    NSMutableArray *staticConstraints = [NSMutableArray new];

    [staticConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[backward(40)][spacer1(margin@750)][playpause(40)][spacer2(==spacer1)][forward(40)]|"
                                                                              options:NSLayoutFormatAlignAllCenterY
                                                                              metrics:@{@"margin": @15.0}
                                                                                views:viewsDict]];

    [staticConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backward(40)]|"
                                                                                   options:NSLayoutFormatAlignAllCenterX
                                                                                   metrics:nil
                                                                                     views:viewsDict]];
    for (NSString *object in viewsDict) {
        NSString *format = [NSString stringWithFormat:@"V:[%@(40)]", object];

        [staticConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:format
                                                                                       options:NSLayoutFormatAlignAllCenterX
                                                                                       metrics:nil
                                                                                         views:viewsDict]];
    }
    [self addConstraints:staticConstraints];
}

- (void)updateViewConstraints
{
    BOOL compactMode = CGRectGetWidth(self.frame) <= maxControlsWidth;
    if (self.compactMode != compactMode) {
        self.compactMode = compactMode;
        [self setupConstraints:compactMode];
    }
}

- (void)setupConstraints:(BOOL)compactMode
{
    if (_constraints != nil) {
        [self removeConstraints:_constraints];
    }

    NSDictionary *viewsDict = @{@"speed" : self.playbackSpeedButton,
                                @"track" : self.trackSwitcherButton,
                                @"playback" : self.playbackControls,
                                @"filter" : self.videoFilterButton,
                                @"actions" : self.moreActionsButton,
                                @"volume" : self.volumeView,
                                };

    _constraints = [NSMutableArray array];
    if (compactMode) {

        [_constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[speed(35)]-[track(35)]-(>=8)-[playback]-(>=8)-[filter(35)]-[actions(35)]-|"
                                                                                 options:NSLayoutFormatAlignAllCenterY
                                                                                 metrics:nil
                                                                                   views:viewsDict]];
        [_constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=10)-[volume(==300)]-(>=10)-|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:viewsDict]];

        [_constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[playback]-[volume]-|"
                                                                                 options:NSLayoutFormatAlignAllCenterX
                                                                                 metrics:nil
                                                                                   views:viewsDict]];
    } else {
        [_constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[volume(>=150)]-(>=8)-[playback]-(>=8)-[speed(35)]-[track(35)]-[filter(35)]-[actions(35)]-|"
                                                                                 options:NSLayoutFormatAlignAllCenterY
                                                                                 metrics:nil
                                                                                   views:viewsDict]];

        [_constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[playback]-|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:viewsDict]];
    }

    [_constraints addObject:[NSLayoutConstraint constraintWithItem:self.playbackControls
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0]];
    
    [self addConstraints:_constraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateViewConstraints];
}

- (VLCPlaybackController *)playbackController
{
    if (!_playbackController) {
        _playbackController = [VLCPlaybackController sharedInstance];
    }
    return _playbackController;
}

- (void)playPauseLongPress:(UILongPressGestureRecognizer *)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        {   UIImage *image = [UIImage imageNamed:@"stopIcon"];
            [_playPauseButton setImage:image forState:UIControlStateNormal];
        }
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

- (void)updateButtons
{
    [self updatePlayPauseButton];

    self.trackSwitcherButton.hidden = !self.playbackController.currentMediaHasTrackToChooseFrom;
    self.videoFilterButton.hidden = self.playbackController.metadata.isAudioOnly;
}

- (void)updatePlayPauseButton
{
    const BOOL isPlaying = self.playbackController.isPlaying;
    UIImage *playPauseImage = isPlaying ? [UIImage imageNamed:@"pauseIcon"] : [UIImage imageNamed:@"playIcon"];
    [_playPauseButton setImage:playPauseImage forState:UIControlStateNormal];
}

@end
