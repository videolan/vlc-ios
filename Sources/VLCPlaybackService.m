/*****************************************************************************
 * VLCPlaybackService.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2022 VLC authors and VideoLAN
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
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackService.h"
#import <AVFoundation/AVFoundation.h>
#import "VLCRemoteControlService.h"
#import "VLCMetadata.h"
#import "VLCPlayerDisplayController.h"

#import "VLC-Swift.h"

NSString *const VLCPlaybackServicePlaybackDidStart = @"VLCPlaybackServicePlaybackDidStart";
NSString *const VLCPlaybackServicePlaybackDidPause = @"VLCPlaybackServicePlaybackDidPause";
NSString *const VLCPlaybackServicePlaybackDidResume = @"VLCPlaybackServicePlaybackDidResume";
NSString *const VLCPlaybackServicePlaybackDidStop = @"VLCPlaybackServicePlaybackDidStop";
NSString *const VLCPlaybackServicePlaybackMetadataDidChange = @"VLCPlaybackServicePlaybackMetadataDidChange";
NSString *const VLCPlaybackServicePlaybackDidFail = @"VLCPlaybackServicePlaybackDidFail";
NSString *const VLCPlaybackServicePlaybackPositionUpdated = @"VLCPlaybackServicePlaybackPositionUpdated";

#if TARGET_OS_IOS
@interface VLCPlaybackService () <VLCMediaPlayerDelegate, VLCMediaDelegate, VLCMediaListPlayerDelegate, VLCRemoteControlServiceDelegate, EqualizerViewDelegate>
#else
@interface VLCPlaybackService () <VLCMediaPlayerDelegate, VLCMediaDelegate, VLCMediaListPlayerDelegate, VLCRemoteControlServiceDelegate>
#endif
{
    VLCRemoteControlService *_remoteControlService;
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

    BOOL _needsMetadataUpdate;
    BOOL _mediaWasJustStarted;
    int _majorPositionChangeInProgress;
    BOOL _recheckForExistingThumbnail;
    BOOL _externalAudioPlaybackDeviceConnected;

    NSLock *_playbackSessionManagementLock;

    NSMutableArray *_shuffleStack;
    void (^_playbackCompletion)(BOOL success);

    VLCDialogProvider *_dialogProvider;
    VLCCustomDialogRendererHandler *_customDialogHandler;
    VLCPlayerDisplayController *_playerDisplayController;

    NSMutableArray *_openedLocalURLs;
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
        _externalAudioPlaybackDeviceConnected = [self isExternalAudioPlaybackDeviceConnected];
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
        _shuffleStack = [[NSMutableArray alloc] init];

        // Initialize a separate media player in order to play silence so that the application can
        // stay alive in background exclusively for Chromecast.
        _backgroundDummyPlayer = [[VLCMediaPlayer alloc] initWithOptions:@[@"--demux=rawaud"]];
        _backgroundDummyPlayer.media = [[VLCMedia alloc] initWithPath:@"/dev/zero"];

        _mediaList = [[VLCMediaList alloc] init];

        _openedLocalURLs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (VLCRemoteControlService *)remoteControlService
{
    if (!_remoteControlService) {
        _remoteControlService = [[VLCRemoteControlService alloc] init];
        _remoteControlService.remoteControlServiceDelegate = self;
    }
    return _remoteControlService;
}
#pragma mark - playback management

- (void)openVideoSubTitlesFromFile:(NSString *)pathToFile
{
    [_mediaPlayer addPlaybackSlave:[NSURL fileURLWithPath:pathToFile] type:VLCMediaPlaybackSlaveTypeSubtitle enforce:YES];
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

    /* the chromecast options cannot be set per media, so we need to set it per
     * media player instance however, potentially initialising an additional library instance
     * for this is costly, so this should be done only if needed */
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL chromecastPassthrough = [[userDefaults objectForKey:kVLCSettingCastingAudioPassthrough] boolValue];
    int chromecastQuality = [[userDefaults objectForKey:kVLCSettingCastingConversionQuality] intValue];
    NSMutableArray *libVLCOptions = [NSMutableArray array];
    if (chromecastPassthrough) {
        [libVLCOptions addObject:[@"--" stringByAppendingString:kVLCSettingCastingAudioPassthrough]];
    }
    if (chromecastQuality != 2) {
        [libVLCOptions addObject:[NSString stringWithFormat:@"--%@=%i", kVLCSettingCastingConversionQuality, chromecastQuality]];
    }
    if (libVLCOptions.count > 0) {
        _listPlayer = [[VLCMediaListPlayer alloc] initWithOptions:libVLCOptions
                                                      andDrawable:_actualVideoOutputView];
    } else {
        _listPlayer = [[VLCMediaListPlayer alloc] initWithDrawable:_actualVideoOutputView];
    }
    _listPlayer.delegate = self;

#if MEDIA_PLAYBACK_DEBUG
    _listPlayer.mediaPlayer.libraryInstance.debugLogging = YES;
    _listPlayer.mediaPlayer.libraryInstance.debugLoggingLevel = 4;
#endif
    BOOL saveDebugLogs = [userDefaults boolForKey:kVLCSaveDebugLogs];
    if (saveDebugLogs) {
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
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
        [_listPlayer.mediaPlayer.libraryInstance setDebugLoggingToFile:logFilePath];
    }

    id<VLCFilter> newFilter = _listPlayer.mediaPlayer.adjustFilter;
    [newFilter applyParametersFrom:_adjustFilter.mediaPlayerAdjustFilter];
    newFilter.enabled = _adjustFilter.mediaPlayerAdjustFilter.isEnabled;
    _adjustFilter = [[VLCPlaybackServiceAdjustFilter alloc] initWithMediaPlayerAdjustFilter:newFilter];
    _mediaPlayer = _listPlayer.mediaPlayer;

    [_mediaPlayer setDelegate:self];
    if ([[defaults objectForKey:kVLCSettingPlaybackSpeedDefaultValue] floatValue] != 0)
        [_mediaPlayer setRate: [[defaults objectForKey:kVLCSettingPlaybackSpeedDefaultValue] floatValue]];
    int deinterlace = [[defaults objectForKey:kVLCSettingDeinterlace] intValue];
    [_mediaPlayer setDeinterlace:deinterlace withFilter:@"blend"];

    VLCMedia *media = [_mediaList mediaAtIndex:_itemInMediaListToBePlayedFirst];
    [media parseWithOptions:VLCMediaParseLocal];
    media.delegate = self;
    [media addOptions:self.mediaOptionsDictionary];

    [_listPlayer setMediaList:self.mediaList];

    [_listPlayer setRepeatMode:VLCDoNotRepeat];

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

    // Set last selected equalizer profile if enabled
    _mediaPlayer.equalizerEnabled = ![[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingEqualizerProfileDisabled];

    if (_mediaPlayer.equalizerEnabled) {
        unsigned int profile = (unsigned int)[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingEqualizerProfile] integerValue];
        [_mediaPlayer resetEqualizerFromProfile:profile];
        [_mediaPlayer setPreAmplification:[_mediaPlayer preAmplification]];
    }

    _mediaWasJustStarted = YES;

    [_mediaPlayer addObserver:self forKeyPath:@"time" options:0 context:nil];
    [_mediaPlayer addObserver:self forKeyPath:@"remainingTime" options:0 context:nil];

#if !TARGET_OS_TV
    [_mediaPlayer setRendererItem:_renderer];
#endif

    [_listPlayer playItemAtNumber:@(_itemInMediaListToBePlayedFirst)];

    if ([self.delegate respondsToSelector:@selector(prepareForMediaPlayback:)])
        [self.delegate prepareForMediaPlayback:self];

    _currentAspectRatio = VLCAspectRatioDefault;
    _mediaPlayer.videoAspectRatio = NULL;
    _mediaPlayer.videoCropGeometry = NULL;

    [[self remoteControlService] subscribeToRemoteCommands];

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

    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackDidStart object:self];
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
            [_mediaPlayer removeObserver:self forKeyPath:@"remainingTime"];
        }
        @catch (NSException *exception) {
            APLog(@"we weren't an observer yet");
        }

        if (_mediaPlayer.media) {
            [_mediaPlayer pause];
#if TARGET_OS_IOS
            [_delegate savePlaybackState: self];
#endif
            [_mediaPlayer stop];
        }

        if (_playbackCompletion) {
            BOOL finishedPlaybackWithError = false;
            if (_mediaPlayer.state == VLCMediaPlayerStateStopped && _mediaPlayer.media != nil) {
                // Since VLCMediaPlayerStateError is sometimes not matched with a valid media.
                // This checks for decoded Audio & Video blocks.
                finishedPlaybackWithError = (_mediaPlayer.media.numberOfDecodedAudioBlocks == 0)
                                             && (_mediaPlayer.media.numberOfDecodedVideoBlocks == 0);
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
        NSLog(@"%@", url);
    }
    _openedLocalURLs = nil;
    _openedLocalURLs = [[NSMutableArray alloc] init];

    if (!_sessionWillRestart) {
        _mediaList = nil;
        _mediaList = [[VLCMediaList alloc] init];
    }
    _playerIsSetup = NO;
    [_shuffleStack removeAllObjects];

    [[self remoteControlService] unsubscribeFromRemoteCommands];

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
    VLCMLMedia *media = [_delegate mediaForPlayingMedia:_mediaPlayer.media];

    if (media) {
        _mediaPlayer.currentAudioTrackIndex = (int) media.audioTrackIndex;
        _mediaPlayer.currentVideoSubTitleIndex = (int) media.subtitleTrackIndex;
    }
}
#endif

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (_mediaWasJustStarted) {
        _mediaWasJustStarted = NO;
#if TARGET_OS_IOS
        if (self.mediaList) {
            [self _recoverLastPlaybackState];
        }
#else
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL bValue = [defaults boolForKey:kVLCSettingUseSPDIF];

        if (bValue) {
           _mediaPlayer.audio.passthrough = bValue;
        }
#endif
    }

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

- (BOOL)willPlay
{
    return _mediaPlayer.willPlay;
}

- (VLCRepeatMode)repeatMode
{
    return _listPlayer.repeatMode;
}

- (void)setRepeatMode:(VLCRepeatMode)repeatMode
{
    _listPlayer.repeatMode = repeatMode;
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
    if (_listPlayer.repeatMode == VLCRepeatAllItems) {
        _listPlayer.repeatMode = VLCDoNotRepeat;
    } else {
        _listPlayer.repeatMode += 1;
    }
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
    return [_mediaPlayer numberOfAudioTracks];
}

- (NSInteger)numberOfVideoSubtitlesIndexes
{
    return _mediaPlayer.videoSubTitlesIndexes.count + 1;
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
        return NSLocalizedString(@"DOWNLOAD_SUBS_FROM_OSO", nil);
    }
    return @"";
}

- (NSString *)audioTrackNameAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _mediaPlayer.audioTrackNames.count)
        return _mediaPlayer.audioTrackNames[index];
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

        case VLCMediaPlayerStateError: {
            APLog(@"Playback failed");
            dispatch_async(dispatch_get_main_queue(),^{
                [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackDidFail object:self];
            });
            _sessionWillRestart = NO;
            [self stopPlayback];
        } break;
        case VLCMediaPlayerStateEnded: {
            NSInteger nextIndex = [self nextMediaIndex];

            if (nextIndex == -1) {
                _sessionWillRestart = NO;
                [self stopPlayback];
            } else {
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

    if ([self.delegate respondsToSelector:@selector(mediaPlayerStateChanged:isPlaying:currentMediaHasTrackToChooseFrom:currentMediaHasChapters:forPlaybackService:)])
        [self.delegate mediaPlayerStateChanged:currentState
                                     isPlaying:_mediaPlayer.isPlaying
              currentMediaHasTrackToChooseFrom:self.currentMediaHasTrackToChooseFrom
                       currentMediaHasChapters:self.currentMediaHasChapters
                         forPlaybackService:self];

    [self setNeedsMetadataUpdate];
}

#pragma mark - playback controls
- (void)playPause
{
    [_mediaPlayer isPlaying] ? [self pause] : [self play];
}

- (void)play
{
    [_listPlayer play];
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackDidResume object:self];
}

- (void)pause
{
    [_listPlayer pause];
#if TARGET_OS_IOS
    [_delegate savePlaybackState: self];
#endif
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackDidPause object:self];
}

- (void)playItemAtIndex:(NSUInteger)index
{
    VLCMedia *media = [_mediaList mediaAtIndex:index];
    [_listPlayer playItemAtNumber:[NSNumber numberWithUnsignedInteger:index]];
    _mediaPlayer.media = media;
    if ([self.delegate respondsToSelector:@selector(prepareForMediaPlayback:)])
        [self.delegate prepareForMediaPlayback:self];
}

- (void)setShuffleMode:(BOOL)shuffleMode
{
    _shuffleMode = shuffleMode;

    if (_shuffleMode) {
        [_shuffleStack removeAllObjects];
    }
}

- (NSInteger)nextMediaIndex
{
    NSInteger nextIndex = -1;
    NSInteger mediaListCount = _mediaList.count;
    NSUInteger currentIndex = [_mediaList indexOfMedia:_listPlayer.mediaPlayer.media];

    if (self.repeatMode == VLCRepeatCurrentItem) {
        return currentIndex;
    }

    if (_shuffleMode && mediaListCount > 2) {
        //Reached end of playlist
        if (_shuffleStack.count + 1 == mediaListCount) {
            if ([self repeatMode] == VLCDoNotRepeat)
                return -1;
            [_shuffleStack removeAllObjects];
        }

        [_shuffleStack addObject:@(currentIndex)];
        do {
            nextIndex = arc4random_uniform((uint32_t)mediaListCount);
        } while (currentIndex == nextIndex || [_shuffleStack containsObject:@(nextIndex)]);
    } else {
        // Normal playback
        if (currentIndex + 1 < mediaListCount) {
            nextIndex =  currentIndex + 1;
        } else if (self.repeatMode == VLCRepeatAllItems) {
            nextIndex = 0;
        } else if ([self repeatMode] == VLCDoNotRepeat) {
            nextIndex = -1;
        }
    }
    return nextIndex;
}

- (BOOL)next
{
    if (_mediaList.count == 1) {
        NSNumber *skipLength = [[NSUserDefaults standardUserDefaults] valueForKey:kVLCSettingPlaybackForwardSkipLength];
        [_mediaPlayer jumpForward:skipLength.intValue];
        return YES;
    }

    NSInteger nextIndex = [self nextMediaIndex];

    if (nextIndex < 0) {
        if (self.repeatMode == VLCRepeatAllItems) {
#if TARGET_OS_IOS
            [_delegate savePlaybackState:self];
#endif
            [_listPlayer next];
            [[NSNotificationCenter defaultCenter]
             postNotificationName:VLCPlaybackServicePlaybackMetadataDidChange object:self];
        }
        return NO;
    }
#if TARGET_OS_IOS
    [_delegate savePlaybackState:self];
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
            [_delegate savePlaybackState:self];
#endif
            [_listPlayer previous];
            [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackMetadataDidChange object:self];
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
            _mediaPlayer.videoCropGeometry = NULL;
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
            _mediaPlayer.videoCropGeometry = NULL;
            _mediaPlayer.videoAspectRatio = (char *)[[self stringForAspectRatio:_currentAspectRatio] UTF8String];
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
    return -1;
}
#endif

#pragma mark - equalizer

- (void)setAmplification:(CGFloat)amplification forBand:(unsigned int)index
{
    if (!_mediaPlayer.equalizerEnabled)
        [_mediaPlayer setEqualizerEnabled:YES];

    [_mediaPlayer setAmplification:amplification forBand:index];

    // For some reason we have to apply again preamp to apply change
    [_mediaPlayer setPreAmplification:[_mediaPlayer preAmplification]];
}

- (CGFloat)amplificationOfBand:(unsigned int)index
{
    return [_mediaPlayer amplificationOfBand:index];
}

- (NSArray *)equalizerProfiles
{
    return _mediaPlayer.equalizerProfiles;
}

- (void)resetEqualizerFromProfile:(unsigned int)profile
{
    _mediaPlayer.equalizerEnabled = profile != 0;
    [[NSUserDefaults standardUserDefaults] setBool:profile == 0 forKey:kVLCSettingEqualizerProfileDisabled];
    if (profile != 0) {
        [[NSUserDefaults standardUserDefaults] setObject:@(profile - 1) forKey:kVLCSettingEqualizerProfile];
        [_mediaPlayer resetEqualizerFromProfile:profile - 1];
    }
}

- (void)setPreAmplification:(CGFloat)preAmplification
{
    if (!_mediaPlayer.equalizerEnabled)
        [_mediaPlayer setEqualizerEnabled:YES];

    [_mediaPlayer setPreAmplification:preAmplification];
}

- (CGFloat)preAmplification
{
    return [_mediaPlayer preAmplification];
}

- (unsigned int)numberOfBands
{
    return [_mediaPlayer numberOfBands];
}

- (CGFloat)frequencyOfBandAtIndex:(unsigned int)index
{
    return [_mediaPlayer frequencyOfBandAtIndex:index];
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
       [_delegate savePlaybackState: self];
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
    if (_needsMetadataUpdate == NO) {
        _needsMetadataUpdate = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
#if TARGET_OS_IOS
            VLCMLMedia *media = self->_mediaPlayer.media ? [self->_delegate mediaForPlayingMedia:self->_mediaPlayer.media] : nil;
            [self->_metadata updateMetadataFromMedia:media mediaPlayer:self->_mediaPlayer];
#else
            [self->_metadata updateMetadataFromMediaPlayer:self->_mediaPlayer];
#endif
            self->_needsMetadataUpdate = NO;
            [self recoverDisplayedMetadata];
        });
    }
}

#if TARGET_OS_IOS
- (void)_recoverLastPlaybackState
{
    VLCMLMedia *media = [_delegate mediaForPlayingMedia:_mediaPlayer.media];
    if (!media) return;

    CGFloat lastPosition = media.progress;
    // .95 prevents the controller from opening and closing immediatly when restoring state
    //  Additionaly, check if the media is more than 10 sec
    if (lastPosition < .95
        && media.duration > 10000
        && _mediaPlayer.position < lastPosition) {
        NSInteger continuePlayback;
        if (media.type == VLCMLMediaTypeAudio)
            continuePlayback = [[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingContinueAudioPlayback] integerValue];
        else
            continuePlayback = [[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingContinuePlayback] integerValue];

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
    [self restoreAudioAndSubtitleTrack];
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
#if !TARGET_OS_TV
    return (_renderer || [[UIDevice currentDevice] VLCHasExternalDisplay]);
#else
    return [[UIDevice currentDevice] VLCHasExternalDisplay];
#endif
}

#pragma mark - background interaction

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
#if TARGET_OS_IOS
    [_delegate savePlaybackState: self];
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

#if !TARGET_OS_TV
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

#if !TARGET_OS_TV
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

#pragma mark - remoteControlDelegate

- (void)remoteControlServiceHitPause:(VLCRemoteControlService *)rcs
{
    [_listPlayer pause];
}

- (void)remoteControlServiceHitPlay:(VLCRemoteControlService *)rcs
{
    [_listPlayer play];
}

- (void)remoteControlServiceTogglePlayPause:(VLCRemoteControlService *)rcs
{
    [self playPause];
}

- (void)remoteControlServiceHitStop:(VLCRemoteControlService *)rcs
{
    [self stopPlayback];
}

- (BOOL)remoteControlServiceHitPlayNextIfPossible:(VLCRemoteControlService *)rcs
{
    return [self next];
}

- (BOOL)remoteControlServiceHitPlayPreviousIfPossible:(VLCRemoteControlService *)rcs
{
    return [self previous];
}

- (void)remoteControlService:(VLCRemoteControlService *)rcs jumpForwardInSeconds:(NSTimeInterval)seconds
{
    [_mediaPlayer jumpForward:seconds];
}

- (void)remoteControlService:(VLCRemoteControlService *)rcs jumpBackwardInSeconds:(NSTimeInterval)seconds
{
    [_mediaPlayer jumpBackward:seconds];
}

- (NSInteger)remoteControlServiceNumberOfMediaItemsinList:(VLCRemoteControlService *)rcs
{
    return _mediaList.count;
}

- (void)remoteControlService:(VLCRemoteControlService *)rcs setPlaybackRate:(CGFloat)playbackRate
{
    self.playbackRate = playbackRate;
}

- (void)remoteControlService:(VLCRemoteControlService *)rcs setCurrentPlaybackTime:(NSTimeInterval)playbackTime
{
    float positionDiff = playbackTime - [self.metadata.elapsedPlaybackTime floatValue];
    [_mediaPlayer jumpForward:positionDiff];
    _majorPositionChangeInProgress = 1;
}

#pragma mark - helpers

- (NSDictionary *)mediaOptionsDictionary
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return @{ kVLCSettingNetworkCaching : [defaults objectForKey:kVLCSettingNetworkCaching],
              kVLCSettingStretchAudio : [[defaults objectForKey:kVLCSettingStretchAudio] boolValue] ? kVLCSettingStretchAudioOnValue : kVLCSettingStretchAudioOffValue,
              kVLCSettingTextEncoding : [defaults objectForKey:kVLCSettingTextEncoding],
              kVLCSettingSkipLoopFilter : [defaults objectForKey:kVLCSettingSkipLoopFilter],
              kVLCSettingHardwareDecoding : [defaults objectForKey:kVLCSettingHardwareDecoding],
              kVLCSettingNetworkRTSPTCP : [defaults objectForKey:kVLCSettingNetworkRTSPTCP]
    };
}

#pragma mark - Renderer

#if !TARGET_OS_TV

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
    if ([_delegate respondsToSelector:@selector(playbackService:nextMedia:)]) {
        [_delegate playbackService:self nextMedia:media];
    }
}

@end
