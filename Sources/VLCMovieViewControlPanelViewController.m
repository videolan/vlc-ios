/*****************************************************************************
 * VLCMovieViewControlPanelViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan@tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import "VLCMovieViewControlPanelViewController.h"

@interface VLCMovieViewControlPanelViewController ()

@property (nonatomic, weak) IBOutlet UIView *playbackControls;
@property (nonatomic, assign) BOOL compactMode;
@end

@implementation VLCMovieViewControlPanelViewController

static const CGFloat maxCompactWidth = 420.0;


- (void)viewDidLoad {
    [super viewDidLoad];

    _playbackSpeedButton.accessibilityLabel = NSLocalizedString(@"PLAYBACK_SPEED", nil);
    _playbackSpeedButton.isAccessibilityElement = YES;

    _trackSwitcherButton.accessibilityLabel = NSLocalizedString(@"OPEN_TRACK_PANEL", nil);
    _trackSwitcherButton.isAccessibilityElement = YES;

    _bwdButton.accessibilityLabel = NSLocalizedString(@"BWD_BUTTON", nil);
    _bwdButton.isAccessibilityElement = YES;


    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(playPauseLongPress:)];
    [_playPauseButton addGestureRecognizer:longPressRecognizer];
    _playPauseButton.accessibilityLabel = NSLocalizedString(@"PLAY_PAUSE_BUTTON", nil);
    _playPauseButton.accessibilityHint = NSLocalizedString(@"LONGPRESS_TO_STOP", nil);
    _playPauseButton.isAccessibilityElement = YES;

    _fwdButton.accessibilityLabel = NSLocalizedString(@"FWD_BUTTON", nil);
    _fwdButton.isAccessibilityElement = YES;


    _videoFilterButton.accessibilityLabel = NSLocalizedString(@"VIDEO_FILTER", nil);
    _videoFilterButton.isAccessibilityElement = YES;


    // HACK: get the slider from volume view
    UISlider *volumeSlider = nil;
    for (id aView in self.volumeView.subviews){
        if ([aView isKindOfClass:[UISlider class]]){
            volumeSlider = (UISlider *)aView;
            break;
        }
    }
    [volumeSlider addTarget:nil action:@selector(volumeSliderAction:) forControlEvents:UIControlEventValueChanged];
    [self.volumeView setVolumeThumbImage:[UIImage imageNamed:@"sliderKnob"] forState:UIControlStateNormal];

    _compactMode = YES;
    [self setupConstraints:YES];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.volumeView.hidden = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.volumeView.hidden = YES;
}


- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.view setNeedsUpdateConstraints];
}

- (void) updateViewConstraints {

    BOOL compactMode = CGRectGetWidth(self.view.frame) <= maxCompactWidth;
    if (self.compactMode != compactMode) {
        self.compactMode = compactMode;
        [self setupConstraints:compactMode];
    }
    [super updateViewConstraints];
}

- (void) setupConstraints:(BOOL)compactMode {
    UIView *superview = self.view.superview;
    NSArray *oldConstraints = [self.view.constraints filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSLayoutConstraint * evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        if (!superview) {
            return YES;
        }
        return evaluatedObject.firstItem != superview && evaluatedObject.secondItem != superview;
    }]];
    [self.view removeConstraints:oldConstraints];

    NSDictionary *viewsDict = @{@"speed" : self.playbackSpeedButton,
                                @"track" : self.trackSwitcherButton,
                                @"playback" : self.playbackControls,
                                @"filter" : self.videoFilterButton,
                                @"actions" : self.moreActionsButton,
                                @"volume" : self.volumeView,
                                };

    NSMutableArray *constraints = [NSMutableArray array];
    if (compactMode) {

        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[speed]-8-[track]-(>=8)-[playback]-(>=8)-[filter]-8-[actions]-|"
                                                                                 options:NSLayoutFormatAlignAllCenterY
                                                                                 metrics:nil
                                                                                   views:viewsDict]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=10)-[volume]-(>=10)-|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:viewsDict]];

        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[playback]-[volume(==40)]-|"
                                                                                 options:NSLayoutFormatAlignAllCenterX
                                                                                 metrics:nil
                                                                                   views:viewsDict]];
    } else {
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[volume]-(>=8)-[playback]-(>=8)-[speed]-8-[track]-8-[filter]-8-[actions]-|"
                                                                                 options:NSLayoutFormatAlignAllCenterY
                                                                                 metrics:nil
                                                                                   views:viewsDict]];

        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[playback]-|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:viewsDict]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[volume(==40)]"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:viewsDict]];


    }

    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.playbackControls
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0]];
    
    [self.view addConstraints:constraints];
}


// needed for < iOS 8
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.view setNeedsUpdateConstraints];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.view setNeedsUpdateConstraints];
    } completion:nil];
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

- (void)updateButtons {
    [self updatePlayPauseButton];

    self.trackSwitcherButton.hidden = !self.playbackController.currentMediaHasTrackToChooseFrom;
    self.videoFilterButton.hidden = self.playbackController.audioOnlyPlaybackSession;
}

- (void)updatePlayPauseButton
{
    const BOOL isPlaying = self.playbackController.isPlaying;
    UIImage *playPauseImage = isPlaying ? [UIImage imageNamed:@"pauseIcon"] : [UIImage imageNamed:@"playIcon"];
    [_playPauseButton setImage:playPauseImage forState:UIControlStateNormal];
}

@end
