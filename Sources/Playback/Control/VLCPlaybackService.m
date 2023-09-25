/*****************************************************************************
 * VLCPlaybackService.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2023 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Carola Nitz <caro # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Sylver Bruneau <sylver.bruneau # gmail dot com>
 *          Winston Weinert <winston # ml1 dot net>
 *          Maxime Chapelet <umxprime # videolabs.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackService.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "VLCMetadata.h"
#import "VLCPlayerDisplayController.h"
#import <stdatomic.h>

#if TARGET_OS_IOS
#import "VLCMLMedia+Podcast.h"
#endif

#import "VLC-Swift.h"

NSString *const VLCPlaybackServicePlaybackDidStart = @"VLCPlaybackServicePlaybackDidStart";
NSString *const VLCPlaybackServicePlaybackDidPause = @"VLCPlaybackServicePlaybackDidPause";
NSString *const VLCPlaybackServicePlaybackDidResume = @"VLCPlaybackServicePlaybackDidResume";
NSString *const VLCPlaybackServicePlaybackDidStop = @"VLCPlaybackServicePlaybackDidStop";
NSString *const VLCPlaybackServicePlaybackMetadataDidChange = @"VLCPlaybackServicePlaybackMetadataDidChange";
NSString *const VLCPlaybackServicePlaybackDidFail = @"VLCPlaybackServicePlaybackDidFail";
NSString *const VLCPlaybackServicePlaybackPositionUpdated = @"VLCPlaybackServicePlaybackPositionUpdated";
NSString *const VLCPlaybackServicePlaybackModeUpdated = @"VLCPlaybackServicePlaybackModeUpdated";
NSString *const VLCPlaybackServicePlaybackDidMoveOnToNextItem = @"VLCPlaybackServicePlaybackDidMoveOnToNextItem";

#if TARGET_OS_IOS
@interface VLCPlaybackService () <VLCMediaPlayerDelegate, VLCMediaDelegate, VLCMediaListPlayerDelegate, EqualizerViewDelegate>
#else
@interface VLCPlaybackService () <VLCMediaPlayerDelegate, VLCMediaDelegate, VLCMediaListPlayerDelegate>
#endif
{
    VLCMediaPlayer *_backgroundDummyPlayer;
    VLCMediaPlayer *_mediaPlayer;
    VLCMediaListPlayer *_listPlayer;
    BOOL _shouldResumePlaying;
    BOOL _sessionWillRestart;

    NSString *_pathToExternalSubtitlesFile;
    int _itemInMediaListToBePlayedFirst;
    NSTimer *_sleepTimer;

    BOOL _isInFillToScreen;
    NSUInteger _previousAspectRatio;

    UIView *_videoOutputViewWrapper;
    UIView *_actualVideoOutputView;
    UIView *_preBackgroundWrapperView;

    int _majorPositionChangeInProgress;
    BOOL _externalAudioPlaybackDeviceConnected;

    NSLock *_playbackSessionManagementLock;

    void (^_playbackCompletion)(BOOL success);

    VLCDialogProvider *_dialogProvider;
    VLCCustomDialogRendererHandler *_customDialogHandler;
    VLCPlayerDisplayController *_playerDisplayController;

    NSMutableArray *_openedLocalURLs;

    NSInteger _currentIndex;
    NSMutableArray *_shuffledOrder;
}

@end

@implementation VLCPlaybackService

#pragma mark instance management

+ (VLCPlaybackService *)sharedInstance
{
    static VLCPlaybackService *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [VLCPlaybackService new];
    });

    return sharedInstance;
}

- (void)dealloc
{
    _dialogProvider = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fullscreenSessionRequested = YES;
        // listen to audiosessions and appkit callback
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self selector:@selector(audioSessionRouteChange:)
                              name:AVAudioSessionRouteChangeNotification object:nil];

        [defaultCenter addObserver:self selector:@selector(handleInterruption:)
                              name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];

        // appkit because we neeed to know when we go to background in order to stop the video, so that we don't crash
        [defaultCenter addObserver:self selector:@selector(applicationWillResignActive:)
                              name:UIApplicationWillResignActiveNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground:)
                              name:UIApplicationDidEnterBackgroundNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(applicationWillEnterForeground:)
                              name:UIApplicationWillEnterForegroundNotification object:nil];

        _metadata = [VLCMetaData new];
        _dialogProvider = [[VLCDialogProvider alloc] initWithLibrary:[VLCLibrary sharedLibrary] customUI:YES];

        _customDialogHandler = [[VLCCustomDialogRendererHandler alloc]
                                initWithDialogProvider:_dialogProvider];

        _dialogProvider.customRenderer = _customDialogHandler;

        _playbackSessionManagementLock = [[NSLock alloc] init];
        _shuffleMode = NO;

        // Initialize a separate media player in order to play silence so that the application can
        // stay alive in background exclusively for Chromecast.
        _backgroundDummyPlayer = [[VLCMediaPlayer alloc] initWithOptions:@[@"--demux=rawaud"]];
        _backgroundDummyPlayer.media = [[VLCMedia alloc] initWithPath:@"/dev/zero"];

        _mediaList = [[VLCMediaList alloc] init];

        _openedLocalURLs = [[NSMutableArray alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_externalAudioPlaybackDeviceConnected = [self isExternalAudioPlaybackDeviceConnected];
        });
    }
    return self;
}

#pragma mark - playback management

- (void)addAudioToCurrentPlaybackFromURL:(NSURL *)audioURL
{
    [_mediaPlayer addPlaybackSlave:audioURL type:VLCMediaPlaybackSlaveTypeAudio enforce:YES];
}

- (void)addSubtitlesToCurrentPlaybackFromURL:(NSURL *)subtitleURL
{
    [_mediaPlayer addPlaybackSlave:subtitleURL type:VLCMediaPlaybackSlaveTypeSubtitle enforce:YES];
}

- (void)playMediaList:(VLCMediaList *)mediaList firstIndex:(NSInteger)index subtitlesFilePath:(NSString * _Nullable)subsFilePath
{
    [self playMediaList: mediaList firstIndex: index subtitlesFilePath: subsFilePath completion: nil];
}

- (void)playMediaList:(VLCMediaList *)mediaList firstIndex:(NSInteger)index subtitlesFilePath:(NSString * _Nullable)subsFilePath completion:(void (^ __nullable)(BOOL success))completion
{
    _playbackCompletion = completion;
    self.mediaList = mediaList;
    _itemInMediaListToBePlayedFirst = (int)index;
    _pathToExternalSubtitlesFile = subsFilePath;

    _sessionWillRestart = _playerIsSetup;
    _playerIsSetup ? [self stopPlayback] : [self startPlayback];

#if TARGET_OS_TV
    VLCFullscreenMovieTVViewController *movieVC = [VLCFullscreenMovieTVViewController fullscreenMovieTVViewController];

    if (![movieVC isBeingPresented]) {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:movieVC
                                                                                     animated:YES
                                                                                   completion:nil];
    }
#endif
}

- (VLCTime *)playedTime
{
    return [_mediaPlayer time];
}

- (void)startPlayback
{
    if (_playerIsSetup) {
        APLog(@"%s: player is already setup, bailing out", __PRETTY_FUNCTION__);
        return;
    }

    BOOL ret = [_playbackSessionManagementLock tryLock];
    if (!ret) {
        APLog(@"%s: locking failed", __PRETTY_FUNCTION__);
        return;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (!self.mediaList) {
        APLog(@"%s: no URL and no media list set, stopping playback", __PRETTY_FUNCTION__);
        [_playbackSessionManagementLock unlock];
        [self stopPlayback];
        return;
    }

    /* video decoding permanently fails if we don't provide a UIView to draw into on init
     * hence we provide one which is not attached to any view controller for off-screen drawing
     * and disable video decoding once playback started */
    _actualVideoOutputView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _actualVideoOutputView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _actualVideoOutputView.autoresizesSubviews = YES;

    /* the chromecast and audio options cannot be set per media, so we need to set it per
     * media player instance however, potentially initialising an additional library instance
     * for this is costly, so this should be done only if needed */
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL chromecastPassthrough = [[userDefaults objectForKey:kVLCSettingCastingAudioPassthrough] boolValue];
    int chromecastQuality = [[userDefaults objectForKey:kVLCSettingCastingConversionQuality] intValue];
    BOOL audioTimeStretch = [[userDefaults objectForKey:kVLCSettingStretchAudio] boolValue];
    NSMutableArray *libVLCOptions = [NSMutableArray array];
    if (chromecastPassthrough) {
        [libVLCOptions addObject:[@"--" stringByAppendingString:kVLCSettingCastingAudioPassthrough]];
    }
    if (chromecastQuality != 2) {
        [libVLCOptions addObject:[NSString stringWithFormat:@"--%@=%i", kVLCSettingCastingConversionQuality, chromecastQuality]];
    }
    if (!audioTimeStretch) {
        [libVLCOptions addObject:[NSString stringWithFormat:@"--no-%@", kVLCSettingStretchAudio]];
    }
    if (libVLCOptions.count > 0) {
        _listPlayer = [[VLCMediaListPlayer alloc] initWithOptions:libVLCOptions
                                                      andDrawable:_actualVideoOutputView];
    } else {
        _listPlayer = [[VLCMediaListPlayer alloc] initWithDrawable:_actualVideoOutputView];
    }
    _listPlayer.delegate = self;

    NSMutableArray *debugLoggers = [NSMutableArray array];
#if MEDIA_PLAYBACK_DEBUG
    VLCConsoleLogger *consoleLogger = [[VLCConsoleLogger alloc] init];
    consoleLogger.level = kVLCLogLevelDebug;
    [debugLoggers addObject:consoleLogger];
#endif
    BOOL saveDebugLogs = [userDefaults boolForKey:kVLCSaveDebugLogs];
    if (saveDebugLogs) {
        NSArray *searchPaths;
#if TARGET_OS_IOS
        searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
#else
        searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
#endif
        NSString* logFilePath = [searchPaths[0] stringByAppendingPathComponent:@"Logs"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        ret = [fileManager fileExistsAtPath:logFilePath];
        if (!ret) {
            [fileManager createDirectoryAtPath:logFilePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSDate *date = [NSDate date];
        NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd--HH-mm-ss"];
        logFilePath = [logFilePath stringByAppendingPathComponent:[NSString stringWithFormat: @"vlcdebug-%@.log", [dateFormatter stringFromDate:date]]];
        APLog(@"logging at '%@'", logFilePath);
        [fileManager createFileAtPath:logFilePath contents:nil attributes:nil];
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
        if (fileHandle) {
            VLCFileLogger *fileLogger = [[VLCFileLogger alloc] initWithFileHandle:fileHandle];
            fileLogger.level = kVLCLogLevelDebug;
            [debugLoggers addObject:fileLogger];
        }
    }
    [_listPlayer.mediaPlayer.libraryInstance setLoggers:debugLoggers];

    id<VLCFilter> newFilter = _listPlayer.mediaPlayer.adjustFilter;
    [newFilter applyParametersFrom:_adjustFilter.mediaPlayerAdjustFilter];
    newFilter.enabled = _adjustFilter.mediaPlayerAdjustFilter.isEnabled;
    _adjustFilter = [[VLCPlaybackServiceAdjustFilter alloc] initWithMediaPlayerAdjustFilter:newFilter];
    _mediaPlayer = _listPlayer.mediaPlayer;

    [_mediaPlayer setDelegate:self];
    CGFloat defaultPlaybackSpeed = [[defaults objectForKey:kVLCSettingPlaybackSpeedDefaultValue] floatValue];
    if (defaultPlaybackSpeed != 0.)
        [_mediaPlayer setRate: defaultPlaybackSpeed];
    int deinterlace = [[defaults objectForKey:kVLCSettingDeinterlace] intValue];
    [_mediaPlayer setDeinterlace:deinterlace withFilter:@"blend"];

    [_listPlayer setMediaList:self.mediaList];
#if TARGET_OS_IOS
    if ([defaults boolForKey:kVLCPlayerShouldRememberState]) {
        VLCRepeatMode repeatMode = [defaults integerForKey:kVLCPlayerIsRepeatEnabled];
        [_listPlayer setRepeatMode:repeatMode];
    }
#endif

    [_playbackSessionManagementLock unlock];

    [self _playNewMedia];
}

- (void)_playNewMedia
{
    BOOL ret = [_playbackSessionManagementLock tryLock];
    if (!ret) {
        APLog(@"%s: locking failed", __PRETTY_FUNCTION__);
        return;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    BOOL equalizerEnabled = ![userDefaults boolForKey:kVLCSettingEqualizerProfileDisabled];

    if (equalizerEnabled) {
        NSArray *presets = [VLCAudioEqualizer presets];
        unsigned int profile = (unsigned int)[userDefaults integerForKey:kVLCSettingEqualizerProfile];
        VLCAudioEqualizer *equalizer = [[VLCAudioEqualizer alloc] initWithPreset:presets[profile]];
        equalizer.preAmplification = [userDefaults floatForKey:kVLCSettingDefaultPreampLevel];
        _mediaPlayer.equalizer = equalizer;
    } else {
        float preampValue = [userDefaults floatForKey:kVLCSettingDefaultPreampLevel];
        if (preampValue != 0.) {
            APLog(@"Enforcing presumbly disabled equalizer due to custom preamp value of %f2.0", preampValue);
            VLCAudioEqualizer *equalizer = [[VLCAudioEqualizer alloc] init];
            equalizer.preAmplification = preampValue;
            _mediaPlayer.equalizer = equalizer;
        }
    }

    [_mediaPlayer addObserver:self forKeyPath:@"time" options:0 context:nil];

#if TARGET_OS_IOS
    [_mediaPlayer setRendererItem:_renderer];
#endif

    /* we are playing a collection without a valid index,
     * so this is either 0 or totally random */
    if (_itemInMediaListToBePlayedFirst == -1) {
        if (_shuffleMode) {
            int count = (int)_mediaList.count;
            if (count > 0) {
                _currentIndex = arc4random_uniform(count - 1);
                [self shuffleMediaList];
                _itemInMediaListToBePlayedFirst = (int)[_shuffledOrder[0] integerValue];
            }
        } else {
            _itemInMediaListToBePlayedFirst = 0;
        }
    }

    VLCMedia *media = [_mediaList mediaAtIndex:_itemInMediaListToBePlayedFirst];
    [media parseWithOptions:VLCMediaParseLocal];
    media.delegate = self;
    [media addOptions:self.mediaOptionsDictionary];

    [_listPlayer playItemAtNumber:@(_itemInMediaListToBePlayedFirst)];

    _currentIndex = _itemInMediaListToBePlayedFirst;

    if ([self.delegate respondsToSelector:@selector(prepareForMediaPlayback:)])
        [self.delegate prepareForMediaPlayback:self];

    _currentAspectRatio = VLCAspectRatioDefault;
    _mediaPlayer.videoAspectRatio = NULL;
#if LIBVLC_VERSION_MAJOR == 3
        _mediaPlayer.videoCropGeometry = NULL;
#endif

    if (_pathToExternalSubtitlesFile) {
        /* this could be a path or an absolute string - let's see */
        NSURL *subtitleURL = [NSURL URLWithString:_pathToExternalSubtitlesFile];
        if (!subtitleURL || !subtitleURL.scheme) {
            subtitleURL = [NSURL fileURLWithPath:_pathToExternalSubtitlesFile];
        }
        if (subtitleURL) {
            [_mediaPlayer addPlaybackSlave:subtitleURL type:VLCMediaPlaybackSlaveTypeSubtitle enforce:YES];
        }
    }

    _playerIsSetup = YES;

    [_playbackSessionManagementLock unlock];
}

- (void)stopPlayback
{
    BOOL ret = [_playbackSessionManagementLock tryLock];
    _isInFillToScreen = NO; // reset _isInFillToScreen after playback is finished
    if (!ret) {
        APLog(@"%s: locking failed", __PRETTY_FUNCTION__);
        return;
    }

    if (_mediaPlayer) {
        @try {
            [_mediaPlayer removeObserver:self forKeyPath:@"time"];
        }
        @catch (NSException *exception) {
            APLog(@"we weren't an observer yet");
        }

        if (_mediaPlayer.media) {
            [_mediaPlayer pause];
#if TARGET_OS_IOS
            [self savePlaybackState];
#endif
            [_mediaPlayer stop];
        }

        if (_playbackCompletion) {
            BOOL finishedPlaybackWithError = false;
            if (_mediaPlayer.state == VLCMediaPlayerStateStopped && _mediaPlayer.media != nil) {
                // Since VLCMediaPlayerStateError is sometimes not matched with a valid media.
                // This checks for decoded Audio & Video blocks.
                VLCMediaStats stats = _mediaPlayer.media.statistics;
                finishedPlaybackWithError = (stats.decodedAudio == 0) && (stats.decodedVideo == 0);
            } else {
                finishedPlaybackWithError = _mediaPlayer.state == VLCMediaPlayerStateError;
            }
            finishedPlaybackWithError = finishedPlaybackWithError && !_sessionWillRestart;

            _playbackCompletion(!finishedPlaybackWithError);
        }

        _mediaPlayer = nil;
        _listPlayer = nil;
    }

    for (NSURL *url in _openedLocalURLs) {
        [url stopAccessingSecurityScopedResource];
    }
    _openedLocalURLs = nil;
    _openedLocalURLs = [[NSMutableArray alloc] init];

    if (!_sessionWillRestart) {
        _mediaList = nil;
        _mediaList = [[VLCMediaList alloc] init];
    }
    _playerIsSetup = NO;

    [_playbackSessionManagementLock unlock];
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackDidStop object:self];
    if (_sessionWillRestart) {
        _sessionWillRestart = NO;
        [self startPlayback];
    }
}

#if TARGET_OS_IOS
- (void)restoreAudioAndSubtitleTrack
{
    VLCMLMedia *media = [VLCMLMedia mediaForPlayingMedia:_mediaPlayer.media];

    if (media) {
        _mediaPlayer.currentAudioTrackIndex = (int) media.audioTrackIndex;
        _mediaPlayer.currentVideoSubTitleIndex = (int) media.subtitleTrackIndex;
    }
}
#endif

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([self.delegate respondsToSelector:@selector(playbackPositionUpdated:)])
        [self.delegate playbackPositionUpdated:self];

    if (_majorPositionChangeInProgress >= 1) {
        [self.metadata updateExposedTimingFromMediaPlayer:_listPlayer.mediaPlayer];
        _majorPositionChangeInProgress++;

        /* we wait up to 10 time change intervals for the major position change
         * to take effect, afterwards we give up, safe battery and let the OS calculate the position */
        if (_majorPositionChangeInProgress == 10) {
            _majorPositionChangeInProgress = 0;
        }
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackPositionUpdated
                                                        object:self];
}

- (NSInteger)mediaDuration
{
    return _mediaPlayer.media.length.intValue;;
}

- (BOOL)isPlaying
{
    return _mediaPlayer.isPlaying;
}

- (VLCRepeatMode)repeatMode
{
    return _listPlayer.repeatMode;
}

- (void)setRepeatMode:(VLCRepeatMode)repeatMode
{
    _listPlayer.repeatMode = repeatMode;

    if ([self.delegate respondsToSelector:@selector(playModeUpdated)]) {
        [self.delegate playModeUpdated];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackModeUpdated object:self];

#if TARGET_OS_IOS
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kVLCPlayerShouldRememberState]) {
        [defaults setInteger:repeatMode forKey:kVLCPlayerIsRepeatEnabled];
    }
#endif
}

- (BOOL)currentMediaHasChapters
{
    return [_mediaPlayer numberOfTitles] > 1 || [_mediaPlayer numberOfChaptersForTitle:_mediaPlayer.currentTitleIndex] > 1;
}

- (BOOL)currentMediaHasTrackToChooseFrom
{
    /* allow track selection if there is more than 1 audio track or if there is video because even if
     * there is only video, there will always be the option to download additional subtitles */
    return [[_mediaPlayer audioTrackIndexes] count] > 2 || [[_mediaPlayer videoTrackIndexes] count] >= 1;
}

- (BOOL)isSeekable
{
    return _mediaPlayer.isSeekable;
}

- (BOOL)isNextMediaAvailable
{
    if (_mediaList.count == 1) {
        return NO;
    }

    if (_currentIndex < _mediaList.count - 1) {
        return YES;
    }

    return NO;
}

- (NSNumber *)playbackTime
{
    return _mediaPlayer.time.value;
}

- (float)playbackRate
{
    return _mediaPlayer.rate;
}

- (void)setPlaybackRate:(float)playbackRate
{
    [_mediaPlayer setRate:playbackRate];
    _metadata.playbackRate = @(_mediaPlayer.rate);
}

- (void)setAudioDelay:(float)audioDelay
{
    _mediaPlayer.currentAudioPlaybackDelay = 1000.*audioDelay;
}

- (float)audioDelay
{
    return _mediaPlayer.currentAudioPlaybackDelay/1000.;
}

- (float)playbackPosition
{
    return [_mediaPlayer position];
}

- (void)setPlaybackPosition:(float)position
{
    _mediaPlayer.position = position;
    _majorPositionChangeInProgress = 1;
}

- (void)setSubtitleDelay:(float)subtitleDeleay
{
    _mediaPlayer.currentVideoSubTitleDelay = 1000.*subtitleDeleay;
}

- (float)subtitleDelay
{
    return _mediaPlayer.currentVideoSubTitleDelay/1000.;
}

- (void)toggleRepeatMode
{
    VLCRepeatMode newRepeatMode;
    if (_listPlayer.repeatMode == VLCRepeatAllItems) {
        newRepeatMode = VLCDoNotRepeat;
    } else {
        newRepeatMode = _listPlayer.repeatMode + 1;
    }

    [self setRepeatMode:newRepeatMode];
}

- (NSInteger)indexOfCurrentAudioTrack
{
    return [_mediaPlayer.audioTrackIndexes indexOfObject:@(_mediaPlayer.currentAudioTrackIndex)];
}

- (NSInteger)indexOfCurrentSubtitleTrack
{
    return [_mediaPlayer.videoSubTitlesIndexes indexOfObject:@(_mediaPlayer.currentVideoSubTitleIndex)];
}

- (NSInteger)indexOfCurrentChapter
{
    return _mediaPlayer.currentChapterIndex;
}

- (NSInteger)indexOfCurrentTitle
{
    return _mediaPlayer.currentTitleIndex;
}

- (NSInteger)numberOfAudioTracks
{
    return [_mediaPlayer numberOfAudioTracks] + 1;
}

- (NSInteger)numberOfVideoSubtitlesIndexes
{
    return _mediaPlayer.videoSubTitlesIndexes.count + 2;
}

- (NSInteger)numberOfTitles
{
    return  [_mediaPlayer numberOfTitles];
}

- (NSInteger)numberOfChaptersForCurrentTitle
{
    return [_mediaPlayer numberOfChaptersForTitle:_mediaPlayer.currentTitleIndex];
}

- (NSString *)videoSubtitleNameAtIndex:(NSInteger)index
{
    NSInteger count = _mediaPlayer.videoSubTitlesNames.count;
    if (index >= 0 && index < count) {
        return _mediaPlayer.videoSubTitlesNames[index];
    } else if (index == count) {
        return NSLocalizedString(@"SELECT_SUBTITLE_FROM_FILES", nil);
    }
    else if (index == count + 1) {
        return NSLocalizedString(@"DOWNLOAD_SUBS_FROM_OSO", nil);
    }
    return @"";
}

- (NSString *)audioTrackNameAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _mediaPlayer.audioTrackNames.count)
        return _mediaPlayer.audioTrackNames[index];
    else if (index == _mediaPlayer.audioTrackNames.count)
        return NSLocalizedString(@"SELECT_AUDIO_FROM_FILES", nil);
    return @"";
}

- (NSDictionary *)titleDescriptionsDictAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _mediaPlayer.titleDescriptions.count)
        return _mediaPlayer.titleDescriptions[index];
    return [NSDictionary dictionary];
}

- (NSDictionary *)chapterDescriptionsDictAtIndex:(NSInteger)index
{
    NSArray *chapterDescriptions = [_mediaPlayer chapterDescriptionsOfTitle:_mediaPlayer.currentTitleIndex];
    if (index >= 0 && index < chapterDescriptions.count)
        return chapterDescriptions[index];
    return [NSDictionary dictionary];
}

- (void)selectAudioTrackAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _mediaPlayer.audioTrackIndexes.count) {
        //we can cast this cause we won't have more than 2 million audiotracks
        _mediaPlayer.currentAudioTrackIndex = [_mediaPlayer.audioTrackIndexes[index] intValue];
    }
}

- (void)selectVideoSubtitleAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _mediaPlayer.videoSubTitlesIndexes.count) {
        _mediaPlayer.currentVideoSubTitleIndex = [_mediaPlayer.videoSubTitlesIndexes[index] intValue];
    }
}

- (void)selectTitleAtIndex:(NSInteger)index
{
    if (index >= 0 && index < [_mediaPlayer numberOfTitles]) {
        //we can cast this cause we won't have more than 2 million titles
        _mediaPlayer.currentTitleIndex = (int)index;
    }
}

- (void)selectChapterAtIndex:(NSInteger)index
{
    if (index >= 0 && index < [self numberOfChaptersForCurrentTitle]) {
        //we can cast this cause we won't have more than 2 million chapters
        _mediaPlayer.currentChapterIndex = (int)index;
    }
}

- (void)shortJumpForward
{
    [_mediaPlayer shortJumpForward];
}

- (void)shortJumpBackward
{
    [_mediaPlayer shortJumpBackward];
}

- (VLCTime *)remainingTime
{
    return [_mediaPlayer remainingTime];
}

- (void)setAudioPassthrough:(BOOL)shouldPass
{
    _mediaPlayer.audio.passthrough = shouldPass;
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    VLCMediaPlayerState currentState = _mediaPlayer.state;

    switch (currentState) {
        case VLCMediaPlayerStateBuffering: {
            /* attach delegate */
            _mediaPlayer.media.delegate = self;

            /* on-the-fly values through hidden API */
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            [_mediaPlayer performSelector:@selector(setTextRendererFont:) withObject:[defaults objectForKey:kVLCSettingSubtitlesFont]];
            [_mediaPlayer performSelector:@selector(setTextRendererFontSize:) withObject:[defaults objectForKey:kVLCSettingSubtitlesFontSize]];
            [_mediaPlayer performSelector:@selector(setTextRendererFontColor:) withObject:[defaults objectForKey:kVLCSettingSubtitlesFontColor]];
            [_mediaPlayer performSelector:@selector(setTextRendererFontForceBold:) withObject:[defaults objectForKey:kVLCSettingSubtitlesBoldFont]];
#pragma clang diagnostic pop
        } break;

        case VLCMediaPlayerStateOpening: {
#if TARGET_OS_IOS
            [self _recoverLastPlaybackState];
#else
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            BOOL bValue = [defaults boolForKey:kVLCSettingUseSPDIF];

            if (bValue) {
                _mediaPlayer.audio.passthrough = bValue;
            }
#endif
            [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackDidStart object:self];
        } break;

        case VLCMediaPlayerStatePlaying: {
            [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackDidResume object:self];
        } break;

        case VLCMediaPlayerStatePaused: {
#if TARGET_OS_IOS
            [self savePlaybackState];
#endif
            [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackDidPause object:self];
        } break;

        case VLCMediaPlayerStateError: {
            APLog(@"Playback failed");
            dispatch_async(dispatch_get_main_queue(),^{
                [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackDidFail object:self];
            });
            _sessionWillRestart = NO;
            [self stopPlayback];
        } break;
#if LIBVLC_VERSION_MAJOR == 3
        case VLCMediaPlayerStateEnded: {
#endif
#if LIBVLC_VERSION_MAJOR == 4
        case VLCMediaPlayerStateStopping: {
#endif
            NSInteger nextIndex = [self nextMediaIndex:false];

            if (nextIndex > -1) {
                [_listPlayer playItemAtNumber:@(nextIndex)];
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:VLCPlaybackServicePlaybackMetadataDidChange object:self];
            }
        } break;
        case VLCMediaPlayerStateStopped: {
            [_listPlayer.mediaList lock];
            NSUInteger listCount = _listPlayer.mediaList.count;
            [_listPlayer.mediaList unlock];

            if ([_listPlayer.mediaList indexOfMedia:_mediaPlayer.media] == listCount - 1
                && self.repeatMode == VLCDoNotRepeat) {
                _sessionWillRestart = NO;
                [self stopPlayback];
            }
        } break;
        default:
            break;
    }

    _mediaPlayerState = currentState;

    if ([self.delegate respondsToSelector:@selector(mediaPlayerStateChanged:isPlaying:currentMediaHasTrackToChooseFrom:currentMediaHasChapters:forPlaybackService:)])
        [self.delegate mediaPlayerStateChanged:currentState
                                     isPlaying:_mediaPlayer.isPlaying
              currentMediaHasTrackToChooseFrom:self.currentMediaHasTrackToChooseFrom
                       currentMediaHasChapters:self.currentMediaHasChapters
                         forPlaybackService:self];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsMetadataUpdate];
    });
}

- (void)setPlayAsAudio:(BOOL)playAsAudio
{
    _playAsAudio = playAsAudio;
}

#pragma mark - playback controls
- (void)playPause
{
    [_mediaPlayer isPlaying] ? [self pause] : [self play];
}

- (void)play
{
    [_listPlayer play];
}

- (void)pause
{
    [_listPlayer pause];
}

- (void)playItemAtIndex:(NSUInteger)index
{
    VLCMedia *media = [_mediaList mediaAtIndex:index];
    [_listPlayer playItemAtNumber:[NSNumber numberWithUnsignedInteger:index]];
    _mediaPlayer.media = media;
    _currentIndex = [_mediaList indexOfMedia:media];
    if ([self.delegate respondsToSelector:@selector(prepareForMediaPlayback:)])
        [self.delegate prepareForMediaPlayback:self];
}

- (void)setShuffleMode:(BOOL)shuffleMode
{
    _shuffleMode = shuffleMode;

    if (_shuffleMode) {
        [self shuffleMediaList];
        _currentIndex = 0;
    } else {
        _currentIndex = [_shuffledOrder[_currentIndex] integerValue];
    }

    if ([self.delegate respondsToSelector:@selector(playModeUpdated)]) {
        [self.delegate playModeUpdated];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackModeUpdated object:self];

#if TARGET_OS_IOS
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults valueForKey:kVLCPlayerShouldRememberState] boolValue]) {
        [defaults setBool:shuffleMode forKey:kVLCPlayerIsShuffleEnabled];
    }
#endif
}

- (void)shuffleMediaList {
    NSInteger mediaListLength = _mediaList.count;

    if (mediaListLength <= 1) {
        return;
    }
    _shuffledOrder = [[NSMutableArray alloc]init];
    for (int i = 0; i < mediaListLength; i++)
    {
        [_shuffledOrder addObject:[NSNumber numberWithInt:i]];
    }
    [_shuffledOrder exchangeObjectAtIndex:0 withObjectAtIndex:_currentIndex];
    for (NSInteger i = 1; i < mediaListLength; i++) {
        NSInteger nElements = mediaListLength - i;
        NSInteger n = arc4random_uniform((uint32_t)nElements) + i;
        [_shuffledOrder exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
}

- (NSInteger)nextMediaIndex:(BOOL)isButtonPressed
{
    int mediaListCount = (int) _mediaList.count;

    NSInteger nextIndex = 0;
    if (!_currentIndex) {
        _currentIndex = [_mediaList indexOfMedia:self.currentlyPlayingMedia];
    }

    // Change the repeat mode if next button is pressed
    if (self.repeatMode == VLCRepeatCurrentItem && isButtonPressed) {
        [self setRepeatMode:VLCRepeatAllItems];
        if ([self.delegate respondsToSelector:@selector(playModeUpdated)]) {
            [self.delegate playModeUpdated];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackModeUpdated object:self];
    } else if (self.repeatMode == VLCRepeatCurrentItem && !isButtonPressed) {
        return _currentIndex;
    }

    // Normal playback
    if (_currentIndex + 1 < mediaListCount) {
        nextIndex = _currentIndex + 1;
    } else {
        if (self.repeatMode == VLCRepeatAllItems) {
            nextIndex = 0;
        } else {
            nextIndex = -1;
        }
    }

    _currentIndex = nextIndex;

    if (_shuffleMode && mediaListCount > 2 && _currentIndex >= 0 && _currentIndex < _shuffledOrder.count) {
        return [_shuffledOrder[_currentIndex] integerValue];
    }

    return _currentIndex;
}

- (BOOL)next
{
    if (_mediaList.count == 1) {
        NSNumber *skipLength = [[NSUserDefaults standardUserDefaults] valueForKey:kVLCSettingPlaybackForwardSkipLength];
        [_mediaPlayer jumpForward:skipLength.intValue];
        return YES;
    }

    NSInteger nextIndex = [self nextMediaIndex:true];

    if (nextIndex < 0) {
        if (self.repeatMode == VLCRepeatAllItems) {
#if TARGET_OS_IOS
            [self savePlaybackState];
#endif
            [_listPlayer next];
            [[NSNotificationCenter defaultCenter]
             postNotificationName:VLCPlaybackServicePlaybackMetadataDidChange object:self];
        } else if (self.repeatMode == VLCDoNotRepeat) {
            [self stopPlayback];
        }
        return NO;
    }
#if TARGET_OS_IOS
    [self savePlaybackState];
#endif

    [_listPlayer playItemAtNumber:@(nextIndex)];
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackMetadataDidChange object:self];
    return YES;
}

- (BOOL)previous
{
    if (_mediaList.count > 1) {
        VLCTime *playedTime = self.playedTime;
        if (playedTime.value.longLongValue / 2000 >= 1) {
            self.playbackPosition = .0;
        } else {
#if TARGET_OS_IOS
            [self savePlaybackState];
#endif
            if (!_currentIndex) {
                _currentIndex = [_mediaList indexOfMedia:self.currentlyPlayingMedia];
            }

            // Change the repeat mode if next button is pressed
            if (self.repeatMode == VLCRepeatCurrentItem) {
                [self setRepeatMode:VLCRepeatAllItems];
                if ([self.delegate respondsToSelector:@selector(playModeUpdated)]) {
                    [self.delegate playModeUpdated];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackModeUpdated object:self];
            }

            if(_currentIndex > 0) {
                _currentIndex -= 1;
            } else{
                if(_listPlayer.repeatMode == VLCRepeatAllItems) {
                    _currentIndex = _mediaList.count - 1;
                }
            }
            if(_shuffleMode){
                [_listPlayer playItemAtNumber:@([_shuffledOrder[_currentIndex] integerValue])];
            }else{
                [_listPlayer playItemAtNumber:@(_currentIndex)];
            }
        }
    } else {
        NSNumber *skipLength = [[NSUserDefaults standardUserDefaults] valueForKey:kVLCSettingPlaybackBackwardSkipLength];
        [_mediaPlayer jumpBackward:skipLength.intValue];
    }
    return YES;
}

- (void)jumpForward:(int)interval
{
    [_mediaPlayer jumpForward:interval];
}

- (void)jumpBackward:(int)interval
{
    [_mediaPlayer jumpBackward:interval];
}

- (UIScreen *)currentScreen
{
    return [[UIDevice currentDevice] VLCHasExternalDisplay] ? [UIScreen screens][1] : [UIScreen mainScreen];
}

- (void)switchToFillToScreen
{
    UIScreen *screen = [self currentScreen];
    CGSize screenSize = screen.bounds.size;

    CGSize videoSize = _mediaPlayer.videoSize;

    CGFloat ar = videoSize.width / (float)videoSize.height;
    CGFloat dar = screenSize.width / (float)screenSize.height;

    CGFloat scale;

    if (dar >= ar) {
        scale = screenSize.width / (float)videoSize.width;
    } else {
        scale = screenSize.height / (float)videoSize.height;
    }

    // Multiplied by screen.scale in consideration of pt to px
    _mediaPlayer.scaleFactor = scale * screen.scale;
    _isInFillToScreen = YES;
}

- (void)switchAspectRatio:(BOOL)toggleFullScreen
{
    if (toggleFullScreen) {
        // Set previousAspectRatio to current, unless we're in full screen
        _previousAspectRatio = _isInFillToScreen ? _previousAspectRatio : _currentAspectRatio;
        _currentAspectRatio = _isInFillToScreen ? _previousAspectRatio : VLCAspectRatioFillToScreen;
    } else {
        // Increment unless hitting last aspectratio
        _currentAspectRatio = _currentAspectRatio == VLCAspectRatioSixteenToTen ? VLCAspectRatioDefault : _currentAspectRatio + 1;
    }

    // If fullScreen is toggled directly and then the aspect ratio changes, fullScreen is not reset
    if (_isInFillToScreen) _isInFillToScreen = NO;

    switch (_currentAspectRatio) {
        case VLCAspectRatioDefault:
            _mediaPlayer.scaleFactor = 0;
            _mediaPlayer.videoAspectRatio = NULL;
#if LIBVLC_VERSION_MAJOR == 3
            _mediaPlayer.videoCropGeometry = NULL;
#endif
            break;
        case VLCAspectRatioFillToScreen:
            // Reset aspect ratio only with aspectRatio button since we want to keep
            // the user ratio with double tap.
            _mediaPlayer.videoAspectRatio = NULL;
            [self switchToFillToScreen];
            break;
        case VLCAspectRatioFourToThree:
        case VLCAspectRatioSixteenToTen:
        case VLCAspectRatioSixteenToNine:
            _mediaPlayer.scaleFactor = 0;
#if LIBVLC_VERSION_MAJOR == 3
            _mediaPlayer.videoCropGeometry = NULL;
            _mediaPlayer.videoAspectRatio = (char *)[[self stringForAspectRatio:_currentAspectRatio] UTF8String];
#else
            _mediaPlayer.videoAspectRatio = [self stringForAspectRatio:_currentAspectRatio];
#endif
    }

    if ([self.delegate respondsToSelector:@selector(showStatusMessage:)]) {
        [self.delegate showStatusMessage:[NSString stringWithFormat:NSLocalizedString(@"AR_CHANGED", nil), [self stringForAspectRatio:_currentAspectRatio]]];
    }

    if ([self.delegate respondsToSelector:@selector(playbackServiceDidSwitchAspectRatio:)]) {
        [_delegate playbackServiceDidSwitchAspectRatio:_currentAspectRatio];
    }
}

- (NSString *)stringForAspectRatio:(VLCAspectRatio)ratio
{
    switch (ratio) {
            case VLCAspectRatioFillToScreen:
            return NSLocalizedString(@"FILL_TO_SCREEN", nil);
            case VLCAspectRatioDefault:
            return NSLocalizedString(@"DEFAULT", nil);
            case VLCAspectRatioFourToThree:
            return @"4:3";
            case VLCAspectRatioSixteenToTen:
            return @"16:10";
            case VLCAspectRatioSixteenToNine:
            return @"16:9";
        default:
            NSAssert(NO, @"this shouldn't happen");
    }
}

- (void)setVideoTrackEnabled:(BOOL)enabled
{
    if (!enabled)
        _mediaPlayer.currentVideoTrackIndex = -1;
    else if (_mediaPlayer.currentVideoTrackIndex == -1) {
        for (NSNumber *trackId in _mediaPlayer.videoTrackIndexes) {
            if ([trackId intValue] != -1) {
                _mediaPlayer.currentVideoTrackIndex = [trackId intValue];
                break;
            }
        }
    }
}

- (void)setVideoOutputView:(UIView *)videoOutputView
{
    if (videoOutputView) {
        if ([_actualVideoOutputView superview] != nil)
            [_actualVideoOutputView removeFromSuperview];

        _actualVideoOutputView.frame = (CGRect){CGPointZero, videoOutputView.frame.size};

        [self setVideoTrackEnabled:true];

        [videoOutputView addSubview:_actualVideoOutputView];
        [_actualVideoOutputView layoutSubviews];
        [_actualVideoOutputView updateConstraints];
        [_actualVideoOutputView setNeedsLayout];
    } else
        [_actualVideoOutputView removeFromSuperview];

    _videoOutputViewWrapper = videoOutputView;
}

- (UIView *)videoOutputView
{
    return _videoOutputViewWrapper;
}

#pragma mark - 360 Support
#if !TARGET_OS_TV
- (BOOL)updateViewpoint:(CGFloat)yaw pitch:(CGFloat)pitch roll:(CGFloat)roll fov:(CGFloat)fov absolute:(BOOL)absolute
{
    //adjusting the values
    if (fabs(yaw) > 180) {
        yaw = yaw > 0 ? yaw - 360 : yaw + 360;
    }
    if (fabs(roll) > 180) {
        roll = roll > 0 ? roll - 360 : roll + 360;
    }
    if (fabs(pitch) > 90) {
        pitch = pitch > 0 ? pitch - 180 : pitch + 180;
    }
    return [_mediaPlayer updateViewpoint:yaw pitch:pitch roll:roll fov:fov absolute:absolute];
}

- (CGFloat)yaw
{
    return _mediaPlayer.yaw;
}

- (CGFloat)pitch
{
    return _mediaPlayer.pitch;
}

- (CGFloat)roll
{
    return _mediaPlayer.roll;
}

- (CGFloat)fov
{
    return _mediaPlayer.fov;
}

- (BOOL)currentMediaIs360Video
{
    return [self currentMediaProjection] == VLCMediaProjectionEquiRectangular;
}

- (NSInteger)currentMediaProjection
{
#if LIBVLC_VERSION_MAJOR == 3
    VLCMedia *media = [_mediaPlayer media];
    NSInteger currentVideoTrackIndex = [_mediaPlayer currentVideoTrackIndex];

    if (media && currentVideoTrackIndex >= 0) {
        NSArray *tracksInfo = media.tracksInformation;

        for (NSDictionary *track in tracksInfo) {
            if ([track[VLCMediaTracksInformationType] isEqualToString:VLCMediaTracksInformationTypeVideo]) {
                return [track[VLCMediaTracksInformationVideoProjection] integerValue];
            }
        }
    }
#else
    NSArray *videoTracks = _mediaPlayer.videoTracks;
    VLCMediaPlayerTrack *selectedVideoTrack = nil;
    for (VLCMediaPlayerTrack *track in videoTracks) {
        if (track.selected) {
            selectedVideoTrack = track;
            break;
        }
    }
    if (selectedVideoTrack) {
        return selectedVideoTrack.video.projection;
    }
#endif
    return -1;
}
#endif

#pragma mark - equalizer

- (void)setAmplification:(CGFloat)amplification forBand:(unsigned int)index
{
    VLCAudioEqualizer *equalizer = _mediaPlayer.equalizer;
    if (!equalizer) {
        equalizer = [[VLCAudioEqualizer alloc] init];
        _mediaPlayer.equalizer = equalizer;
    }

    NSArray *bands = equalizer.bands;
    if (index < bands.count) {
        VLCAudioEqualizerBand *band = equalizer.bands[index];
        band.amplification = amplification;
    }
}

- (CGFloat)amplificationOfBand:(unsigned int)index
{
    VLCAudioEqualizer *equalizer = _mediaPlayer.equalizer;
    if (!equalizer) {
        equalizer = [[VLCAudioEqualizer alloc] init];
        _mediaPlayer.equalizer = equalizer;
    }

    NSArray *bands = equalizer.bands;
    if (index < bands.count) {
        VLCAudioEqualizerBand *band = equalizer.bands[index];
        return band.amplification;
    }
    return 0.;
}

- (NSArray *)equalizerProfiles
{
    return VLCAudioEqualizer.presets;
}

- (void)resetEqualizerFromProfile:(unsigned int)profile
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (profile == 0) {
        _mediaPlayer.equalizer = nil;
        [userDefaults setBool:YES forKey:kVLCSettingEqualizerProfileDisabled];

        float preampValue = [userDefaults floatForKey:kVLCSettingDefaultPreampLevel];
        if (preampValue != 6.0) {
            APLog(@"Enforcing presumbly disabled equalizer due to custom preamp value of %f2.0", preampValue);
            VLCAudioEqualizer *eq = [[VLCAudioEqualizer alloc] init];
            eq.preAmplification = preampValue;
            _mediaPlayer.equalizer = eq;
        }
        return;
    }

    [userDefaults setBool:NO forKey:kVLCSettingEqualizerProfileDisabled];

    unsigned int actualProfile = profile - 1;
    [userDefaults setInteger:actualProfile forKey:kVLCSettingEqualizerProfile];

    NSArray *presets = [VLCAudioEqualizer presets];
    VLCAudioEqualizer *equalizer = [[VLCAudioEqualizer alloc] initWithPreset:presets[actualProfile]];
    _mediaPlayer.equalizer = equalizer;
}

- (void)setPreAmplification:(CGFloat)preAmplification
{
    VLCAudioEqualizer *equalizer = _mediaPlayer.equalizer;
    if (!equalizer) {
        equalizer = [[VLCAudioEqualizer alloc] init];
    }
    equalizer.preAmplification = preAmplification;
    _mediaPlayer.equalizer = equalizer;
}

- (CGFloat)preAmplification
{
    VLCAudioEqualizer *equalizer = _mediaPlayer.equalizer;
    if (equalizer) {
        return equalizer.preAmplification;
    }

    return [[NSUserDefaults standardUserDefaults] floatForKey:kVLCSettingDefaultPreampLevel];
}

- (unsigned int)numberOfBands
{
    /* we need to alloc an equalizer here to get the number of bands to have a proper UI
     * in case no equalizer was configured yet */
    VLCAudioEqualizer *equalizer = _mediaPlayer.equalizer;
    if (!equalizer) {
        equalizer = [[VLCAudioEqualizer alloc] init];
    }
    return (unsigned int)equalizer.bands.count;
}

- (CGFloat)frequencyOfBandAtIndex:(unsigned int)index
{
    VLCAudioEqualizer *equalizer = _mediaPlayer.equalizer;
    if (!equalizer) {
        equalizer = [[VLCAudioEqualizer alloc] init];
    }
    VLCAudioEqualizerBand *band = equalizer.bands[index];
    return band.frequency;
}

- (unsigned int)selectedEqualizerProfile
{
    /* this is a bit complex, if the eq is off, we need to return 0
     * if it is on, we need to provide the profile + 1 as the UI fakes a "Off" profile in its list */
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:kVLCSettingEqualizerProfileDisabled]) {
        return 0;
    }
    unsigned int actualProfile = (unsigned int)[userDefaults integerForKey:kVLCSettingEqualizerProfile];
    return actualProfile + 1;
}

#pragma mark - AVAudioSession Notification Observers

- (void)handleInterruption:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;

    if (!userInfo || !userInfo[AVAudioSessionInterruptionTypeKey]) {
        return;
    }

    NSUInteger interruptionType = [userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];

    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        [_mediaPlayer pause];
    } else if (interruptionType == AVAudioSessionInterruptionTypeEnded
               && [userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue] == AVAudioSessionInterruptionOptionShouldResume) {
        [_mediaPlayer play];
    }
}

- (BOOL)isExternalAudioPlaybackDeviceConnected
{
    /* check what output device is currently connected
     * this code assumes that everything which is not a builtin speaker, must be external */
    NSArray *outputs = [[AVAudioSession sharedInstance] currentRoute].outputs;
    AVAudioSessionPortDescription *outputDescription = outputs.firstObject;
    return ![outputDescription.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker];
}

- (void)audioSessionRouteChange:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSInteger routeChangeReason = [[userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];

    if (routeChangeReason == AVAudioSessionRouteChangeReasonRouteConfigurationChange)
        return;

    BOOL externalAudioPlaybackDeviceConnected = [self isExternalAudioPlaybackDeviceConnected];

    if (_externalAudioPlaybackDeviceConnected && !externalAudioPlaybackDeviceConnected && [_mediaPlayer isPlaying]) {
        APLog(@"Pausing playback as previously connected external audio playback device was removed");
        [_mediaPlayer pause];
#if TARGET_OS_IOS
       [self savePlaybackState];
#endif
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackDidPause object:self];
    }
    _externalAudioPlaybackDeviceConnected = externalAudioPlaybackDeviceConnected;
}

#pragma mark - Managing the media item

- (VLCMedia *)currentlyPlayingMedia
{
    return _mediaPlayer.media;
}

#pragma mark - metadata handling
- (void)performNavigationAction:(VLCMediaPlaybackNavigationAction)action
{
    [_mediaPlayer performNavigationAction:action];
}
- (void)mediaDidFinishParsing:(VLCMedia *)aMedia
{
    [self setNeedsMetadataUpdate];
}

- (void)mediaMetaDataDidChange:(VLCMedia*)aMedia
{
    [self setNeedsMetadataUpdate];
}

- (void)setNeedsMetadataUpdate
{
#if TARGET_OS_IOS
    VLCMLMedia *media = self->_mediaPlayer.media ? [VLCMLMedia mediaForPlayingMedia:self->_mediaPlayer.media] : nil;
    [_metadata updateMetadataFromMedia:media mediaPlayer:_mediaPlayer];
#else
    [_metadata updateMetadataFromMediaPlayer:_mediaPlayer];
#endif

    [self recoverDisplayedMetadata];
}

#if TARGET_OS_IOS
- (void)_recoverLastPlaybackState
{
    VLCMLMedia *media = [VLCMLMedia mediaForPlayingMedia:_mediaPlayer.media];
    if (!media) return;

    if (self.repeatMode != VLCDoNotRepeat) {
        goto bailout;
    }

    CGFloat lastPosition = media.progress;
    // .95 prevents the controller from opening and closing immediatly when restoring state
    //  Additionally, check if the media is more than 10 sec
    if (lastPosition < .95
        && _mediaPlayer.position < lastPosition) {
        NSInteger continuePlayback;
        if (media.type == VLCMLMediaTypeAudio) {
            if (!media.isPodcast) {
                goto bailout;
            }
            continuePlayback = [[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingContinueAudioPlayback] integerValue];
        } else {
            if (media.duration < 10000 && !media.isExternalMedia) {
                goto bailout;
            }
            continuePlayback = [[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingContinuePlayback] integerValue];
        }

        if (continuePlayback == 1) {
            [self setPlaybackPosition:lastPosition];
        } else if (continuePlayback == 0) {
            NSArray<VLCAlertButton *> *buttonsAction = @[[[VLCAlertButton alloc] initWithTitle: NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                                                         style: UIAlertActionStyleCancel
                                                                                        action: nil],
                                                         [[VLCAlertButton alloc] initWithTitle: NSLocalizedString(@"BUTTON_CONTINUE", nil)
                                                                                        action: ^(UIAlertAction *action) {
                                                                                            [self setPlaybackPosition:lastPosition];
                                                                                        }]
                                                         ];
            UIViewController *presentingVC = [UIApplication sharedApplication].delegate.window.rootViewController;
            presentingVC = presentingVC.presentedViewController ?: presentingVC;
            [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"CONTINUE_PLAYBACK", nil)
                                                 errorMessage:[NSString stringWithFormat:NSLocalizedString(@"CONTINUE_PLAYBACK_LONG", nil), media.title]
                                               viewController:presentingVC
                                                buttonsAction:buttonsAction];

        }
    }

    bailout:
    [self restoreAudioAndSubtitleTrack];
}

- (void)_findCachedSubtitlesForMedia:(VLCMedia *)media
{
    /* if we already enforce a subtitle e.g. through Google Drive, don't try to find another */
    if (_pathToExternalSubtitlesFile) {
        return;
    }
    NSURL *mediaURL = media.url;
    if (mediaURL.isFileURL) {
        /* let's see if it is in the Inbox folder or outside our Documents folder and if yes, maybe we have a cached subtitles file? */
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentFolderPath = [searchPaths firstObject];
        NSString *potentialInboxFolderPath = [documentFolderPath stringByAppendingPathComponent:@"Inbox"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *mediaURLpath = mediaURL.path;
        if ([mediaURLpath containsString:potentialInboxFolderPath] && ![mediaURLpath containsString:documentFolderPath]) {
            NSString *mediaFileName = mediaURL.path.lastPathComponent.stringByDeletingPathExtension;
            searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *cachefolderPath = [searchPaths.firstObject stringByAppendingPathComponent:kVLCSubtitlesCacheFolderName];

            NSDirectoryEnumerator *folderEnumerator = [fileManager enumeratorAtURL:[NSURL fileURLWithPath:cachefolderPath]
                                                        includingPropertiesForKeys:@[NSURLNameKey]
                                                                           options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                      errorHandler:nil];
            NSString *theSubtitleFileName;
            for (NSURL *theURL in folderEnumerator) {
                NSString *iter;
                [theURL getResourceValue:&iter forKey:NSURLNameKey error:NULL];

                if ([iter hasPrefix:mediaFileName]) {
                    theSubtitleFileName = iter;
                    break;
                }
            }

            NSURL *subtitleURL = [NSURL fileURLWithPath:[cachefolderPath stringByAppendingPathComponent:theSubtitleFileName]];
            [_mediaPlayer addPlaybackSlave:subtitleURL type:VLCMediaPlaybackSlaveTypeSubtitle enforce:YES];
        }
    }
}
#endif

- (void)recoverDisplayedMetadata
{
    if ([self.delegate respondsToSelector:@selector(displayMetadataForPlaybackService:metadata:)])
        [self.delegate displayMetadataForPlaybackService:self metadata:_metadata];
}

- (void)recoverPlaybackState
{
    if ([self.delegate respondsToSelector:@selector(mediaPlayerStateChanged:isPlaying:currentMediaHasTrackToChooseFrom:currentMediaHasChapters:forPlaybackService:)])
        [self.delegate mediaPlayerStateChanged:_mediaPlayer.state
                                     isPlaying:self.isPlaying
              currentMediaHasTrackToChooseFrom:self.currentMediaHasTrackToChooseFrom
                       currentMediaHasChapters:self.currentMediaHasChapters
                         forPlaybackService:self];
    if ([self.delegate respondsToSelector:@selector(prepareForMediaPlayback:)])
        [self.delegate prepareForMediaPlayback:self];
}

- (void)scheduleSleepTimerWithInterval:(NSTimeInterval)timeInterval
{
    if (_sleepTimer) {
        [_sleepTimer invalidate];
        _sleepTimer = nil;
    }
    _sleepTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(stopPlayback) userInfo:nil repeats:NO];
}

- (BOOL)isPlayingOnExternalScreen
{
#if TARGET_OS_IOS
    return (_renderer || [[UIDevice currentDevice] VLCHasExternalDisplay]);
#else
    return [[UIDevice currentDevice] VLCHasExternalDisplay];
#endif
}

#pragma mark - background interaction

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
#if TARGET_OS_IOS
    [self savePlaybackState];
#endif
    if (![self isPlayingOnExternalScreen]
        && ![[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingContinueAudioInBackgroundKey] boolValue]) {
        if ([_mediaPlayer isPlaying]) {
            [_mediaPlayer pause];
            _shouldResumePlaying = YES;
        }
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    _preBackgroundWrapperView = _videoOutputViewWrapper;

#if TARGET_OS_IOS
    if (!_renderer && _mediaPlayer.audioTrackIndexes.count > 0 && [_mediaPlayer isPlaying])
        [self setVideoTrackEnabled:false];

    if (_renderer) {
        [_backgroundDummyPlayer play];
    }
#else
    if (_mediaPlayer.audioTrackIndexes.count > 0 && [_mediaPlayer isPlaying])
        [self setVideoTrackEnabled:false];
#endif
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    if (_preBackgroundWrapperView) {
        [self setVideoOutputView:_preBackgroundWrapperView];
        _preBackgroundWrapperView = nil;
    }

#if TARGET_OS_IOS
    if (_renderer) {
        [_backgroundDummyPlayer stop];
    }
#endif

    if (_mediaPlayer.currentVideoTrackIndex == -1) {
        [self setVideoTrackEnabled:true];
    }

    if (_shouldResumePlaying) {
        _shouldResumePlaying = NO;
        [_listPlayer play];
    }
}

#pragma mark - helpers

- (NSDictionary *)mediaOptionsDictionary
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return @{ kVLCSettingNetworkCaching : [defaults objectForKey:kVLCSettingNetworkCaching],
              kVLCSettingTextEncoding : [defaults objectForKey:kVLCSettingTextEncoding],
              kVLCSettingSkipLoopFilter : [defaults objectForKey:kVLCSettingSkipLoopFilter],
              kVLCSettingHardwareDecoding : [defaults objectForKey:kVLCSettingHardwareDecoding],
              kVLCSettingNetworkRTSPTCP : [defaults objectForKey:kVLCSettingNetworkRTSPTCP]
    };
}

#if TARGET_OS_IOS
- (void)savePlaybackState
{
    BOOL activePlaybackSession = self.isPlaying || _playerIsSetup;
    if (activePlaybackSession)
        [[VLCAppCoordinator sharedInstance].mediaLibraryService savePlaybackStateFrom:self];
}
#endif

#pragma mark - Renderer

#if TARGET_OS_IOS
- (void)setRenderer:(VLCRendererItem * __nullable)renderer
{
    _renderer = renderer;
    [_mediaPlayer setRendererItem:_renderer];
}
#endif

#pragma mark - PlayerDisplayController

- (void)setPlayerDisplayController:(VLCPlayerDisplayController *)playerDisplayController
{
    _playerDisplayController = playerDisplayController;
}

- (void)setPlayerHidden:(BOOL)hidden
{
    [_playerDisplayController setEditing:hidden];
    [_playerDisplayController dismissPlaybackView];
}

#pragma mark - VLCMediaListPlayerDelegate

- (void)mediaListPlayer:(VLCMediaListPlayer *)player nextMedia:(VLCMedia *)media
{
#if TARGET_OS_IOS
    [self _findCachedSubtitlesForMedia:media];
#endif

    if ([_delegate respondsToSelector:@selector(playbackService:nextMedia:)]) {
        [_delegate playbackService:self nextMedia:media];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackDidMoveOnToNextItem
                                                        object:self];
}

@end
