/*****************************************************************************
 * VLCMovieViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Ahmad Harb <harb.dev.leb # gmail.com>
 *          Fabio Ritrovato <sephiroth87 # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Jean-Baptiste Kempf <jb # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMovieViewController.h"
#import "VLCExternalDisplayController.h"
#import <AVFoundation/AVFoundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "UIDevice+SpeedCategory.h"
#import "VLCBugreporter.h"
#import "VLCThumbnailsCache.h"

#import "OBSlider.h"
#import "VLCStatusLabel.h"

#define INPUT_RATE_DEFAULT  1000.
#define FORWARD_SWIPE_DURATION 30
#define BACKWARD_SWIPE_DURATION 10

@interface VLCMovieViewController () <UIGestureRecognizerDelegate, AVAudioSessionDelegate, VLCMediaDelegate>
{
    VLCMediaListPlayer *_listPlayer;
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
    BOOL _playerIsSetup;
    BOOL _isScrubbing;

    BOOL _swipeGesturesEnabled;
    NSString * panType;
    UIPinchGestureRecognizer *_pinchRecognizer;
    UIPanGestureRecognizer *_panRecognizer;
    UISwipeGestureRecognizer *_swipeRecognizerLeft;
    UISwipeGestureRecognizer *_swipeRecognizerRight;
    UITapGestureRecognizer *_tapRecognizer;
    UITapGestureRecognizer *_tapOnVideoRecognizer;
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

    if (_tapRecognizer)
        [self.view removeGestureRecognizer:_tapRecognizer];
    if (_swipeRecognizerLeft)
        [self.view removeGestureRecognizer:_swipeRecognizerLeft];
    if (_swipeRecognizerRight)
        [self.view removeGestureRecognizer:_swipeRecognizerRight];
    if (_panRecognizer)
        [self.view removeGestureRecognizer:_panRecognizer];
    if (_pinchRecognizer)
        [self.view removeGestureRecognizer:_pinchRecognizer];
    [self.view removeGestureRecognizer:_tapOnVideoRecognizer];

    _tapRecognizer = nil;
    _swipeRecognizerLeft = nil;
    _swipeRecognizerRight = nil;
    _panRecognizer = nil;
    _pinchRecognizer = nil;
    _tapOnVideoRecognizer = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Managing the media item

- (void)setMediaItem:(id)newMediaItem
{
    if (_mediaItem != newMediaItem) {
        [self _stopPlayback];
        _mediaItem = newMediaItem;
        if (_viewAppeared)
            [self _startPlayback];
    }

    if (self.masterPopoverController != nil)
        [self.masterPopoverController dismissPopoverAnimated:YES];
}

- (void)setUrl:(NSURL *)url
{
    [self _stopPlayback];
    _url = url;
    _playerIsSetup = NO;
    if (_viewAppeared)
        [self _startPlayback];
}

- (void)setMediaList:(VLCMediaList *)mediaList
{
    [self _stopPlayback];
    _mediaList = mediaList;
    _playerIsSetup = NO;
    if (_viewAppeared)
        [self _startPlayback];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.wantsFullScreenLayout = YES;

    self.videoFilterView.hidden = YES;
    _videoFiltersHidden = YES;
    _hueLabel.text = NSLocalizedString(@"VFILTER_HUE", @"");
    _hueSlider.accessibilityLabel = _hueLabel.text;
    _hueSlider.isAccessibilityElement = YES;
    _contrastLabel.text = NSLocalizedString(@"VFILTER_CONTRAST", @"");
    _contrastSlider.accessibilityLabel = _contrastLabel.text;
    _contrastSlider.isAccessibilityElement = YES;
    _brightnessLabel.text = NSLocalizedString(@"VFILTER_BRIGHTNESS", @"");
    _brightnessSlider.accessibilityLabel = _brightnessLabel.text;
    _brightnessSlider.isAccessibilityElement = YES;
    _saturationLabel.text = NSLocalizedString(@"VFILTER_SATURATION", @"");
    _saturationSlider.accessibilityLabel = _saturationLabel.text;
    _saturationSlider.isAccessibilityElement = YES;
    _gammaLabel.text = NSLocalizedString(@"VFILTER_GAMMA", @"");
    _gammaSlider.accessibilityLabel = _gammaLabel.text;
    _gammaSlider.isAccessibilityElement = YES;
    _playbackSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SPEED", @"");
    _playbackSpeedSlider.accessibilityLabel = _playbackSpeedLabel.text;
    _playbackSpeedSlider.isAccessibilityElement = YES;

    _positionSlider.accessibilityLabel = NSLocalizedString(@"PLAYBACK_POSITION", @"");
    _positionSlider.isAccessibilityElement = YES;
    _timeDisplay.isAccessibilityElement = YES;

    _audioSwitcherButton.accessibilityLabel = NSLocalizedString(@"CHOOSE_AUDIO_TRACK", @"");
    _audioSwitcherButton.isAccessibilityElement = YES;
    _audioSwitcherButtonLandscape.accessibilityLabel = NSLocalizedString(@"CHOOSE_AUDIO_TRACK", @"");
    _audioSwitcherButtonLandscape.isAccessibilityElement = YES;
    _subtitleSwitcherButton.accessibilityLabel = NSLocalizedString(@"CHOOSE_SUBTITLE_TRACK", @"");
    _subtitleSwitcherButton.isAccessibilityElement = YES;
    _subtitleSwitcherButtonLandscape.accessibilityLabel = NSLocalizedString(@"CHOOSE_SUBTITLE_TRACK", @"");
    _subtitleSwitcherButtonLandscape.isAccessibilityElement = YES;
    _playbackSpeedButton.accessibilityLabel = _playbackSpeedLabel.text;
    _playbackSpeedButton.isAccessibilityElement = YES;
    _playbackSpeedButtonLandscape.accessibilityLabel = _playbackSpeedLabel.text;
    _playbackSpeedButtonLandscape.isAccessibilityElement = YES;
    _videoFilterButton.accessibilityLabel = NSLocalizedString(@"VIDEO_FILTER", @"");
    _videoFilterButton.isAccessibilityElement = YES;
    _videoFilterButtonLandscape.accessibilityLabel = NSLocalizedString(@"VIDEO_FILTER", @"");
    _videoFilterButtonLandscape.isAccessibilityElement = YES;
    _resetVideoFilterButton.accessibilityLabel = NSLocalizedString(@"VIDEO_FILTER_RESET_BUTTON", @"");
    _resetVideoFilterButton.isAccessibilityElement = YES;
    _aspectRatioButton.accessibilityLabel = NSLocalizedString(@"VIDEO_ASPECT_RATIO_BUTTON", @"");
    _aspectRatioButton.isAccessibilityElement = YES;
    _playPauseButton.accessibilityLabel = NSLocalizedString(@"PLAY_PAUSE_BUTTON", @"");
    _playPauseButton.isAccessibilityElement = YES;
    _playPauseButtonLandscape.accessibilityLabel = NSLocalizedString(@"PLAY_PAUSE_BUTTON", @"");
    _playPauseButtonLandscape.isAccessibilityElement = YES;
    _bwdButton.accessibilityLabel = NSLocalizedString(@"BWD_BUTTON", @"");
    _bwdButton.isAccessibilityElement = YES;
    _bwdButtonLandscape.accessibilityLabel = NSLocalizedString(@"BWD_BUTTON", @"");
    _bwdButtonLandscape.isAccessibilityElement = YES;
    _fwdButton.accessibilityLabel = NSLocalizedString(@"FWD_BUTTON", @"");
    _fwdButton.isAccessibilityElement = YES;
    _fwdButtonLandscape.accessibilityLabel = NSLocalizedString(@"FWD_BUTTON", @"");
    _fwdButtonLandscape.isAccessibilityElement = YES;
    _repeatButton.accessibilityLabel = NSLocalizedString(@"BUTTON_REPEAT", @"");
    _repeatButton.isAccessibilityElement = YES;

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

    self.trackNameLabel.text = self.artistNameLabel.text = self.albumNameLabel.text = @"";

    _movieView.userInteractionEnabled = NO;
    _tapOnVideoRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControlsVisible)];
    _tapOnVideoRecognizer.delegate = self;
    [self.view addGestureRecognizer:_tapOnVideoRecognizer];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _displayRemainingTime = [[defaults objectForKey:kVLCShowRemainingTime] boolValue];
    _swipeGesturesEnabled = [[defaults objectForKey:kVLCSettingPlaybackGestures] boolValue];

    if (_swipeGesturesEnabled) {
        _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
        _pinchRecognizer.delegate = self;
        [self.view addGestureRecognizer:_pinchRecognizer];

        _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized)];
        [_tapRecognizer setNumberOfTouchesRequired:2];
        _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panRecognized:)];
        [_panRecognizer setMinimumNumberOfTouches:1];
        [_panRecognizer setMaximumNumberOfTouches:1];

        _swipeRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
        _swipeRecognizerLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        _swipeRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
        _swipeRecognizerRight.direction = UISwipeGestureRecognizerDirectionRight;

        [self.view addGestureRecognizer:_swipeRecognizerLeft];
        [self.view addGestureRecognizer:_swipeRecognizerRight];
        [self.view addGestureRecognizer:_panRecognizer];
        [self.view addGestureRecognizer:_tapRecognizer];
        [_panRecognizer requireGestureRecognizerToFail:_swipeRecognizerLeft];
        [_panRecognizer requireGestureRecognizerToFail:_swipeRecognizerRight];

        _panRecognizer.delegate = self;
        _swipeRecognizerRight.delegate = self;
        _swipeRecognizerLeft.delegate = self;
        _tapRecognizer.delegate = self;
    }

    _aspectRatios = @[@"DEFAULT", @"FILL_TO_SCREEN", @"4:3", @"16:9", @"16:10", @"2.21:1"];

    [self.aspectRatioButton setImage:[UIImage imageNamed:@"ratioIcon"] forState:UIControlStateNormal];
    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        self.backButton.tintColor = [UIColor colorWithRed:(190.0f/255.0f) green:(190.0f/255.0f) blue:(190.0f/255.0f) alpha:1.];
        self.toolbar.tintColor = [UIColor whiteColor];
        self.toolbar.barStyle = UIBarStyleBlack;

        CGRect rect = self.resetVideoFilterButton.frame;
        rect.origin.y = rect.origin.y + 5.;
        self.resetVideoFilterButton.frame = rect;
        rect = self.toolbar.frame;
        rect.size.height = rect.size.height + rect.origin.y;
        rect.origin.y = 0;
        self.toolbar.frame = rect;
        rect = self.aspectRatioButton.frame;
        rect.size.width -= 19.;
        rect.origin.x += 19.;
        self.aspectRatioButton.frame = rect;
        rect = self.timeDisplay.frame;
        rect.origin.x += 19.;
        self.timeDisplay.frame = rect;
        rect = self.positionSlider.frame;
        rect.size.width += 19.;
        self.positionSlider.frame = rect;
    } else {
        CGRect rect = self.positionSlider.frame;
        rect.origin.y = rect.origin.y + 3.;
        self.positionSlider.frame = rect;
        [self.aspectRatioButton setBackgroundImage:[UIImage imageNamed:@"ratioButton"] forState:UIControlStateNormal];
        [self.aspectRatioButton setBackgroundImage:[UIImage imageNamed:@"ratioButtonHighlight"] forState:UIControlStateHighlighted];
        [self.toolbar setBackgroundImage:[UIImage imageNamed:@"seekbarBg"] forBarMetrics:UIBarMetricsDefault];
        [self.backButton setBackgroundImage:[UIImage imageNamed:@"playbackDoneButton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self.backButton setBackgroundImage:[UIImage imageNamed:@"playbackDoneButtonHighlight"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    }

    /* FIXME: there is a saner iOS 6+ API for this! */
    /* this looks a bit weird, but we need to support iOS 5 and should show the same appearance */
    void (^initVolumeSlider)(MPVolumeView *) = ^(MPVolumeView *volumeView){
        UISlider *volumeSlider = nil;
        for (id aView in volumeView.subviews){
            if ([[[aView class] description] isEqualToString:@"MPVolumeSlider"]){
                volumeSlider = (UISlider *)aView;
                break;
            }
        }
        if (!SYSTEM_RUNS_IOS7_OR_LATER) {
            [volumeSlider setMinimumTrackImage:[[UIImage imageNamed:@"sliderminiValue"]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 0)] forState:UIControlStateNormal];
            [volumeSlider setMaximumTrackImage:[[UIImage imageNamed:@"slidermaxValue"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 4)] forState:UIControlStateNormal];
            [volumeSlider setThumbImage:[UIImage imageNamed:@"volumeballslider"] forState:UIControlStateNormal];
        } else
            [volumeView setVolumeThumbImage:[UIImage imageNamed:@"modernSliderKnob"] forState:UIControlStateNormal];
        [volumeSlider addTarget:self
                         action:@selector(volumeSliderAction:)
               forControlEvents:UIControlEventValueChanged];
    };

    initVolumeSlider(self.volumeView);
    initVolumeSlider(self.volumeViewLandscape);

    [[AVAudioSession sharedInstance] setDelegate:self];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self.positionSlider.scrubbingSpeedChangePositions = @[@(0.), @(100.), @(200.), @(300)];

    _playerIsSetup = NO;

    [self.movieView setAccessibilityLabel:NSLocalizedString(@"VO_VIDEOPLAYER_TITLE", @"")];
    [self.movieView setAccessibilityHint:NSLocalizedString(@"VO_VIDEOPLAYER_DOUBLETAP", @"")];
}

- (BOOL)_blobCheck
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = searchPaths[0];

    if (![[NSFileManager defaultManager] fileExistsAtPath:[directoryPath stringByAppendingPathComponent:@"blob.bin"]])
        return NO;

    NSData *data = [NSData dataWithContentsOfFile:[directoryPath stringByAppendingPathComponent:@"blob.bin"]];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);

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
    [super viewWillAppear:animated];

    _swipeGesturesEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingPlaybackGestures] boolValue];

    [self.navigationController setNavigationBarHidden:YES animated:YES];

    if (!SYSTEM_RUNS_IOS7_OR_LATER) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    }

    [self _startPlayback];

    [self setControlsHidden:NO animated:YES];
    _viewAppeared = YES;
}

- (void)viewWillLayoutSubviews
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        CGSize viewSize = self.view.frame.size;
        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
            [_controllerPanel removeFromSuperview];
            _controllerPanelLandscape.frame = (CGRect){CGPointMake(0, viewSize.height - _controllerPanelLandscape.frame.size.height), CGSizeMake(viewSize.width, _controllerPanelLandscape.frame.size.height)};
            [self.view addSubview:_controllerPanelLandscape];
        } else {
            [_controllerPanelLandscape removeFromSuperview];
            _controllerPanel.frame = (CGRect){CGPointMake(0, viewSize.height - _controllerPanel.frame.size.height), CGSizeMake(viewSize.width, _controllerPanel.frame.size.height)};
            [self.view addSubview:_controllerPanel];
        }
    }
}

- (void)_startPlayback
{
    if (_playerIsSetup)
        return;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (!self.mediaItem && !self.url && !self.mediaList) {
        [self _stopPlayback];
        return;
    }

    _listPlayer = [[VLCMediaListPlayer alloc]
                   initWithOptions:@[[NSString stringWithFormat:@"--%@=%@", kVLCSettingSubtitlesFont, [self _resolveFontName]], [NSString stringWithFormat:@"--%@=%@", kVLCSettingSubtitlesFontColor, [defaults objectForKey:kVLCSettingSubtitlesFontColor]], [NSString stringWithFormat:@"--%@=%@", kVLCSettingSubtitlesFontSize, [defaults objectForKey:kVLCSettingSubtitlesFontSize]], [NSString stringWithFormat:@"--%@=%@", kVLCSettingDeinterlace, [defaults objectForKey:kVLCSettingDeinterlace]], [NSString stringWithFormat:@"--%@=%@", kVLCSettingNetworkCaching, [defaults objectForKey:kVLCSettingNetworkCaching]]]];
    _mediaPlayer = _listPlayer.mediaPlayer;
    [_mediaPlayer setDelegate:self];
    [_mediaPlayer setDrawable:self.movieView];
    self.trackNameLabel.text = self.artistNameLabel.text = self.albumNameLabel.text = @"";

    VLCMedia *media;
    if (self.mediaItem) {
        MLFile *item = self.mediaItem;
        media = [VLCMedia mediaWithURL:[NSURL URLWithString:item.url]];
        item.unread = @(NO);
    } else if (!self.mediaList) {
        media = [VLCMedia mediaWithURL:self.url];
        [media parse];
    }

    NSMutableDictionary *mediaDictionary = [[NSMutableDictionary alloc] init];

    [mediaDictionary setObject:[[defaults objectForKey:kVLCSettingStretchAudio] boolValue] ? kVLCSettingStretchAudioOnValue : kVLCSettingStretchAudioOffValue forKey:kVLCSettingStretchAudio];
    [mediaDictionary setObject:[defaults objectForKey:kVLCSettingTextEncoding] forKey:kVLCSettingTextEncoding];
    [mediaDictionary setObject:[defaults objectForKey:kVLCSettingSkipLoopFilter] forKey:kVLCSettingSkipLoopFilter];

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
                    case 862151013:
                    case 1684566644:
                    case 2126701:
                    {
                        if (![self _blobCheck]) {
                            [mediaDictionary setObject:[NSNull null] forKey:@"no-audio"];
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

    if (self.mediaList) {
        VLCMediaList *list = self.mediaList;
        NSUInteger count = list.count;
        for (NSUInteger x = 0; x < count; x++)
            [[list mediaAtIndex:x] addOptions:mediaDictionary];
        [_listPlayer setMediaList:self.mediaList];
    } else {
        [media addOptions:mediaDictionary];
        [_listPlayer setRootMedia:media];
    }
    [_listPlayer setRepeatMode:VLCDoNotRepeat];

    self.positionSlider.value = 0.;
    [self.timeDisplay setTitle:@"" forState:UIControlStateNormal];
    self.timeDisplay.accessibilityLabel = @"";
    [self.repeatButton setImage:[UIImage imageNamed:@"repeat"] forState:UIControlStateNormal];
    [self.repeatButtonLandscape setImage:[UIImage imageNamed:@"repeat"] forState:UIControlStateNormal];

    if (![self _isMediaSuitableForDevice]) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DEVICE_TOOSLOW_TITLE", @"") message:[NSString stringWithFormat:NSLocalizedString(@"DEVICE_TOOSLOW", @""), [[UIDevice currentDevice] model], self.mediaItem.title] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:NSLocalizedString(@"BUTTON_OPEN", @""), nil];
        [alert show];
    } else
        [self _playNewMedia];

    if (![self hasExternalDisplay])
        self.brightnessSlider.value = [UIScreen mainScreen].brightness * 2.;
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
    else {
        [self _stopPlayback];
        [self closePlayback:nil];
    }
}

- (void)_playNewMedia
{
    NSNumber *playbackPositionInTime = @(0);
    CGFloat lastPosition = .0;
    NSInteger duration = self.mediaItem.duration.intValue;

    if (self.mediaItem.lastPosition)
        lastPosition = self.mediaItem.lastPosition.floatValue;
    if (lastPosition < .95) {
        if (duration != 0)
            playbackPositionInTime = @(lastPosition * (duration / 1000.));
    }
    if (playbackPositionInTime.intValue > 0 && (duration * lastPosition - duration) < -60000) {
        /* start time is not supported for media lists */
        [_mediaPlayer.media addOptions:@{@"start-time": playbackPositionInTime}];
        APLog(@"set starttime to %i", playbackPositionInTime.intValue);
    }

    [_mediaPlayer addObserver:self forKeyPath:@"time" options:0 context:nil];
    [_mediaPlayer addObserver:self forKeyPath:@"remainingTime" options:0 context:nil];

    if (self.mediaList)
        [_listPlayer playItemAtIndex:self.itemInMediaListToBePlayedFirst];
    else
        [_listPlayer playMedia:_listPlayer.rootMedia];

    if (self.mediaItem) {
        if (self.mediaItem.lastAudioTrack.intValue > 0)
            _mediaPlayer.currentAudioTrackIndex = self.mediaItem.lastAudioTrack.intValue;
        if (self.mediaItem.lastSubtitleTrack.intValue > 0)
            _mediaPlayer.currentVideoSubTitleIndex = self.mediaItem.lastSubtitleTrack.intValue;
    }

    self.playbackSpeedSlider.value = [self _playbackSpeed];
    [self _updatePlaybackSpeedIndicator];

    _currentAspectRatioMask = 0;
    _mediaPlayer.videoAspectRatio = NULL;

    /* some demuxers don't respect :start-time, so re-try here */
    if (lastPosition < .95 && _mediaPlayer.position < lastPosition && (duration * lastPosition - duration) < -60000)
        _mediaPlayer.position = lastPosition;

    [self _resetIdleTimer];
    _playerIsSetup = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self _stopPlayback];
    _viewAppeared = NO;
    if (_idleTimer) {
        [_idleTimer invalidate];
        _idleTimer = nil;
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if (!SYSTEM_RUNS_IOS7_OR_LATER)
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [super viewWillDisappear:animated];

    // hide filter UI for next run
    if (!_videoFiltersHidden)
        _videoFiltersHidden = YES;

    if (!_playbackSpeedViewHidden)
        _playbackSpeedViewHidden = YES;
}

- (void)_stopPlayback
{
    if (_mediaPlayer) {
        @try {
            [_mediaPlayer removeObserver:self forKeyPath:@"time"];
            [_mediaPlayer removeObserver:self forKeyPath:@"remainingTime"];
        }
        @catch (NSException *exception) {
            APLog(@"we weren't an observer yet");
        }

        if (_mediaPlayer.media) {
            [_mediaPlayer pause];
            [self _saveCurrentState];
            [_mediaPlayer stop];
        }
        if (_mediaPlayer)
            _mediaPlayer = nil;
        if (_listPlayer)
            _listPlayer = nil;
    }
    if (_mediaItem)
        _mediaItem = nil;
    if (_mediaList)
        _mediaList = nil;
    if (_url)
        _url = nil;

    _playerIsSetup = NO;
}

- (void)_saveCurrentState
{
    if (self.mediaItem) {
        @try {
            MLFile *item = self.mediaItem;
            item.lastPosition = @([_mediaPlayer position]);
            item.lastAudioTrack = @(_mediaPlayer.currentAudioTrackIndex);
            item.lastSubtitleTrack = @(_mediaPlayer.currentVideoSubTitleIndex);
        }
        @catch (NSException *exception) {
            APLog(@"failed to save current media state - file removed?");
        }
    }
}

- (NSString *)_resolveFontName
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL bold = [[defaults objectForKey:kVLCSettingSubtitlesBoldFont] boolValue];
    NSString *font = [defaults objectForKey:kVLCSettingSubtitlesFont];
    NSDictionary *fontMap = @{
                              @"AmericanTypewriter":   @"AmericanTypewriter-Bold",
                              @"ArialMT":              @"Arial-BoldMT",
                              @"ArialHebrew":          @"ArialHebrew-Bold",
                              @"ChalkboardSE-Regular": @"ChalkboardSE-Bold",
                              @"CourierNewPSMT":       @"CourierNewPS-BoldMT",
                              @"Georgia":              @"Georgia-Bold",
                              @"GillSans":             @"GillSans-Bold",
                              @"GujaratiSangamMN":     @"GujaratiSangamMN-Bold",
                              @"STHeitiSC-Light":      @"STHeitiSC-Medium",
                              @"STHeitiTC-Light":      @"STHeitiTC-Medium",
                              @"HelveticaNeue":        @"HelveticaNeue-Bold",
                              @"HiraKakuProN-W3":      @"HiraKakuProN-W6",
                              @"HiraMinProN-W3":       @"HiraMinProN-W6",
                              @"HoeflerText-Regular":  @"HoeflerText-Black",
                              @"Kailasa":              @"Kailasa-Bold",
                              @"KannadaSangamMN":      @"KannadaSangamMN-Bold",
                              @"MalayalamSangamMN":    @"MalayalamSangamMN-Bold",
                              @"OriyaSangamMN":        @"OriyaSangamMN-Bold",
                              @"SinhalaSangamMN":      @"SinhalaSangamMN-Bold",
                              @"SnellRoundhand":       @"SnellRoundhand-Bold",
                              @"TamilSangamMN":        @"TamilSangamMN-Bold",
                              @"TeluguSangamMN":       @"TeluguSangamMN-Bold",
                              @"TimesNewRomanPSMT":    @"TimesNewRomanPS-BoldMT",
                              @"Zapfino":              @"Zapfino"
                              };

    if (!bold) {
        return font;
    } else {
        return fontMap[font];
    }
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
            [_listPlayer play];
            break;

        case UIEventSubtypeRemoteControlPause:
            [_listPlayer pause];
            break;

        case UIEventSubtypeRemoteControlTogglePlayPause:
            [self playPause];
            break;

        case UIEventSubtypeRemoteControlNextTrack:
            [self forward:nil];

        case UIEventSubtypeRemoteControlPreviousTrack:
            [self backward:nil];

        case UIEventSubtypeRemoteControlStop:
            [self closePlayback:nil];

        default:
            break;
    }
}

#pragma mark - controls visibility

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    if (!_swipeGesturesEnabled)
        return;

    if (recognizer.velocity < 0.)
        [self closePlayback:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (!_swipeGesturesEnabled)
        return NO;

    if (touch.view != self.view)
        return NO;

    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (!_swipeGesturesEnabled)
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
        _controllerPanelLandscape.alpha = 0.0f;
        _controllerPanelLandscape.hidden = !_videoFiltersHidden;
        _toolbar.alpha = 0.0f;
        _toolbar.hidden = NO;
        _videoFilterView.alpha = 0.0f;
        _videoFilterView.hidden = _videoFiltersHidden;
        _playbackSpeedView.alpha = 0.0f;
        _playbackSpeedView.hidden = _playbackSpeedViewHidden;
    }

    void (^animationBlock)() = ^() {
        _controllerPanel.alpha = alpha;
        _controllerPanelLandscape.alpha = alpha;
        _toolbar.alpha = alpha;
        _videoFilterView.alpha = alpha;
        _playbackSpeedView.alpha = alpha;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        _controllerPanel.hidden = _videoFiltersHidden ? _controlsHidden : NO;
        _controllerPanelLandscape.hidden = _videoFiltersHidden ? _controlsHidden : NO;
        _toolbar.hidden = _controlsHidden;
        _videoFilterView.hidden = _videoFiltersHidden;
        _playbackSpeedView.hidden = _playbackSpeedViewHidden;
    };

    UIStatusBarAnimation animationType = animated? UIStatusBarAnimationFade: UIStatusBarAnimationNone;
    NSTimeInterval animationDuration = animated? 0.3: 0.0;

    [[UIApplication sharedApplication] setStatusBarHidden:_viewAppeared ? _controlsHidden : NO withAnimation:animationType];
    [UIView animateWithDuration:animationDuration animations:animationBlock completion:completionBlock];

    _volumeView.hidden = _volumeViewLandscape.hidden = _controllerPanel.hidden;
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
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)positionSliderAction:(UISlider *)sender
{
    /* we need to limit the number of events sent by the slider, since otherwise, the user
     * wouldn't see the I-frames when seeking on current mobile devices. This isn't a problem
     * within the Simulator, but especially on older ARMv7 devices, it's clearly noticeable. */
    [self performSelector:@selector(_setPositionForReal) withObject:nil afterDelay:0.3];
    VLCTime *newPosition = [VLCTime timeWithInt:(int)(_positionSlider.value * self.mediaItem.duration.intValue)];
    [self.timeDisplay setTitle:newPosition.stringValue forState:UIControlStateNormal];
    self.timeDisplay.accessibilityLabel = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"PLAYBACK_POSITION", @""), newPosition.stringValue];
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
    _isScrubbing = YES;
}

- (IBAction)positionSliderTouchUp:(id)sender
{
    self.scrubIndicatorView.hidden = YES;
    _isScrubbing = NO;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (!_isScrubbing) {
        self.positionSlider.value = [_mediaPlayer position];
    }

    if (_displayRemainingTime)
        [self.timeDisplay setTitle:[[_mediaPlayer remainingTime] stringValue] forState:UIControlStateNormal];
    else
        [self.timeDisplay setTitle:[[_mediaPlayer time] stringValue] forState:UIControlStateNormal];
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    VLCMediaPlayerState currentState = _mediaPlayer.state;
    if (currentState == VLCMediaPlayerStateBuffering) {
        /* attach delegate */
        _mediaPlayer.media.delegate = self;
        /* let's update meta data */
        [self _updateDisplayedMetadata];
    }

    if (currentState == VLCMediaPlayerStateError) {
        [self.statusLabel showStatusMessage:NSLocalizedString(@"PLAYBACK_FAILED", @"")];
        [self performSelector:@selector(closePlayback:) withObject:nil afterDelay:2.];
    }

    if ((currentState == VLCMediaPlayerStateEnded || currentState == VLCMediaPlayerStateStopped) && _listPlayer.repeatMode == VLCDoNotRepeat) {
        if ([_listPlayer.mediaList indexOfMedia:_mediaPlayer.media] == _listPlayer.mediaList.count - 1)[self performSelector:@selector(closePlayback:) withObject:nil afterDelay:2.];
    }

    UIImage *playPauseImage = [_mediaPlayer isPlaying]? [UIImage imageNamed:@"pauseIcon"] : [UIImage imageNamed:@"playIcon"];
    [_playPauseButton setImage:playPauseImage forState:UIControlStateNormal];
    [_playPauseButtonLandscape setImage:playPauseImage forState:UIControlStateNormal];

    if ([[_mediaPlayer audioTrackIndexes] count] > 2) {
        self.audioSwitcherButton.hidden = NO;
        self.audioSwitcherButtonLandscape.hidden = NO;
    } else {
        self.audioSwitcherButton.hidden = YES;
        self.audioSwitcherButtonLandscape.hidden = YES;
    }

    if ([[_mediaPlayer videoSubTitlesIndexes] count] > 1) {
        self.subtitleContainer.hidden = NO;
        self.subtitleContainerLandscape.hidden = NO;
    } else {
        self.subtitleContainer.hidden = YES;
        self.subtitleContainerLandscape.hidden = YES;
    }
}

- (IBAction)playPause
{
    if ([_mediaPlayer isPlaying])
        [_listPlayer pause];
    else
        [_listPlayer play];
}

- (IBAction)forward:(id)sender
{
    if (self.mediaList)
        [_listPlayer next];
    else
        [_mediaPlayer mediumJumpForward];
}

- (IBAction)backward:(id)sender
{
    if (self.mediaList)
        [_listPlayer previous];
    else
        [_mediaPlayer mediumJumpBackward];
}

- (void)toggleRepeatMode:(id)sender
{
    if (_listPlayer.repeatMode == VLCDoNotRepeat) {
        _listPlayer.repeatMode = VLCRepeatCurrentItem;
        [self.repeatButton setImage:[UIImage imageNamed:@"repeatOne"] forState:UIControlStateNormal];
        [self.repeatButtonLandscape setImage:[UIImage imageNamed:@"repeatOne"] forState:UIControlStateNormal];
    } else {
        _listPlayer.repeatMode = VLCDoNotRepeat;
        [self.repeatButton setImage:[UIImage imageNamed:@"repeat"] forState:UIControlStateNormal];
        [self.repeatButtonLandscape setImage:[UIImage imageNamed:@"repeat"] forState:UIControlStateNormal];
    }
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
    [_audiotrackActionSheet showInView:(UIButton *)sender];
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
    [_subtitleActionSheet showInView:(UIButton *)sender];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
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

#pragma mark - multi-touch gestures

- (void)tapRecognized
{
    if ([_mediaPlayer isPlaying]) {
        [_listPlayer pause];
        [self.statusLabel showStatusMessage:@"  ▌▌"];
    } else {
        [_listPlayer play];
        [self.statusLabel showStatusMessage:@" ►"];
    }
}

- (NSString*)detectPanTypeForPan:(UIPanGestureRecognizer*)panRecognizer
{
    NSString * type;
    NSString * deviceType = [[UIDevice currentDevice] model];
    type = @"Volume"; // default in case of error
    CGPoint location = [panRecognizer locationInView:self.view];
    CGFloat position = location.x;

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = .0;
    if (orientation == UIDeviceOrientationPortrait)
        screenWidth = screenRect.size.width;
    else
        screenWidth = screenRect.size.height;

    if (position < screenWidth / 2)
        type = @"Brightness";
    if (position > screenWidth / 2)
        type = @"Volume";

    // only check for seeking gesture if on iPad , will overwrite last statements if true
    if ([deviceType isEqualToString:@"iPad"]) {
        if (location.y < 110)
            type = @"Seek";
    }

    return type;
}

- (void)panRecognized:(UIPanGestureRecognizer*)panRecognizer
{
    CGFloat panDirectionX = [panRecognizer velocityInView:self.view].x;
    CGFloat panDirectionY = [panRecognizer velocityInView:self.view].y;

    if (panRecognizer.state == UIGestureRecognizerStateBegan) // Only Detect pantype when began to allow more freedom
        panType = [self detectPanTypeForPan:panRecognizer];

    if ([panType isEqual:@"Seek"]) {
        double timeRemainingDouble = (-_mediaPlayer.remainingTime.intValue*0.001);
        int timeRemaining = timeRemainingDouble;

        if (panDirectionX > 0) {
            if (timeRemaining > 2 ) // to not go outside duration , video will stop
                [_mediaPlayer jumpForward:1];
        } else
            [_mediaPlayer jumpBackward:1];
    } else if ([panType isEqual:@"Volume"]) {
        MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
        if (panDirectionY > 0)
            musicPlayer.volume -= 0.01;
        else
            musicPlayer.volume += 0.01;
    } else if ([panType isEqual:@"Brightness"]) {
        CGFloat brightness = [UIScreen mainScreen].brightness;

        if (panDirectionY > 0)
            brightness = brightness - 0.01;
        else
            brightness = brightness + 0.01;

        [[UIScreen mainScreen] setBrightness:brightness];
        self.brightnessSlider.value = brightness * 2.;

        NSString *brightnessHUD = [NSString stringWithFormat:@"%@: %@ %%", NSLocalizedString(@"VFILTER_BRIGHTNESS", @""), [[[NSString stringWithFormat:@"%f",(brightness*100)] componentsSeparatedByString:@"."] objectAtIndex:0]];
        [self.statusLabel showStatusMessage:brightnessHUD];
    }

    if (panRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([_mediaPlayer isPlaying])
            [_listPlayer play];
    }
}

- (void)swipeRecognized:(UISwipeGestureRecognizer*)swipeRecognizer
{
    NSString * hudString = @" ";

    if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        double timeRemainingDouble = (-_mediaPlayer.remainingTime.intValue*0.001);
        int timeRemaining = timeRemainingDouble;

        if (FORWARD_SWIPE_DURATION < timeRemaining) {
            [_mediaPlayer jumpForward:FORWARD_SWIPE_DURATION];
            hudString = [NSString stringWithFormat:@"⇒ %is", FORWARD_SWIPE_DURATION];
        } else {
            [_mediaPlayer jumpForward:(timeRemaining - 5)];
            hudString = [NSString stringWithFormat:@"⇒ %is",(timeRemaining - 5)];
        }
    }
    else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        [_mediaPlayer jumpBackward:BACKWARD_SWIPE_DURATION];
        hudString = [NSString stringWithFormat:@"⇐ %is",BACKWARD_SWIPE_DURATION];
    }

    if (swipeRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([_mediaPlayer isPlaying])
            [_listPlayer play];

        [self.statusLabel showStatusMessage:hudString];
    }
}

#pragma mark - Video Filter UI

- (IBAction)videoFilterToggle:(id)sender
{
    if (!_playbackSpeedViewHidden)
        self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (!_controlsHidden) {
            self.controllerPanel.hidden = _controlsHidden = YES;
            self.controllerPanelLandscape.hidden = YES;
        }
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

    /* rate changed, so update the exported info */
    [self performSelectorInBackground:@selector(_updateDisplayedMetadata) withObject:nil];
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
    if (sender == self.playbackSpeedButton || sender == self.playbackSpeedButtonLandscape) {
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
    [self _saveCurrentState];

    _mediaPlayer.currentVideoTrackIndex = 0;

    if (![[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingContinueAudioInBackgroundKey] boolValue]) {
        if ([_mediaPlayer isPlaying]) {
            [_mediaPlayer pause];
            _shouldResumePlaying = YES;
        }
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    _shouldResumePlaying = NO;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    _mediaPlayer.currentVideoTrackIndex = 1;

    if (_shouldResumePlaying) {
        _shouldResumePlaying = NO;
        [_listPlayer play];
    }
}

- (void)mediaDidFinishParsing:(VLCMedia *)aMedia
{
    [self _updateDisplayedMetadata];
}

- (void)mediaMetaDataDidChange:(VLCMedia*)aMedia
{
    [self _updateDisplayedMetadata];
}

- (void)_updateDisplayedMetadata
{
    MLFile *item = self.mediaItem;
    NSString *title;
    NSString *artist;
    NSString *albumName;
    NSString *trackNumber;

    if (item) {
        if (item.isAlbumTrack) {
            title = item.albumTrack.title;
            artist = item.albumTrack.artist;
            albumName = item.albumTrack.album.name;
        } else
            title = item.title;
        self.artworkImageView.image = [VLCThumbnailsCache thumbnailForMediaFile:item];
    } else {
        NSDictionary * metaDict = _mediaPlayer.media.metaDictionary;
        if (metaDict) {
            title = metaDict[VLCMetaInformationNowPlaying] ? metaDict[VLCMetaInformationNowPlaying] : metaDict[VLCMetaInformationTitle];
            artist = metaDict[VLCMetaInformationArtist];
            albumName = metaDict[VLCMetaInformationAlbum];
            trackNumber = metaDict[VLCMetaInformationTrackNumber];
            self.artworkImageView.image = [VLCThumbnailsCache thumbnailForMediaItemWithTitle:title Artist:artist andAlbumName:albumName];
        }
    }
    if (!self.artworkImageView.image) {
        self.trackNameLabel.text = title;
        self.artistNameLabel.text = artist;
        self.albumNameLabel.text = albumName;
    } else {
        NSString *trackName = title;
        if (artist)
            trackName = [trackName stringByAppendingFormat:@" — %@", artist];
        if (albumName)
            trackName = [trackName stringByAppendingFormat:@" — %@", albumName];
        self.trackNameLabel.text = trackName;
    }

    if (self.trackNameLabel.text.length < 1)
        self.trackNameLabel.text = [[_mediaPlayer.media url] lastPathComponent];

    /* don't leak sensitive information to the OS, if passcode lock is enabled */
    BOOL passcodeLockEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingPasscodeOnKey] boolValue];

    NSMutableDictionary *currentlyPlayingTrackInfo;
    if (passcodeLockEnabled)
        currentlyPlayingTrackInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:@(_mediaPlayer.media.length.intValue / 1000.), MPMediaItemPropertyPlaybackDuration, @(_mediaPlayer.time.intValue / 1000.), MPNowPlayingInfoPropertyElapsedPlaybackTime, @(_mediaPlayer.rate), MPNowPlayingInfoPropertyPlaybackRate, nil];
    else {
        currentlyPlayingTrackInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys: title, MPMediaItemPropertyTitle, @(_mediaPlayer.media.length.intValue / 1000.), MPMediaItemPropertyPlaybackDuration, @(_mediaPlayer.time.intValue / 1000.), MPNowPlayingInfoPropertyElapsedPlaybackTime, @(_mediaPlayer.rate), MPNowPlayingInfoPropertyPlaybackRate, nil];
        if (artist.length > 0)
            [currentlyPlayingTrackInfo setObject:artist forKey:MPMediaItemPropertyArtist];
        if (albumName.length > 0)
            [currentlyPlayingTrackInfo setObject:albumName forKey:MPMediaItemPropertyAlbumTitle];
        [currentlyPlayingTrackInfo setObject:[NSNumber numberWithInt:[trackNumber intValue]] forKey:MPMediaItemPropertyAlbumTrackNumber];
        if (self.artworkImageView.image) {
            MPMediaItemArtwork *mpartwork = [[MPMediaItemArtwork alloc] initWithImage:self.artworkImageView.image];
            [currentlyPlayingTrackInfo setObject:mpartwork forKey:MPMediaItemPropertyArtwork];
        }
    }

    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = currentlyPlayingTrackInfo;
}

#pragma mark - autorotation

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
           || toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (self.artworkImageView.image)
            self.trackNameLabel.hidden = UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
    }
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
