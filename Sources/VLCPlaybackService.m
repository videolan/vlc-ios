/*****************************************************************************
 * VLCPlaybackService.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Carola Nitz <caro # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Sylver Bruneau <sylver.bruneau # gmail dot com>
 *          Winston Weinert <winston # ml1 dot net>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackService.h"
#import "UIDevice+VLC.h"
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

@interface VLCPlaybackService () <VLCMediaPlayerDelegate, VLCMediaDelegate, VLCRemoteControlServiceDelegate>
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
    BOOL _recheckForExistingThumbnail;
    BOOL _externalAudioPlaybackDeviceConnected;

    NSLock *_playbackSessionManagementLock;

    NSMutableArray *_shuffleStack;
    void (^_playbackCompletion)(BOOL success);

    VLCDialogProvider *_dialogProvider;
    VLCCustomDialogRendererHandler *_customDialogHandler;
    VLCPlayerDisplayController *_playerDisplayController;
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

    _listPlayer = [[VLCMediaListPlayer alloc] initWithDrawable:_actualVideoOutputView];

    /* to enable debug logging for the playback library instance, switch the boolean below
     * note that the library instance used for playback may not necessarily match the instance
     * used for media discovery or thumbnailing */
    _listPlayer.mediaPlayer.libraryInstance.debugLogging = NO;

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

    [_mediaPlayer setRendererItem:_renderer];

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
        _mediaPlayer = nil;
        _listPlayer = nil;
    }
    if (!_sessionWillRestart) {
        _mediaList = nil;
    }
    _playerIsSetup = NO;
    [_shuffleStack removeAllObjects];

    if (_playbackCompletion) {
        BOOL finishedPlaybackWithError = _mediaPlayer.state == VLCMediaPlayerStateError &&  !_sessionWillRestart;
        _playbackCompletion(!finishedPlaybackWithError);
    }

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
    return [[_mediaPlayer audioTrackIndexes] count] > 2 || [[_mediaPlayer videoSubTitlesIndexes] count] > 1;
}

- (BOOL) isSeekable
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
}

- (void)setSubtitleDelay:(float)subtitleDeleay
{
    _mediaPlayer.currentVideoSubTitleDelay = 1000.*subtitleDeleay;
}

- (float)subtitleDelay
{
    return _mediaPlayer.currentVideoSubTitleDelay/1000.;
}

- (float)hue
{
    return _mediaPlayer.hue;
}

- (void)setHue:(float)hue
{
    _mediaPlayer.hue = hue;
}

- (float)contrast
{
    return _mediaPlayer.contrast;
}

- (void)setContrast:(float)contrast
{
    _mediaPlayer.contrast = contrast;
}

- (float)brightness
{
    return _mediaPlayer.brightness;
}

- (void)setBrightness:(float)brightness
{
    _mediaPlayer.brightness = brightness;
}

- (float)saturation
{
    return _mediaPlayer.saturation;
}

- (void)setSaturation:(float)saturation
{
    _mediaPlayer.saturation = saturation;
}

- (void)setGamma:(float)gamma
{
    _mediaPlayer.gamma = gamma;
}

- (float)gamma
{
    return _mediaPlayer.gamma;
}

- (void)resetFilters
{
    _mediaPlayer.hue = 0.;
    _mediaPlayer.contrast = 1.;
    _mediaPlayer.brightness = 1.;
    _mediaPlayer.saturation = 1.;
    _mediaPlayer.gamma = 1.;
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
    return _mediaPlayer.audioTrackIndexes.count;
}

- (NSInteger)numberOfVideoSubtitlesIndexes
{
    return _mediaPlayer.videoSubTitlesIndexes.count;
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
    if (index >= 0 && index < _mediaPlayer.videoSubTitlesNames.count)
        return _mediaPlayer.videoSubTitlesNames[index];
    return nil;
}

- (NSString *)audioTrackNameAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _mediaPlayer.audioTrackNames.count)
        return _mediaPlayer.audioTrackNames[index];
    return nil;
}

- (NSDictionary *)titleDescriptionsDictAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _mediaPlayer.titleDescriptions.count)
        return _mediaPlayer.titleDescriptions[index];
    return nil;
}

- (NSDictionary *)chapterDescriptionsDictAtIndex:(NSInteger)index
{
    NSArray *chapterDescriptions = [_mediaPlayer chapterDescriptionsOfTitle:_mediaPlayer.currentTitleIndex];
    if (index >= 0 && index < chapterDescriptions.count)
        return chapterDescriptions[index];
    return nil;
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

- (void)next
{
    if (_mediaList.count == 1) {
        NSNumber *skipLength = [[NSUserDefaults standardUserDefaults] valueForKey:kVLCSettingPlaybackForwardSkipLength];
        [_mediaPlayer jumpForward:skipLength.intValue];
        return;
    }

    NSInteger nextIndex = [self nextMediaIndex];

    if (nextIndex < 0) {
        if (self.repeatMode == VLCRepeatAllItems) {
            [_listPlayer next];
            [[NSNotificationCenter defaultCenter]
             postNotificationName:VLCPlaybackServicePlaybackMetadataDidChange object:self];
        }
        return;
    }

    [_listPlayer playItemAtNumber:@(nextIndex)];
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackMetadataDidChange object:self];
}

- (void)previous
{
    if (_mediaList.count > 1) {
        [_listPlayer previous];
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackMetadataDidChange object:self];
    }
    else {
        NSNumber *skipLength = [[NSUserDefaults standardUserDefaults] valueForKey:kVLCSettingPlaybackBackwardSkipLength];
        [_mediaPlayer jumpBackward:skipLength.intValue];
    }
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
    return (_renderer || [[UIDevice currentDevice] VLCHasExternalDisplay]);
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

    if (!_renderer && _mediaPlayer.audioTrackIndexes.count > 0 && [_mediaPlayer isPlaying])
        [self setVideoTrackEnabled:false];

    if (_renderer) {
        [_backgroundDummyPlayer play];
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    if (_preBackgroundWrapperView) {
        [self setVideoOutputView:_preBackgroundWrapperView];
        _preBackgroundWrapperView = nil;
    }

    if (_renderer) {
        [_backgroundDummyPlayer stop];
    }

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
    //TODO handle stop playback entirely
    [_listPlayer stop];
}

- (BOOL)remoteControlServiceHitPlayNextIfPossible:(VLCRemoteControlService *)rcs
{
    //TODO This doesn't handle shuffle or repeat yet
    return [_listPlayer next];
}

- (BOOL)remoteControlServiceHitPlayPreviousIfPossible:(VLCRemoteControlService *)rcs
{
    //TODO This doesn't handle shuffle or repeat yet
    return [_listPlayer previous];
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
              kVLCForceSMBV1 : [NSNull null]
    };
}

#pragma mark - Renderer
- (void)setRenderer:(VLCRendererItem * __nullable)renderer
{
    _renderer = renderer;
    [_mediaPlayer setRendererItem:_renderer];
}


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

@end
