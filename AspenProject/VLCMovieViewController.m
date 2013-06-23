//
//  VLCMovieViewController.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCMovieViewController.h"
#import "VLCExternalDisplayController.h"
#import <AVFoundation/AVFoundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "UIDevice+SpeedCategory.h"

#define INPUT_RATE_DEFAULT  1000.

@interface VLCMovieViewController () <UIGestureRecognizerDelegate, AVAudioSessionDelegate>
{
    VLCMediaPlayer *_mediaPlayer;

    BOOL _controlsHidden;
    BOOL _videoFiltersHidden;
    BOOL _playbackSpeedViewHidden;

    UIActionSheet *_subtitleActionSheet;
    UIActionSheet *_audiotrackActionSheet;

    float _currentPlaybackRate;
    NSArray *_aspectRatios;
    NSUInteger _currentAspectRatioMask;

    NSTimer *_idleTimer;

    BOOL _shouldResumePlaying;
    BOOL _viewAppeared;
    BOOL _displayRemainingTime;
    BOOL _positionSet;
}

@property (nonatomic, strong) UIPopoverController *masterPopoverController;
@property (nonatomic, strong) UIWindow *externalWindow;
@end

@implementation VLCMovieViewController

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = @{kVLCShowRemainingTime : @(YES)};
    [defaults registerDefaults:appDefaults];
}

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

    self.videoFilterView.hidden = YES;
    _videoFiltersHidden = YES;
    _hueLabel.text = NSLocalizedString(@"VFILTER_HUE", @"");
    _contrastLabel.text = NSLocalizedString(@"VFILTER_CONTRAST", @"");
    _brightnessLabel.text = NSLocalizedString(@"VFILTER_BRIGHTNESS", @"");
    _saturationLabel.text = NSLocalizedString(@"VFILTER_SATURATION", @"");
    _gammaLabel.text = NSLocalizedString(@"VFILTER_GAMMA", @"");
    _playbackSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SPEED", @"");

    _scrubHelpLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_HELP", @"");

    self.playbackSpeedView.hidden = YES;
    _playbackSpeedViewHidden = YES;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(handleExternalScreenDidConnect:)
                   name:UIScreenDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(handleExternalScreenDidDisconnect:)
                   name:UIScreenDidDisconnectNotification object:nil];
    [center addObserver:self selector:@selector(applicationWillResignActive:)
                   name:UIApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationDidBecomeActive:)
                   name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationDidEnterBackground:)
                   name:UIApplicationDidEnterBackgroundNotification object:nil];

    _playingExternallyTitle.text = NSLocalizedString(@"PLAYING_EXTERNALLY_TITLE", @"");
    _playingExternallyDescription.text = NSLocalizedString(@"PLAYING_EXTERNALLY_DESC", @"");
    if ([self hasExternalDisplay])
        [self showOnExternalDisplay];

    _movieView.userInteractionEnabled = NO;
    UITapGestureRecognizer *tapOnVideoRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControlsVisible)];
    tapOnVideoRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapOnVideoRecognizer];

    _displayRemainingTime = [[[NSUserDefaults standardUserDefaults] objectForKey:kVLCShowRemainingTime] boolValue];

    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinchRecognizer.delegate = self;
    [self.view addGestureRecognizer:pinchRecognizer];

#if 0 // FIXME: trac #8742
    UISwipeGestureRecognizer *leftSwipeRecognizer = [[VLCHorizontalSwipeGestureRecognizer alloc] initWithTarget:self action:nil];
    leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    leftSwipeRecognizer.delegate = self;
    [self.view addGestureRecognizer:leftSwipeRecognizer];
    UISwipeGestureRecognizer *rightSwipeRecognizer = [[VLCHorizontalSwipeGestureRecognizer alloc] initWithTarget:self action:nil];
    rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    rightSwipeRecognizer.delegate = self;
    [self.view addGestureRecognizer:rightSwipeRecognizer];
    UISwipeGestureRecognizer *upSwipeRecognizer = [[VLCVerticalSwipeGestureRecognizer alloc] initWithTarget:self action:nil];
    upSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    upSwipeRecognizer.delegate = self;
    [self.view addGestureRecognizer:upSwipeRecognizer];
    UISwipeGestureRecognizer *downSwipeRecognizer = [[VLCVerticalSwipeGestureRecognizer alloc] initWithTarget:self action:nil];
    downSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    downSwipeRecognizer.delegate = self;
    [self.view addGestureRecognizer:downSwipeRecognizer];
#endif

    _aspectRatios = @[@"DEFAULT", @"4:3", @"16:9", @"16:10", @"2.21:1", @"FILL_TO_SCREEN"];

    [self.aspectRatioButton setBackgroundImage:[UIImage imageNamed:@"ratioButton"] forState:UIControlStateNormal];
    [self.aspectRatioButton setBackgroundImage:[UIImage imageNamed:@"ratioButtonHighlight"] forState:UIControlStateHighlighted];
    [self.aspectRatioButton setImage:[UIImage imageNamed:@"ratioIcon"] forState:UIControlStateNormal];
    [self.toolbar setBackgroundImage:[UIImage imageNamed:@"seekbarBg"] forBarMetrics:UIBarMetricsDefault];
    [self.backButton setBackgroundImage:[UIImage imageNamed:@"playbackDoneButton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self.backButton setBackgroundImage:[UIImage imageNamed:@"playbackDoneButtonHighlight"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];

    /* this looks a bit weird, but we need to support iOS 5 and should show the same appearance */
    UISlider *volumeSlider = nil;
    for (id aView in self.volumeView.subviews){
        if ([[[aView class] description] isEqualToString:@"MPVolumeSlider"]){
            volumeSlider = (UISlider *)aView;
            break;
        }
    }
    [volumeSlider setMinimumTrackImage:[[UIImage imageNamed:@"sliderminiValue"]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 0)] forState:UIControlStateNormal];
    [volumeSlider setMaximumTrackImage:[[UIImage imageNamed:@"slidermaxValue"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 4)] forState:UIControlStateNormal];
    [volumeSlider setThumbImage:[UIImage imageNamed:@"volumeballslider"] forState:UIControlStateNormal];
    [volumeSlider addTarget:self
                     action:@selector(volumeSliderAction:)
           forControlEvents:UIControlEventValueChanged];

    [[AVAudioSession sharedInstance] setDelegate:self];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self.positionSlider.scrubbingSpeedChangePositions = @[@(0.), @(100.), @(200.), @(300)];
}

- (BOOL)_blobCheck
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = searchPaths[0];

    if (![[NSFileManager defaultManager] fileExistsAtPath:[directoryPath stringByAppendingPathComponent:@"blob.bin"]])
        return NO;

    NSData *data = [NSData dataWithContentsOfFile:[directoryPath stringByAppendingPathComponent:@"blob.bin"]];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, digest);

    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

    for (unsigned int u = 0; u < CC_SHA1_DIGEST_LENGTH; u++)
        [hash appendFormat:@"%02x", digest[u]];

    if ([hash isEqualToString:kBlobHash])
        return YES;
    else
        return NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    _mediaPlayer = [[VLCMediaPlayer alloc] init];
    [_mediaPlayer setDelegate:self];
    [_mediaPlayer setDrawable:self.movieView];

    [self.navigationController setNavigationBarHidden:YES animated:YES];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;

    if (!self.mediaItem && !self.url)
        return;

    VLCMedia *media;
    if (self.mediaItem) {
        self.title = [self.mediaItem title];
        media = [VLCMedia mediaWithURL:[NSURL URLWithString:self.mediaItem.url]];
        self.mediaItem.unread = @(NO);
    } else {
        media = [VLCMedia mediaWithURL:self.url];
        self.title = @"Network Stream";
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [media addOptions:
     @{kVLCSettingStretchAudio :
           [[defaults objectForKey:kVLCSettingStretchAudio] boolValue] ? kVLCSettingStretchAudioOnValue : kVLCSettingStretchAudioOffValue, kVLCSettingTextEncoding : [defaults objectForKey:kVLCSettingTextEncoding], kVLCSettingSkipLoopFilter : [defaults objectForKey:kVLCSettingSkipLoopFilter]}];

    [NSTimeZone resetSystemTimeZone];
    NSString *tzName = [[NSTimeZone systemTimeZone] name];
    NSArray *tzNames = @[@"America/Adak", @"America/Anchorage", @"America/Boise", @"America/Chicago", @"America/Denver", @"America/Detroit", @"America/Indiana/Indianapolis", @"America/Indiana/Knox", @"America/Indiana/Marengo", @"America/Indiana/Petersburg", @"America/Indiana/Tell_City", @"America/Indiana/Vevay", @"America/Indiana/Vincennes", @"America/Indiana/Winamac", @"America/Juneau", @"America/Kentucky/Louisville", @"America/Kentucky/Monticello", @"America/Los_Angeles", @"America/Menominee", @"America/Metlakatla", @"America/New_York", @"America/Nome", @"America/North_Dakota/Beulah", @"America/North_Dakota/Center", @"America/North_Dakota/New_Salem", @"America/Phoenix", @"America/Puerto_Rico", @"America/Shiprock", @"America/Sitka", @"America/St_Thomas", @"America/Thule", @"America/Yakutat", @"Pacific/Guam", @"Pacific/Honolulu", @"Pacific/Johnston", @"Pacific/Kwajalein", @"Pacific/Midway", @"Pacific/Pago_Pago", @"Pacific/Saipan", @"Pacific/Wake"];

    if ([tzNames containsObject:tzName] || [[tzName stringByDeletingLastPathComponent] isEqualToString:@"US"]) {
        NSArray *tracksInfo = media.tracksInformation;
        for (NSUInteger x = 0; x < tracksInfo.count; x++) {
            if ([[tracksInfo[x] objectForKey:VLCMediaTracksInformationType] isEqualToString:VLCMediaTracksInformationTypeAudio])
            {
                NSInteger fourcc = [[tracksInfo[x] objectForKey:VLCMediaTracksInformationCodec] integerValue];

                switch (fourcc) {
                    case 540161377:
                    case 1647457633:
                    case 858612577:
                    case 862151027:
                    case 2126701:
                    case 544437348:
                    case 542331972:
                    case 1651733604:
                    case 1668510820:
                    case 1702065252:
                    case 1752396900:
                    case 1819505764:
                    case 18903917:
                    case 862151013:
                    {
                        if (![self _blobCheck]) {
                            [media addOptions:@{@"no-audio" : [NSNull null]}];
                            APLog(@"audio playback disabled because an unsupported codec was found");
                        }
                        break;
                    }

                    default:
                        break;
                }
            }
        }
    }

    [_mediaPlayer setMedia:media];

    self.positionSlider.value = 0.;
    [self.timeDisplay setTitle:@"" forState:UIControlStateNormal];

    [super viewWillAppear:animated];

    if (![self _isMediaSuitableForDevice]) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DEVICE_TOOSLOW_TITLE", @"") message:[NSString stringWithFormat:NSLocalizedString(@"DEVICE_TOOSLOW", @""), [[UIDevice currentDevice] model], self.mediaItem.title] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:NSLocalizedString(@"BUTTON_OPEN", @""), nil];
        [alert show];
    } else
        [self _playNewMedia];

    if (![self hasExternalDisplay])
        self.brightnessSlider.value = [UIScreen mainScreen].brightness * 2.;

    [self setControlsHidden:NO animated:YES];
    _viewAppeared = YES;
}

- (BOOL)_isMediaSuitableForDevice
{
    if (!self.mediaItem)
        return YES;

    NSUInteger totalNumberOfPixels = [[[self.mediaItem videoTrack] valueForKey:@"width"] doubleValue] * [[[self.mediaItem videoTrack] valueForKey:@"height"] doubleValue];

    NSInteger speedCategory = [[UIDevice currentDevice] speedCategory];

    if (speedCategory == 1) {
        // iPhone 3GS, iPhone 4, first gen. iPad, 3rd and 4th generation iPod touch
        return (totalNumberOfPixels < 600000); // between 480p and 720p
    } else if (speedCategory == 2) {
        // iPhone 4S, iPad 2 and 3, iPod 4 and 5
        return (totalNumberOfPixels < 922000); // 720p
    } else if (speedCategory == 3) {
        // iPhone 5, iPad 4
        return (totalNumberOfPixels < 2074000); // 1080p
    }

    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [self _playNewMedia];
    else
        [self closePlayback:nil];
}

- (void)_playNewMedia
{
    NSNumber *playbackPositionInTime = @(0);
    if (self.mediaItem.lastPosition && [self.mediaItem.lastPosition floatValue] < .95) {
        if (self.mediaItem.duration.intValue != 0)
            playbackPositionInTime = @(self.mediaItem.lastPosition.floatValue * (self.mediaItem.duration.intValue / 1000.));
    }
    [_mediaPlayer.media addOptions:@{@"start-time": playbackPositionInTime}];
    APLog(@"set starttime to %i", playbackPositionInTime.intValue);

    [_mediaPlayer play];

    self.playbackSpeedSlider.value = [self _playbackSpeed];
    [self _updatePlaybackSpeedIndicator];

    _currentAspectRatioMask = 0;
    _mediaPlayer.videoAspectRatio =  NULL;

    [self _resetIdleTimer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    _viewAppeared = NO;
    if (_idleTimer) {
        [_idleTimer invalidate];
        _idleTimer = nil;
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [_mediaPlayer pause];
    [super viewWillDisappear:animated];
    if (self.mediaItem)
        self.mediaItem.lastPosition = @([_mediaPlayer position]);
    [_mediaPlayer stop];
    _mediaPlayer = nil; // save memory and some CPU time

    // hide filter UI for next run
    if (!_videoFiltersHidden)
        _videoFiltersHidden = YES;

    if (!_playbackSpeedViewHidden)
        _playbackSpeedViewHidden = YES;
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

    [[NSUserDefaults standardUserDefaults] setBool:_displayRemainingTime forKey:kVLCShowRemainingTime];
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

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    if (recognizer.velocity < 0.)
        [self closePlayback:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view != self.view)
        return NO;

    return YES;
}

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated
{
    _controlsHidden = hidden;
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
    }

    void (^animationBlock)() = ^() {
        _controllerPanel.alpha = alpha;
        _toolbar.alpha = alpha;
        _videoFilterView.alpha = alpha;
        _playbackSpeedView.alpha = alpha;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        if (_videoFiltersHidden)
            _controllerPanel.hidden = _controlsHidden;
        else
            _controllerPanel.hidden = NO;
        _toolbar.hidden = _controlsHidden;
        _videoFilterView.hidden = _videoFiltersHidden;
        _playbackSpeedView.hidden = _playbackSpeedViewHidden;
    };

    UIStatusBarAnimation animationType = animated? UIStatusBarAnimationFade: UIStatusBarAnimationNone;
    NSTimeInterval animationDuration = animated? 0.3: 0.0;

    [[UIApplication sharedApplication] setStatusBarHidden:_viewAppeared ? _controlsHidden : NO withAnimation:animationType];
    [UIView animateWithDuration:animationDuration animations:animationBlock completion:completionBlock];

    _volumeView.hidden = _controllerPanel.hidden;
}

- (void)toggleControlsVisible
{
    if (_controlsHidden && !_videoFiltersHidden)
        _videoFiltersHidden = YES;

    [self setControlsHidden:!_controlsHidden animated:YES];
}

- (void)_resetIdleTimer
{
    if (!_idleTimer)
        _idleTimer = [NSTimer scheduledTimerWithTimeInterval:4.
                                                      target:self
                                                    selector:@selector(idleTimerExceeded)
                                                    userInfo:nil
                                                     repeats:NO];
    else {
        if (fabs([_idleTimer.fireDate timeIntervalSinceNow]) < 4.)
            [_idleTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:4.]];
    }
}

- (void)idleTimerExceeded
{
    _idleTimer = nil;
    if (!_controlsHidden)
        [self toggleControlsVisible];

    if (!_videoFiltersHidden)
        _videoFiltersHidden = YES;

    if (!_playbackSpeedViewHidden)
        _playbackSpeedViewHidden = YES;

    if (self.scrubIndicatorView.hidden == NO)
        self.scrubIndicatorView.hidden = YES;
}

- (UIResponder *)nextResponder
{
    [self _resetIdleTimer];
    return [super nextResponder];
}

#pragma mark - controls

- (IBAction)closePlayback:(id)sender
{
    [self setControlsHidden:NO animated:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)positionSliderAction:(UISlider *)sender
{
    /* we need to limit the number of events sent by the slider, since otherwise, the user
     * wouldn't see the I-frames when seeking on current mobile devices. This isn't a problem
     * within the Simulator, but especially on older ARMv7 devices, it's clearly noticeable. */
    [self performSelector:@selector(_setPositionForReal) withObject:nil afterDelay:0.3];
    VLCTime *newPosition = [VLCTime timeWithInt:(int)(_positionSlider.value * self.mediaItem.duration.intValue)];
    [self.timeDisplay setTitle:newPosition.stringValue forState:UIControlStateNormal];
    _positionSet = NO;
    [self _resetIdleTimer];
}

- (void)_setPositionForReal
{
    if (!_positionSet) {
        _mediaPlayer.position = _positionSlider.value;
        _positionSet = YES;
    }
}

- (IBAction)positionSliderTouchDown:(id)sender
{
    [self _updateScrubLabel];
    self.scrubIndicatorView.hidden = NO;
}

- (IBAction)positionSliderTouchUp:(id)sender
{
    self.scrubIndicatorView.hidden = YES;
}

- (void)_updateScrubLabel
{
    float speed = self.positionSlider.scrubbingSpeed;
    if (speed == 1.)
        self.currentScrubSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_HIGH", @"");
    else if (speed == .5)
        self.currentScrubSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_HALF", @"");
    else if (speed == .25)
        self.currentScrubSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_QUARTER", @"");
    else
        self.currentScrubSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_FINE", @"");

    [self _resetIdleTimer];
}

- (IBAction)positionSliderDrag:(id)sender
{
    [self _updateScrubLabel];
}

- (IBAction)volumeSliderAction:(id)sender
{
    [self _resetIdleTimer];
}

- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification {
    self.positionSlider.value = [_mediaPlayer position];
    if (_displayRemainingTime)
        [self.timeDisplay setTitle:[[_mediaPlayer remainingTime] stringValue] forState:UIControlStateNormal];
    else
        [self.timeDisplay setTitle:[[_mediaPlayer time] stringValue] forState:UIControlStateNormal];
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    VLCMediaPlayerState currentState = _mediaPlayer.state;

    if (currentState == VLCMediaPlayerStateError) {
        [self.statusLabel showStatusMessage:NSLocalizedString(@"PLAYBACK_FAILED", @"")];
        [self performSelector:@selector(closePlayback:) withObject:nil afterDelay:2.];
    }

    if (currentState == VLCMediaPlayerStateEnded || currentState == VLCMediaPlayerStateStopped)
        [self performSelector:@selector(closePlayback:) withObject:nil afterDelay:2.];

    UIImage *playPauseImage = [_mediaPlayer isPlaying]? [UIImage imageNamed:@"pauseIcon"] : [UIImage imageNamed:@"playIcon"];
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
    if ([_mediaPlayer isPlaying])
        [_mediaPlayer pause];
    else
        [_mediaPlayer play];
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
    NSArray *audioTrackIndexes = [_mediaPlayer audioTrackIndexes];

    NSUInteger count = [audioTracks count];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *indexIndicator = ([audioTrackIndexes[i] intValue] == [_mediaPlayer currentAudioTrackIndex])? @"\u2713": @"";
        NSString *buttonTitle = [NSString stringWithFormat:@"%@ %@", indexIndicator, audioTracks[i]];
        [_audiotrackActionSheet addButtonWithTitle:buttonTitle];
    }

    [_audiotrackActionSheet addButtonWithTitle:NSLocalizedString(@"BUTTON_CANCEL", @"cancel button")];
    [_audiotrackActionSheet setCancelButtonIndex:[_audiotrackActionSheet numberOfButtons] - 1];
    [_audiotrackActionSheet showInView:self.audioSwitcherButton];
}

- (IBAction)switchSubtitleTrack:(id)sender
{
    NSArray *spuTracks = [_mediaPlayer videoSubTitlesNames];
    NSArray *spuTrackIndexes = [_mediaPlayer videoSubTitlesIndexes];

    NSUInteger count = [spuTracks count];
    if (count <= 1)
        return;
    _subtitleActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"CHOOSE_SUBTITLE_TRACK", @"subtitle track selector") delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];

    for (NSUInteger i = 0; i < count; i++) {
        NSString *indexIndicator = ([spuTrackIndexes[i] intValue] == [_mediaPlayer currentVideoSubTitleIndex])? @"\u2713": @"";
        NSString *buttonTitle = [NSString stringWithFormat:@"%@ %@", indexIndicator, spuTracks[i]];
        [_subtitleActionSheet addButtonWithTitle:buttonTitle];
    }

    [_subtitleActionSheet addButtonWithTitle:NSLocalizedString(@"BUTTON_CANCEL", @"cancel button")];
    [_subtitleActionSheet setCancelButtonIndex:[_subtitleActionSheet numberOfButtons] - 1];
    [_subtitleActionSheet showInView: self.subtitleSwitcherButton];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [actionSheet cancelButtonIndex])
        return;

    NSArray *indexArray;
    if (actionSheet == _subtitleActionSheet) {
        indexArray = _mediaPlayer.videoSubTitlesIndexes;
        if (buttonIndex <= indexArray.count) {
            _mediaPlayer.currentVideoSubTitleIndex = [indexArray[buttonIndex] intValue];
        }
    } else if (actionSheet == _audiotrackActionSheet) {
        indexArray = _mediaPlayer.audioTrackIndexes;
        if (buttonIndex <= indexArray.count) {
            _mediaPlayer.currentAudioTrackIndex = [indexArray[buttonIndex] intValue];
        }
    }
}

- (IBAction)toggleTimeDisplay:(id)sender
{
    _displayRemainingTime = !_displayRemainingTime;

    [self _resetIdleTimer];
}

#pragma mark - swipe gestures

- (void)horizontalSwipePercentage:(CGFloat)percentage inView:(UIView *)view
{
    if (percentage != 0.) {
        _mediaPlayer.position = _mediaPlayer.position + percentage;
    }
}

- (void)verticalSwipePercentage:(CGFloat)percentage inView:(UIView *)view half:(NSUInteger)half
{
    if (percentage != 0.) {
        if (half > 0) {
            CGFloat currentValue = self.brightnessSlider.value;
            currentValue = currentValue + percentage;
            self.brightnessSlider.value = currentValue;
            if ([self hasExternalDisplay])
                _mediaPlayer.brightness = currentValue;
            else
                [[UIScreen mainScreen] setBrightness:currentValue / 2];
        } else
            NSLog(@"volume setting through swipe not implemented");//_mediaPlayer.audio.volume = percentage * 200;
    }
}

#pragma mark - Video Filter UI

- (IBAction)videoFilterToggle:(id)sender
{
    if (!_playbackSpeedViewHidden)
        self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (!_controlsHidden)
            self.controllerPanel.hidden = _controlsHidden = YES;
    }

    self.videoFilterView.hidden = !_videoFiltersHidden;
    _videoFiltersHidden = self.videoFilterView.hidden;
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
        [[UIScreen mainScreen] setBrightness:(self.brightnessSlider.value / 2.)];
        _mediaPlayer.saturation = self.saturationSlider.value = 1.;
        _mediaPlayer.gamma = self.gammaSlider.value = 1.;
    } else
        APLog(@"unknown sender for videoFilterSliderAction");
    [self _resetIdleTimer];
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
    [self _resetIdleTimer];
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
        [self _resetIdleTimer];
    } else if (sender == self.aspectRatioButton) {
        NSUInteger count = [_aspectRatios count];

        if (_currentAspectRatioMask + 1 > count - 1) {
            _mediaPlayer.videoAspectRatio = NULL;
            _mediaPlayer.videoCropGeometry = NULL;
            _currentAspectRatioMask = 0;
            [self.statusLabel showStatusMessage:[NSString stringWithFormat:NSLocalizedString(@"AR_CHANGED", @""), NSLocalizedString(@"DEFAULT", @"")]];
        } else {
            _currentAspectRatioMask++;

            if ([_aspectRatios[_currentAspectRatioMask] isEqualToString:@"FILL_TO_SCREEN"]) {
                UIScreen *screen;
                if (![self hasExternalDisplay])
                    screen = [UIScreen mainScreen];
                else
                    screen = [UIScreen screens][1];

                float f_ar = screen.bounds.size.width / screen.bounds.size.height;

                if (f_ar == (float)(640./1136.)) // iPhone 5 aka 16:9.01
                    _mediaPlayer.videoCropGeometry = "16:9";
                else if (f_ar == (float)(2./3.)) // all other iPhones
                    _mediaPlayer.videoCropGeometry = "16:10"; // libvlc doesn't support 2:3 crop
                else if (f_ar == .75) // all iPads
                    _mediaPlayer.videoCropGeometry = "4:3";
                else if (f_ar == .5625) // AirPlay
                    _mediaPlayer.videoCropGeometry = "16:9";
                else
                    APLog(@"unknown screen format %f, can't crop", f_ar);

                [self.statusLabel showStatusMessage:NSLocalizedString(@"FILL_TO_SCREEN", @"")];
                return;
            }

            _mediaPlayer.videoCropGeometry = NULL;
            _mediaPlayer.videoAspectRatio = (char *)[_aspectRatios[_currentAspectRatioMask] UTF8String];
            [self.statusLabel showStatusMessage:[NSString stringWithFormat:NSLocalizedString(@"AR_CHANGED", @""), _aspectRatios[_currentAspectRatioMask]]];
        }
    }
}

#pragma mark - background interaction

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
    if (self.mediaItem)
        self.mediaItem.lastPosition = @([_mediaPlayer position]);

    if (![[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingContinueAudioInBackgroundKey] boolValue]) {
        [_mediaPlayer pause];
        _shouldResumePlaying = YES;
    } else
        _mediaPlayer.currentVideoTrackIndex = 0;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    _shouldResumePlaying = NO;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (_shouldResumePlaying) {
        _shouldResumePlaying = NO;
        [_mediaPlayer play];
    } else
        _mediaPlayer.currentVideoTrackIndex = 1;
}

#pragma mark - autorotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
           || toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

#pragma mark - AVSession delegate
- (void)beginInterruption
{
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingContinueAudioInBackgroundKey] boolValue])
        _shouldResumePlaying = YES;

    [_mediaPlayer pause];
}

- (void)endInterruption
{
    if (_shouldResumePlaying) {
        [_mediaPlayer play];
        _shouldResumePlaying = NO;
    }
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
