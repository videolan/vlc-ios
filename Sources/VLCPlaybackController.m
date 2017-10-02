/*****************************************************************************
 * VLCPlaybackController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
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

#import "VLCPlaybackController.h"
#import <CommonCrypto/CommonDigest.h>
#import "UIDevice+VLC.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "VLCPlayerDisplayController.h"
#import "VLCConstants.h"

#if TARGET_OS_IOS
#import "VLCKeychainCoordinator.h"
#import "VLCThumbnailsCache.h"
#import "VLCLibraryViewController.h"
#import <WatchKit/WatchKit.h>
#endif

NSString *const VLCPlaybackControllerPlaybackDidStart = @"VLCPlaybackControllerPlaybackDidStart";
NSString *const VLCPlaybackControllerPlaybackDidPause = @"VLCPlaybackControllerPlaybackDidPause";
NSString *const VLCPlaybackControllerPlaybackDidResume = @"VLCPlaybackControllerPlaybackDidResume";
NSString *const VLCPlaybackControllerPlaybackDidStop = @"VLCPlaybackControllerPlaybackDidStop";
NSString *const VLCPlaybackControllerPlaybackMetadataDidChange = @"VLCPlaybackControllerPlaybackMetadataDidChange";
NSString *const VLCPlaybackControllerPlaybackDidFail = @"VLCPlaybackControllerPlaybackDidFail";
NSString *const VLCPlaybackControllerPlaybackPositionUpdated = @"VLCPlaybackControllerPlaybackPositionUpdated";

typedef NS_ENUM(NSUInteger, VLCAspectRatio) {
    VLCAspectRatioDefault = 0,
    VLCAspectRatioFillToScreen,
    VLCAspectRatioFourToThree,
    VLCAspectRatioSixteenToNine,
    VLCAspectRatioSixteenToTen,
};

@interface VLCPlaybackController () <VLCMediaPlayerDelegate, VLCMediaDelegate>
{
    BOOL _playerIsSetup;
    BOOL _shouldResumePlaying;
    NSTimer *_sleepTimer;

    NSUInteger _currentAspectRatio;

    float _currentPlaybackRate;
    UIView *_videoOutputViewWrapper;
    UIView *_actualVideoOutputView;
    UIView *_preBackgroundWrapperView;

    /* cached stuff for the VC */
    NSString *_title;
    UIImage *_artworkImage;
    NSString *_artist;
    NSString *_albumName;
    BOOL _mediaIsAudioOnly;

    BOOL _needsMetadataUpdate;
    BOOL _mediaWasJustStarted;
    BOOL _recheckForExistingThumbnail;
    BOOL _activeSession;
    BOOL _headphonesWasPlugged;

    NSLock *_playbackSessionManagementLock;

    VLCDialogProvider *_dialogProvider;

    NSMutableArray *_shuffleStack;
}

@end

@implementation VLCPlaybackController

#pragma mark instance management

+ (VLCPlaybackController *)sharedInstance
{
    static VLCPlaybackController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [VLCPlaybackController new];
    });

    return sharedInstance;
}

- (void)dealloc
{
    _dialogProvider = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _headphonesWasPlugged = [self areHeadphonesPlugged];
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self selector:@selector(audioSessionRouteChange:)
                              name:AVAudioSessionRouteChangeNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(handleInterruption:)
                              name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
        [defaultCenter addObserver:self selector:@selector(applicationWillResignActive:)
                              name:UIApplicationWillResignActiveNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive:)
                              name:UIApplicationDidBecomeActiveNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground:)
                              name:UIApplicationDidEnterBackgroundNotification object:nil];

        _dialogProvider = [[VLCDialogProvider alloc] initWithLibrary:[VLCLibrary sharedLibrary] customUI:NO];

        _playbackSessionManagementLock = [[NSLock alloc] init];
        _shuffleMode = NO;
        _shuffleStack = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - playback management

- (BOOL)_isMediaSuitableForDevice:(VLCMedia *)media
{
    NSArray *tracksInfo = media.tracksInformation;
    double width = 0.0, height = 0.0;
    NSDictionary *track;

    for (NSUInteger x = 0; x < tracksInfo.count; x++) {
        track = tracksInfo[x];
        if ([track[VLCMediaTracksInformationType] isEqualToString:VLCMediaTracksInformationTypeVideo]) {
            width = [track[VLCMediaTracksInformationVideoWidth] doubleValue];
            height = [track[VLCMediaTracksInformationVideoHeight] doubleValue];
        }
    }

    NSUInteger totalNumberOfPixels = width * height;

    NSInteger speedCategory = [[UIDevice currentDevice] VLCSpeedCategory];

    if (speedCategory == 1) {
        // iPhone 3GS, iPhone 4, first gen. iPad, 3rd and 4th generation iPod touch
        return (totalNumberOfPixels < 600000); // between 480p and 720p
    } else if (speedCategory == 2) {
        // iPhone 4S, iPad 2 and 3, iPod 4 and 5
        return (totalNumberOfPixels < 922000); // 720p
    } else if (speedCategory == 3) {
        // iPhone 5, iPad 4
        return (totalNumberOfPixels < 2074000); // 1080p
    } else if (speedCategory == 4) {
        // iPhone 6, 2014 iPads
        return (totalNumberOfPixels < 8850000); // 4K
    }

    return YES;
}

- (void)playMediaList:(VLCMediaList *)mediaList firstIndex:(NSInteger)index
{
    self.mediaList = mediaList;
    self.itemInMediaListToBePlayedFirst = (int)index;
    self.pathToExternalSubtitlesFile = nil;

    if (self.activePlaybackSession) {
        self.sessionWillRestart = YES;
        [self stopPlayback];
    } else {
        self.sessionWillRestart = NO;
        [self startPlayback];
    }
}

- (void)playURL:(NSURL *)url successCallback:(NSURL*)successCallback errorCallback:(NSURL *)errorCallback
{
    self.url = url;
    self.successCallback = successCallback;
    self.errorCallback = errorCallback;

    if (self.activePlaybackSession) {
        self.sessionWillRestart = YES;
        [self stopPlayback];
    } else {
        self.sessionWillRestart = NO;
        [self startPlayback];
    }
}

- (void)playURL:(NSURL *)url subtitlesFilePath:(NSString *)subsFilePath
{
    self.url = url;
    self.pathToExternalSubtitlesFile = subsFilePath;

    if (self.activePlaybackSession) {
        self.sessionWillRestart = YES;
        [self stopPlayback];
    } else {
        self.sessionWillRestart = NO;
        [self startPlayback];
    }
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

    _activeSession = YES;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (!self.url && !self.mediaList) {
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

    if (self.pathToExternalSubtitlesFile)
        _listPlayer = [[VLCMediaListPlayer alloc] initWithOptions:@[[NSString stringWithFormat:@"--%@=%@", kVLCSettingSubtitlesFilePath, self.pathToExternalSubtitlesFile]] andDrawable:_actualVideoOutputView];
    else
        _listPlayer = [[VLCMediaListPlayer alloc] initWithDrawable:_actualVideoOutputView];

    /* to enable debug logging for the playback library instance, switch the boolean below
     * note that the library instance used for playback may not necessarily match the instance
     * used for media discovery or thumbnailing */
    _listPlayer.mediaPlayer.libraryInstance.debugLogging = NO;

    _mediaPlayer = _listPlayer.mediaPlayer;
    [_mediaPlayer setDelegate:self];
    if ([[defaults objectForKey:kVLCSettingPlaybackSpeedDefaultValue] floatValue] != 0)
        [_mediaPlayer setRate: [[defaults objectForKey:kVLCSettingPlaybackSpeedDefaultValue] floatValue]];
    if ([[defaults objectForKey:kVLCSettingDeinterlace] intValue] != 0)
        [_mediaPlayer setDeinterlaceFilter:@"blend"];
    else
        [_mediaPlayer setDeinterlaceFilter:nil];
    if (self.pathToExternalSubtitlesFile)
        [_mediaPlayer addPlaybackSlave:[NSURL fileURLWithPath:self.pathToExternalSubtitlesFile] type:VLCMediaPlaybackSlaveTypeSubtitle enforce:YES];

    VLCMedia *media;
    if (_mediaList) {
        media = [_mediaList mediaAtIndex:_itemInMediaListToBePlayedFirst];
        [media parseWithOptions:VLCMediaParseLocal];
        media.delegate = self;
    } else {
        media = [VLCMedia mediaWithURL:self.url];
        media.delegate = self;
        [media parseWithOptions:VLCMediaParseLocal];
        [media addOptions:self.mediaOptionsDictionary];
    }

    if (self.mediaList) {
        [_listPlayer setMediaList:self.mediaList];
    } else {
        [_listPlayer setRootMedia:media];
    }
    [_listPlayer setRepeatMode:VLCDoNotRepeat];

    [_playbackSessionManagementLock unlock];

    if (![self _isMediaSuitableForDevice:media]) {
#if TARGET_OS_IOS
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DEVICE_TOOSLOW_TITLE", nil)
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"DEVICE_TOOSLOW", nil), [[UIDevice currentDevice] model], media.url.lastPathComponent]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                otherButtonTitles:NSLocalizedString(@"BUTTON_OPEN", nil), nil];
        [alert show];
#else
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DEVICE_TOOSLOW_TITLE", nil)
                                                                       message:[NSString stringWithFormat:NSLocalizedString(@"DEVICE_TOOSLOW", nil), [[UIDevice currentDevice] model], media.url.lastPathComponent]
                                                                preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OPEN", nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                      [self _playNewMedia];
                                                              }];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                               style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction * action) {
                                                                [self stopPlayback];
                                                            }];
        [alert addAction:defaultAction];
        [alert addAction:cancelAction];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
#endif
    } else
        [self _playNewMedia];
}

- (void)_playNewMedia
{
    BOOL ret = [_playbackSessionManagementLock tryLock];
    if (!ret) {
        APLog(@"%s: locking failed", __PRETTY_FUNCTION__);
        return;
    }

    // Set last selected equalizer profile
    unsigned int profile = (unsigned int)[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingEqualizerProfile] integerValue];
    [_mediaPlayer resetEqualizerFromProfile:profile];
    [_mediaPlayer setPreAmplification:[_mediaPlayer preAmplification]];

    _mediaWasJustStarted = YES;

    [_mediaPlayer addObserver:self forKeyPath:@"time" options:0 context:nil];
    [_mediaPlayer addObserver:self forKeyPath:@"remainingTime" options:0 context:nil];

    if (self.mediaList)
        [_listPlayer playItemAtNumber:@(self.itemInMediaListToBePlayedFirst)];
    else
        [_listPlayer playMedia:_listPlayer.rootMedia];

    if ([self.delegate respondsToSelector:@selector(prepareForMediaPlayback:)])
        [self.delegate prepareForMediaPlayback:self];

    _currentAspectRatio = VLCAspectRatioDefault;
    _mediaPlayer.videoAspectRatio = NULL;
    _mediaPlayer.videoCropGeometry = NULL;

    [self subscribeRemoteCommands];

    _playerIsSetup = YES;

    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackDidStart object:self];
    [_playbackSessionManagementLock unlock];
}

#if TARGET_OS_IOS
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [self _playNewMedia];
    else
        [self stopPlayback];
}
#endif

- (void)stopPlayback
{
    BOOL ret = [_playbackSessionManagementLock tryLock];
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
            [self _savePlaybackState];
#endif
            [_mediaPlayer stop];
        }
        if (_mediaPlayer)
            _mediaPlayer = nil;
        if (_listPlayer)
            _listPlayer = nil;
    }
    if (!_sessionWillRestart) {
        if (_mediaList)
            _mediaList = nil;
        if (_url)
            _url = nil;
        if (_pathToExternalSubtitlesFile) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:_pathToExternalSubtitlesFile])
                [fileManager removeItemAtPath:_pathToExternalSubtitlesFile error:nil];
            _pathToExternalSubtitlesFile = nil;
        }
    }
    _playerIsSetup = NO;
    [_shuffleStack removeAllObjects];

    if (self.errorCallback && _mediaPlayer.state == VLCMediaPlayerStateError && !_sessionWillRestart)
        [[UIApplication sharedApplication] openURL:self.errorCallback];
    else if (self.successCallback && !_sessionWillRestart)
        [[UIApplication sharedApplication] openURL:self.successCallback];

    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
    [self unsubscribeFromRemoteCommand];
    _activeSession = NO;

    [_playbackSessionManagementLock unlock];
    if (!_sessionWillRestart) {
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackDidStop object:self];
    } else {
        self.sessionWillRestart = NO;
        [self startPlayback];
    }
}

#if TARGET_OS_IOS
- (void)_savePlaybackState
{
    @try {
        [[MLMediaLibrary sharedMediaLibrary] save];
    }
    @catch (NSException *exception) {
        APLog(@"saving playback state failed");
    }

    MLFile *fileItem;
    NSArray *files = [MLFile fileForURL:_mediaPlayer.media.url];
    if (files.count > 0)
        fileItem = files.firstObject;

    if (!fileItem) {
        APLog(@"couldn't find file, not saving playback progress");
        return;
    }

    @try {
        float position = _mediaPlayer.position;
        fileItem.lastPosition = @(position);
        fileItem.lastAudioTrack = @(_mediaPlayer.currentAudioTrackIndex);
        fileItem.lastSubtitleTrack = @(_mediaPlayer.currentVideoSubTitleIndex);

        if (position > .95)
            return;

        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString* newThumbnailPath = [searchPaths[0] stringByAppendingPathComponent:@"VideoSnapshots"];
        NSFileManager *fileManager = [NSFileManager defaultManager];

        if (![fileManager fileExistsAtPath:newThumbnailPath])
            [fileManager createDirectoryAtPath:newThumbnailPath withIntermediateDirectories:YES attributes:nil error:nil];

        newThumbnailPath = [newThumbnailPath stringByAppendingPathComponent:fileItem.objectID.URIRepresentation.lastPathComponent];
        [_mediaPlayer saveVideoSnapshotAt:newThumbnailPath withWidth:0 andHeight:0];

        _recheckForExistingThumbnail = YES;
        [self performSelector:@selector(_updateStoredThumbnailForFile:) withObject:fileItem afterDelay:.25];
    }
    @catch (NSException *exception) {
        APLog(@"failed to save current media state - file removed?");
    }
}
#endif

#if TARGET_OS_IOS
- (void)_updateStoredThumbnailForFile:(MLFile *)fileItem
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* newThumbnailPath = [searchPaths[0] stringByAppendingPathComponent:@"VideoSnapshots"];
    newThumbnailPath = [newThumbnailPath stringByAppendingPathComponent:fileItem.objectID.URIRepresentation.lastPathComponent];

    if (![fileManager fileExistsAtPath:newThumbnailPath]) {
        if (_recheckForExistingThumbnail) {
            [self performSelector:@selector(_updateStoredThumbnailForFile:) withObject:fileItem afterDelay:1.];
            _recheckForExistingThumbnail = NO;
        } else
            return;
    }

    UIImage *newThumbnail = [UIImage imageWithContentsOfFile:newThumbnailPath];
    if (!newThumbnail) {
        if (_recheckForExistingThumbnail) {
            [self performSelector:@selector(_updateStoredThumbnailForFile:) withObject:fileItem afterDelay:1.];
            _recheckForExistingThumbnail = NO;
        } else
            return;
    }

    @try {
        [fileItem setComputedThumbnailScaledForDevice:newThumbnail];
    }
    @catch (NSException *exception) {
        APLog(@"updating thumbnail failed");
    }

    [fileManager removeItemAtPath:newThumbnailPath error:nil];
}
#endif

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (_mediaWasJustStarted) {
        _mediaWasJustStarted = NO;
#if TARGET_OS_IOS
        if (self.mediaList) {
            MLFile *item;
            NSArray *matches = [MLFile fileForURL:_mediaPlayer.media.url];
            item = matches.firstObject;
            [self _recoverLastPlaybackStateOfItem:item];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackPositionUpdated
                                                        object:self];
}

- (NSInteger)mediaDuration
{
    return _listPlayer.mediaPlayer.media.length.intValue;;
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
}

- (BOOL)currentMediaHasChapters
{
    return [_mediaPlayer numberOfTitles] > 1 || [_mediaPlayer numberOfChaptersForTitle:_mediaPlayer.currentTitleIndex] > 1;
}

- (BOOL)currentMediaHasTrackToChooseFrom
{
    return [[_mediaPlayer audioTrackIndexes] count] > 2 || [[_mediaPlayer videoSubTitlesIndexes] count] > 1;
}

- (BOOL)activePlaybackSession
{
    return _activeSession;
}

- (BOOL)audioOnlyPlaybackSession
{
    return _mediaIsAudioOnly;
}

- (NSString *)mediaTitle
{
    return _title;
}

- (float)playbackRate
{
    float f_rate = _mediaPlayer.rate;
    _currentPlaybackRate = f_rate;
    return f_rate;
}

- (void)setPlaybackRate:(float)playbackRate
{
    if (_currentPlaybackRate != playbackRate)
        [_mediaPlayer setRate:playbackRate];
    _currentPlaybackRate = playbackRate;
}

- (void)setAudioDelay:(float)audioDelay
{
    _mediaPlayer.currentAudioPlaybackDelay = 1000000.*audioDelay;
}
- (float)audioDelay
{
    return _mediaPlayer.currentAudioPlaybackDelay/1000000.;
}
-(void)setSubtitleDelay:(float)subtitleDeleay
{
    _mediaPlayer.currentVideoSubTitleDelay = 1000000.*subtitleDeleay;
}
- (float)subtitleDelay
{
    return _mediaPlayer.currentVideoSubTitleDelay/1000000.;
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    VLCMediaPlayerState currentState = _mediaPlayer.state;

    if (currentState == VLCMediaPlayerStateBuffering) {
        /* attach delegate */
        _mediaPlayer.media.delegate = self;

        /* on-the-fly values through hidden API */
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [_mediaPlayer performSelector:@selector(setTextRendererFont:) withObject:[defaults objectForKey:kVLCSettingSubtitlesFont]];
        [_mediaPlayer performSelector:@selector(setTextRendererFontSize:) withObject:[defaults objectForKey:kVLCSettingSubtitlesFontSize]];
        [_mediaPlayer performSelector:@selector(setTextRendererFontColor:) withObject:[defaults objectForKey:kVLCSettingSubtitlesFontColor]];
        [_mediaPlayer performSelector:@selector(setTextRendererFontForceBold:) withObject:[defaults objectForKey:kVLCSettingSubtitlesBoldFont]];
    } else if (currentState == VLCMediaPlayerStateError) {
        APLog(@"Playback failed");
        dispatch_async(dispatch_get_main_queue(),^{
            [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackDidFail object:self];
        });
        self.sessionWillRestart = NO;
        [self stopPlayback];
    } else if (currentState == VLCMediaPlayerStateEnded || currentState == VLCMediaPlayerStateStopped) {
        [_listPlayer.mediaList lock];
        NSUInteger listCount = _listPlayer.mediaList.count;
        if ([_listPlayer.mediaList indexOfMedia:_mediaPlayer.media] == listCount - 1 && self.repeatMode == VLCDoNotRepeat) {
            [_listPlayer.mediaList unlock];
            self.sessionWillRestart = NO;
            [self stopPlayback];
            return;
        } else if (listCount > 1) {
            [_listPlayer.mediaList unlock];
            [_listPlayer next];
        } else
            [_listPlayer.mediaList unlock];
    }

    if ([self.delegate respondsToSelector:@selector(mediaPlayerStateChanged:isPlaying:currentMediaHasTrackToChooseFrom:currentMediaHasChapters:forPlaybackController:)])
        [self.delegate mediaPlayerStateChanged:currentState
                                     isPlaying:_mediaPlayer.isPlaying
              currentMediaHasTrackToChooseFrom:self.currentMediaHasTrackToChooseFrom
                       currentMediaHasChapters:self.currentMediaHasChapters
                         forPlaybackController:self];

    [self setNeedsMetadataUpdate];
}

#pragma mark - playback controls
- (void)playPause
{
    if ([_mediaPlayer isPlaying]) {
        [_listPlayer pause];
#if TARGET_OS_IOS
        [self _savePlaybackState];
#endif
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackDidPause object:self];
    } else {
        [_listPlayer play];
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackDidResume object:self];
    }
}

- (void)forward
{
    NSInteger mediaListCount = _mediaList.count;

#if TARGET_OS_IOS
    if (self.repeatMode != VLCRepeatCurrentItem && mediaListCount > 2 && _shuffleMode) {

        NSNumber *nextIndex;
        NSUInteger currentIndex = [_mediaList indexOfMedia:_listPlayer.mediaPlayer.media];

        //Reached end of playlist
        if (_shuffleStack.count + 1 == mediaListCount) {
            if ([self repeatMode] == VLCDoNotRepeat)
                return;
            [_shuffleStack removeAllObjects];
        }

        [_shuffleStack addObject:[NSNumber numberWithUnsignedInteger:currentIndex]];
        do {
            nextIndex = [NSNumber numberWithUnsignedInt:arc4random_uniform((uint32_t)mediaListCount)];
        } while (currentIndex == nextIndex.unsignedIntegerValue || [_shuffleStack containsObject:nextIndex]);

        [_listPlayer playItemAtNumber:[NSNumber numberWithUnsignedInteger:nextIndex.unsignedIntegerValue]];
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackMetadataDidChange object:self];

        return;
    }
#endif

    if (mediaListCount > 1) {
        [_listPlayer next];
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackMetadataDidChange object:self];
    } else {
        NSNumber *skipLength = [[NSUserDefaults standardUserDefaults] valueForKey:kVLCSettingPlaybackForwardSkipLength];
        [_mediaPlayer jumpForward:skipLength.intValue];
    }
}

- (void)backward
{
    if (_mediaList.count > 1) {
        [_listPlayer previous];
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackMetadataDidChange object:self];
    }
    else {
        NSNumber *skipLength = [[NSUserDefaults standardUserDefaults] valueForKey:kVLCSettingPlaybackBackwardSkipLength];
        [_mediaPlayer jumpBackward:skipLength.intValue];
    }
}

- (NSString *)screenAspectRatio
{
    UIScreen *screen = [[UIDevice currentDevice] VLCHasExternalDisplay] ? [UIScreen screens][1] : [UIScreen mainScreen];
    return [NSString stringWithFormat:@"%d:%d", (int)screen.bounds.size.width, (int)screen.bounds.size.height];
}

- (void)switchIPhoneXFullScreen
{
    BOOL inFullScreen = _mediaPlayer.videoCropGeometry && [[NSString stringWithUTF8String:_mediaPlayer.videoCropGeometry] isEqualToString:[self screenAspectRatio]];
    if (inFullScreen) {
        const char *previousAspectRatio = _currentAspectRatio == VLCAspectRatioDefault ? NULL : [[self stringForAspectRatio:_currentAspectRatio] UTF8String];
        _mediaPlayer.videoAspectRatio = (char *)previousAspectRatio;
    }
    _mediaPlayer.videoCropGeometry = inFullScreen ? NULL : (char *)[[self screenAspectRatio] UTF8String];
}

- (void)switchAspectRatio
{
    _currentAspectRatio = _currentAspectRatio == VLCAspectRatioSixteenToTen ? VLCAspectRatioDefault : _currentAspectRatio + 1;
    switch (_currentAspectRatio) {
        case VLCAspectRatioDefault:
            _mediaPlayer.videoAspectRatio = NULL;
            _mediaPlayer.videoCropGeometry = NULL;
            break;
        case VLCAspectRatioFillToScreen:
            _mediaPlayer.videoCropGeometry = (char *)[[self screenAspectRatio] UTF8String];
            break;
        case VLCAspectRatioFourToThree:
        case VLCAspectRatioSixteenToTen:
        case VLCAspectRatioSixteenToNine:
            _mediaPlayer.videoCropGeometry = NULL;
            _mediaPlayer.videoAspectRatio = (char *)[[self stringForAspectRatio:_currentAspectRatio] UTF8String];
    }

    if ([self.delegate respondsToSelector:@selector(showStatusMessage:forPlaybackController:)]) {
        [self.delegate showStatusMessage:[NSString stringWithFormat:NSLocalizedString(@"AR_CHANGED", nil), [self stringForAspectRatio:_currentAspectRatio]] forPlaybackController:self];
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
    return [_mediaPlayer updateViewpoint:yaw pitch:pitch roll:roll fov:fov absolute:absolute];
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
    [[NSUserDefaults standardUserDefaults] setObject:@(profile) forKey:kVLCSettingEqualizerProfile];
    [_mediaPlayer resetEqualizerFromProfile:profile];
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

- (BOOL)areHeadphonesPlugged
{
    NSArray *outputs = [[AVAudioSession sharedInstance] currentRoute].outputs;
    NSString *portName = [[outputs firstObject] portName];
    return [portName isEqualToString:@"Headphones"];
}

- (void)audioSessionRouteChange:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSInteger routeChangeReason = [[userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];

    if (routeChangeReason == AVAudioSessionRouteChangeReasonRouteConfigurationChange)
        return;

    BOOL headphonesPlugged = [self areHeadphonesPlugged];

    if (_headphonesWasPlugged && !headphonesPlugged && [_mediaPlayer isPlaying]) {
        [_mediaPlayer pause];
#if TARGET_OS_IOS
        [self _savePlaybackState];
#endif
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackDidPause object:self];
    }
    _headphonesWasPlugged = headphonesPlugged;
}

#pragma mark - Managing the media item

#if TARGET_OS_IOS
- (MLFile *)currentlyPlayingMediaFile {
    if (self.mediaList) {
        NSArray *results = [MLFile fileForURL:_mediaPlayer.media.url];
        return results.firstObject;
    }

    return nil;
}
#endif

#pragma mark - metadata handling
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
            [self _updateDisplayedMetadata];
        });
    }
}

- (void)_updateDisplayedMetadata
{
    _needsMetadataUpdate = NO;

    NSNumber *trackNumber;

    NSString *title;
    NSString *artist;
    NSString *albumName;
    UIImage* artworkImage;
    BOOL mediaIsAudioOnly = NO;

#if TARGET_OS_IOS
    MLFile *item;

    if (self.mediaList) {
        NSArray *matches = [MLFile fileForURL:_mediaPlayer.media.url];
        item = matches.firstObject;
    }

    if (item) {
        if (item.isAlbumTrack) {
            title = item.albumTrack.title;
            artist = item.albumTrack.artist;
            albumName = item.albumTrack.album.name;
        } else
            title = item.title;

        /* MLKit knows better than us if this thing is audio only or not */
        mediaIsAudioOnly = [item isSupportedAudioFile];
    } else {
#endif
        NSDictionary * metaDict = _mediaPlayer.media.metaDictionary;

        if (metaDict) {
            title = metaDict[VLCMetaInformationNowPlaying] ? metaDict[VLCMetaInformationNowPlaying] : metaDict[VLCMetaInformationTitle];
            artist = metaDict[VLCMetaInformationArtist];
            albumName = metaDict[VLCMetaInformationAlbum];
            trackNumber = metaDict[VLCMetaInformationTrackNumber];
        }
#if TARGET_OS_IOS
    }
#endif

    if (!mediaIsAudioOnly) {
        /* either what we are playing is not a file known to MLKit or
         * MLKit fails to acknowledge that it is audio-only.
         * Either way, do a more expensive check to see if it is really audio-only */
        NSArray *tracks = _mediaPlayer.media.tracksInformation;
        NSUInteger trackCount = tracks.count;
        mediaIsAudioOnly = YES;
        for (NSUInteger x = 0 ; x < trackCount; x++) {
            if ([[tracks[x] objectForKey:VLCMediaTracksInformationType] isEqualToString:VLCMediaTracksInformationTypeVideo]) {
                mediaIsAudioOnly = NO;
                break;
            }
        }
    }

    if (mediaIsAudioOnly) {
#if TARGET_OS_IOS
        artworkImage = [VLCThumbnailsCache thumbnailForManagedObject:item];

        if (artworkImage) {
            if (artist)
                title = [title stringByAppendingFormat:@" — %@", artist];
            if (albumName)
                title = [title stringByAppendingFormat:@" — %@", albumName];
        }
#endif

        if (title.length < 1)
            title = [[_mediaPlayer.media url] lastPathComponent];
    }

    /* populate delegate with metadata info */
    if ([self.delegate respondsToSelector:@selector(displayMetadataForPlaybackController:title:artwork:artist:album:audioOnly:)])
        [self.delegate displayMetadataForPlaybackController:self
                                                      title:title
                                                    artwork:artworkImage
                                                     artist:artist
                                                      album:albumName
                                                  audioOnly:mediaIsAudioOnly];

    /* populate now playing info center with metadata information */
    NSMutableDictionary *currentlyPlayingTrackInfo = [NSMutableDictionary dictionary];
    currentlyPlayingTrackInfo[MPMediaItemPropertyPlaybackDuration] = @(_mediaPlayer.media.length.intValue / 1000.);
    currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] =  @(_mediaPlayer.time.intValue / 1000.);
    currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyPlaybackRate] = @(_mediaPlayer.isPlaying ? _mediaPlayer.rate : 0.0);

    /* don't leak sensitive information to the OS, if passcode lock is enabled */
#if TARGET_OS_IOS
    if (![[VLCKeychainCoordinator defaultCoordinator] passcodeLockEnabled]) {
#endif
        if (title)
            currentlyPlayingTrackInfo[MPMediaItemPropertyTitle] = title;
        if (artist.length > 0)
            currentlyPlayingTrackInfo[MPMediaItemPropertyArtist] = artist;
        if (albumName.length > 0)
            currentlyPlayingTrackInfo[MPMediaItemPropertyAlbumTitle] = albumName;

        if ([trackNumber intValue] > 0)
            currentlyPlayingTrackInfo[MPMediaItemPropertyAlbumTrackNumber] = trackNumber;

#if TARGET_OS_IOS
        /* FIXME: UGLY HACK
         * iOS 8.2 and 8.3 include an issue which will lead to a termination of the client app if we set artwork
         * when the playback initialized through the watch extension
         * radar://pending */
        if ([WKInterfaceDevice class] != nil) {
            if ([WKInterfaceDevice currentDevice] != nil)
                goto setstuff;
        }
        if (artworkImage) {
            MPMediaItemArtwork *mpartwork = [[MPMediaItemArtwork alloc] initWithImage:artworkImage];
            currentlyPlayingTrackInfo[MPMediaItemPropertyArtwork] = mpartwork;
        }
    }
#endif

setstuff:
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = currentlyPlayingTrackInfo;
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackMetadataDidChange object:self];

    _title = title;
    _artist = artist;
    _albumName = albumName;
    _artworkImage = artworkImage;
    _mediaIsAudioOnly = mediaIsAudioOnly;
}

#if TARGET_OS_IOS
- (void)_recoverLastPlaybackStateOfItem:(MLFile *)item
{
    if (item) {
        if (_mediaPlayer.numberOfAudioTracks > 2) {
            if (item.lastAudioTrack.intValue > 0)
                _mediaPlayer.currentAudioTrackIndex = item.lastAudioTrack.intValue;
        }
        if (_mediaPlayer.numberOfSubtitlesTracks > 2) {
            if (item.lastSubtitleTrack.intValue > 0)
                _mediaPlayer.currentVideoSubTitleIndex = item.lastSubtitleTrack.intValue;
        }

        CGFloat lastPosition = .0;
        NSInteger duration = 0;

        if (item.lastPosition)
            lastPosition = item.lastPosition.floatValue;
        duration = item.duration.intValue;

        if (lastPosition < .95 && _mediaPlayer.position < lastPosition && (duration * lastPosition - duration) < -50000) {
            NSInteger continuePlayback;
            if ([item isAlbumTrack] || [item isSupportedAudioFile])
                continuePlayback = [[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingContinueAudioPlayback] integerValue];
            else
                continuePlayback = [[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingContinuePlayback] integerValue];

            if (continuePlayback == 1) {
                _mediaPlayer.position = lastPosition;
            } else if (continuePlayback == 0) {
                VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"CONTINUE_PLAYBACK", nil)
                                                                  message:[NSString stringWithFormat:NSLocalizedString(@"CONTINUE_PLAYBACK_LONG", nil), item.title]
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                        otherButtonTitles:NSLocalizedString(@"BUTTON_CONTINUE", nil), nil];
                alert.completion = ^(BOOL cancelled, NSInteger buttonIndex) {
                    if (!cancelled) {
                        _mediaPlayer.position = lastPosition;
                    }
                };
                [alert show];
            }
        }
    }
}
#endif

- (void)recoverDisplayedMetadata
{
    if ([self.delegate respondsToSelector:@selector(displayMetadataForPlaybackController:title:artwork:artist:album:audioOnly:)])
        [self.delegate displayMetadataForPlaybackController:self
                                                      title:_title
                                                    artwork:_artworkImage
                                                     artist:_artist
                                                      album:_albumName
                                                  audioOnly:_mediaIsAudioOnly];
}

- (void)recoverPlaybackState
{
    if ([self.delegate respondsToSelector:@selector(mediaPlayerStateChanged:isPlaying:currentMediaHasTrackToChooseFrom:currentMediaHasChapters:forPlaybackController:)])
        [self.delegate mediaPlayerStateChanged:_mediaPlayer.state
                                     isPlaying:self.isPlaying
              currentMediaHasTrackToChooseFrom:self.currentMediaHasTrackToChooseFrom
                       currentMediaHasChapters:self.currentMediaHasChapters
                         forPlaybackController:self];
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

#pragma mark - remote events

static inline NSArray * RemoteCommandCenterCommandsToHandle(MPRemoteCommandCenter *cc)
{
    /* commmented out other available commands which we don't support now but may
     * support at some point in the future */
    return @[cc.pauseCommand, cc.playCommand, cc.stopCommand, cc.togglePlayPauseCommand,
             cc.nextTrackCommand, cc.previousTrackCommand,
             cc.skipForwardCommand, cc.skipBackwardCommand,
             //             cc.seekForwardCommand, cc.seekBackwardCommand,
             //             cc.ratingCommand,
             cc.changePlaybackRateCommand,
             //             cc.likeCommand,cc.dislikeCommand,cc.bookmarkCommand,
             ];
}

- (void)subscribeRemoteCommands
{
    /* pre iOS 7.1 */
    if (![MPRemoteCommandCenter class]) {
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        return;
    }
    /* for iOS 7.1 and above: */

    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];

    /*
     * since the control center and lockscreen shows only either skipForward/Backward
     * or next/previousTrack buttons but prefers skip buttons,
     * we only enable skip buttons if we have a no medialist
     */
    BOOL enableSkip = [VLCPlaybackController sharedInstance].mediaList.count <= 1;
    commandCenter.skipForwardCommand.enabled = enableSkip;
    commandCenter.skipBackwardCommand.enabled = enableSkip;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *forwardSkip = [defaults valueForKey:kVLCSettingPlaybackForwardSkipLength];
    commandCenter.skipForwardCommand.preferredIntervals = @[forwardSkip];
    NSNumber *backwardSkip = [defaults valueForKey:kVLCSettingPlaybackBackwardSkipLength];
    commandCenter.skipBackwardCommand.preferredIntervals = @[backwardSkip];

    NSArray *supportedPlaybackRates = @[@(0.5),@(0.75),@(1.0),@(1.25),@(1.5),@(1.75),@(2.0)];
    commandCenter.changePlaybackRateCommand.supportedPlaybackRates = supportedPlaybackRates;

    NSArray *commandsToSubscribe = RemoteCommandCenterCommandsToHandle(commandCenter);
    for (MPRemoteCommand *command in commandsToSubscribe) {
        [command addTarget:self action:@selector(remoteCommandEvent:)];
    }
}

- (void)unsubscribeFromRemoteCommand
{
    /* pre iOS 7.1 */
    if (![MPRemoteCommandCenter class]) {
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
        return;
    }

    /* for iOS 7.1 and above: */
    MPRemoteCommandCenter *cc = [MPRemoteCommandCenter sharedCommandCenter];
    NSArray *commmandsToRemoveFrom = RemoteCommandCenterCommandsToHandle(cc);
    for (MPRemoteCommand *command in commmandsToRemoveFrom) {
        [command removeTarget:self];
    }
}

- (MPRemoteCommandHandlerStatus )remoteCommandEvent:(MPRemoteCommandEvent *)event
{
    MPRemoteCommandCenter *cc = [MPRemoteCommandCenter sharedCommandCenter];
    MPRemoteCommandHandlerStatus result = MPRemoteCommandHandlerStatusSuccess;

    if (event.command == cc.pauseCommand) {
        [_listPlayer pause];
    } else if (event.command == cc.playCommand) {
        [_listPlayer play];
    } else if (event.command == cc.stopCommand) {
        [_listPlayer stop];
    } else if (event.command == cc.togglePlayPauseCommand) {
        [self playPause];
    } else if (event.command == cc.nextTrackCommand) {
        result = [_listPlayer next] ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusNoSuchContent;
    } else if (event.command == cc.previousTrackCommand) {
        result = [_listPlayer previous] ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusNoSuchContent;
    } else if (event.command == cc.skipForwardCommand) {
        if ([event isKindOfClass:[MPSkipIntervalCommandEvent class]]) {
            MPSkipIntervalCommandEvent *skipEvent = (MPSkipIntervalCommandEvent *)event;
            [_mediaPlayer jumpForward:skipEvent.interval];
        } else {
            result = MPRemoteCommandHandlerStatusCommandFailed;
        }
    } else if (event.command == cc.skipBackwardCommand) {
        if ([event isKindOfClass:[MPSkipIntervalCommandEvent class]]) {
            MPSkipIntervalCommandEvent *skipEvent = (MPSkipIntervalCommandEvent *)event;
            [_mediaPlayer jumpBackward:skipEvent.interval];
        } else {
            result = MPRemoteCommandHandlerStatusCommandFailed;
        }
    } else if (event.command == cc.changePlaybackRateCommand) {
        if ([event isKindOfClass:[MPChangePlaybackRateCommandEvent class]]) {
            MPChangePlaybackRateCommandEvent *rateEvent = (MPChangePlaybackRateCommandEvent *)event;
            [_mediaPlayer setRate:rateEvent.playbackRate];
        } else {
            result = MPRemoteCommandHandlerStatusCommandFailed;
        }
        /* stubs for when we want to support the other available commands */
        //    } else if (event.command == cc.seekForwardCommand) {
        //    } else if (event.command == cc.seekBackwardCommand) {
        //    } else if (event.command == cc.ratingCommand) {
        //    } else if (event.command == cc.likeCommand) {
        //    } else if (event.command == cc.dislikeCommand) {
        //    } else if (event.command == cc.bookmarkCommand) {
    } else {
        APLog(@"%s Unsupported remote control event: %@",__PRETTY_FUNCTION__,event);
        result = MPRemoteCommandHandlerStatusCommandFailed;
    }

    if (result == MPRemoteCommandHandlerStatusCommandFailed)
        APLog(@"%s Wasn't able to handle remote control event: %@",__PRETTY_FUNCTION__,event);

    return result;
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
            [self forward];
            break;

        case UIEventSubtypeRemoteControlPreviousTrack:
            [self backward];
            break;

        case UIEventSubtypeRemoteControlStop:
            [self stopPlayback];
            break;

        default:
            break;
    }
}

#pragma mark - background interaction

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
#if TARGET_OS_IOS
    [self _savePlaybackState];
#endif

    if (![[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingContinueAudioInBackgroundKey] boolValue]) {
        if ([_mediaPlayer isPlaying]) {
            [_mediaPlayer pause];
            _shouldResumePlaying = YES;
        }
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    _preBackgroundWrapperView = _videoOutputViewWrapper;

    if (_mediaPlayer.audioTrackIndexes.count > 0)
        [self setVideoTrackEnabled:false];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (_preBackgroundWrapperView) {
        [self setVideoOutputView:_preBackgroundWrapperView];
        _preBackgroundWrapperView = nil;
    }

    [self setVideoTrackEnabled:true];

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
              kVLCSettingStretchAudio : [[defaults objectForKey:kVLCSettingStretchAudio] boolValue] ? kVLCSettingStretchAudioOnValue : kVLCSettingStretchAudioOffValue,
              kVLCSettingTextEncoding : [defaults objectForKey:kVLCSettingTextEncoding],
              kVLCSettingSkipLoopFilter : [defaults objectForKey:kVLCSettingSkipLoopFilter],
#if TARGET_OS_IOS
              kVLCSettingHWDecoding : [defaults objectForKey:kVLCSettingHWDecoding]};
#else
                };
#endif
}

@end
