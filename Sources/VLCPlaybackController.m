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
#import "VLCThumbnailsCache.h"
#import <WatchKit/WatchKit.h>
#import "VLCPlaylistViewController.h"

NSString *const VLCPlaybackControllerPlaybackDidStart = @"VLCPlaybackControllerPlaybackDidStart";
NSString *const VLCPlaybackControllerPlaybackDidPause = @"VLCPlaybackControllerPlaybackDidPause";
NSString *const VLCPlaybackControllerPlaybackDidResume = @"VLCPlaybackControllerPlaybackDidResume";
NSString *const VLCPlaybackControllerPlaybackDidStop = @"VLCPlaybackControllerPlaybackDidStop";
NSString *const VLCPlaybackControllerPlaybackMetadataDidChange = @"VLCPlaybackControllerPlaybackMetadataDidChange";
NSString *const VLCPlaybackControllerPlaybackDidFail = @"VLCPlaybackControllerPlaybackDidFail";

@interface VLCPlaybackController () <AVAudioSessionDelegate, VLCMediaPlayerDelegate, VLCMediaDelegate>
{
    BOOL _playerIsSetup;
    BOOL _playbackFailed;
    BOOL _shouldResumePlaying;

    NSArray *_aspectRatios;
    NSUInteger _currentAspectRatioMask;

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
}

@end

@implementation VLCPlaybackController

#pragma mark instance management

+ (VLCPlaybackController *)sharedInstance
{
    static VLCPlaybackController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - playback management

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


- (BOOL)_isMediaSuitableForDevice
{
    if (!self.fileFromMediaLibrary)
        return YES;

    NSUInteger totalNumberOfPixels = [[[self.fileFromMediaLibrary videoTrack] valueForKey:@"width"] doubleValue] * [[[self.fileFromMediaLibrary videoTrack] valueForKey:@"height"] doubleValue];

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
    } else if (speedCategory == 4) {
        // iPhone 6, 2014 iPads
        return (totalNumberOfPixels < 8850000); // 4K
    }

    return YES;
}

- (void)startPlayback
{
    if (_playerIsSetup)
        return;

    [[AVAudioSession sharedInstance] setDelegate:self];

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(audioSessionRouteChange:)
                          name:AVAudioSessionRouteChangeNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(applicationWillResignActive:)
                          name:UIApplicationWillResignActiveNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive:)
                          name:UIApplicationDidBecomeActiveNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground:)
                          name:UIApplicationDidEnterBackgroundNotification object:nil];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    _aspectRatios = @[@"DEFAULT", @"FILL_TO_SCREEN", @"4:3", @"16:9", @"16:10", @"2.21:1"];

    if (!self.fileFromMediaLibrary && !self.url && !self.mediaList) {
        [self stopPlayback];
        return;
    }
    if (self.pathToExternalSubtitlesFile)
        _listPlayer = [[VLCMediaListPlayer alloc] initWithOptions:@[[NSString stringWithFormat:@"--%@=%@", kVLCSettingSubtitlesFilePath, self.pathToExternalSubtitlesFile]]];
    else
        _listPlayer = [[VLCMediaListPlayer alloc] init];

    /* video decoding permanently fails if we don't provide a UIView to draw into on init
     * hence we provide one which is not attached to any view controller for off-screen drawing
     * and disable video decoding once playback started */
    _actualVideoOutputView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _actualVideoOutputView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _actualVideoOutputView.autoresizesSubviews = YES;

    _mediaPlayer = _listPlayer.mediaPlayer;
    [_mediaPlayer setDelegate:self];
    [_mediaPlayer setDrawable:_actualVideoOutputView];
    if ([[defaults objectForKey:kVLCSettingPlaybackSpeedDefaultValue] floatValue] != 0)
        [_mediaPlayer setRate: [[defaults objectForKey:kVLCSettingPlaybackSpeedDefaultValue] floatValue]];
    if ([[defaults objectForKey:kVLCSettingDeinterlace] intValue] != 0)
        [_mediaPlayer setDeinterlaceFilter:@"blend"];
    else
        [_mediaPlayer setDeinterlaceFilter:nil];
    if (self.pathToExternalSubtitlesFile)
        [_mediaPlayer openVideoSubTitlesFromFile:self.pathToExternalSubtitlesFile];

    VLCMedia *media;
    MLFile *item = self.fileFromMediaLibrary;
    if (item) {
        media = [VLCMedia mediaWithURL:item.url];
        media.delegate = self;
    } else if (self.mediaList) {
        media = [self.mediaList mediaAtIndex:self.itemInMediaListToBePlayedFirst];
        media.delegate = self;
    } else {
        media = [VLCMedia mediaWithURL:self.url];
        media.delegate = self;
        [media parse];
    }

    NSMutableDictionary *mediaDictionary = [[NSMutableDictionary alloc] init];
    [mediaDictionary setObject:[defaults objectForKey:kVLCSettingNetworkCaching] forKey:kVLCSettingNetworkCaching];
    [mediaDictionary setObject:[[defaults objectForKey:kVLCSettingStretchAudio] boolValue] ? kVLCSettingStretchAudioOnValue : kVLCSettingStretchAudioOffValue forKey:kVLCSettingStretchAudio];
    [mediaDictionary setObject:[defaults objectForKey:kVLCSettingTextEncoding] forKey:kVLCSettingTextEncoding];
    [mediaDictionary setObject:[defaults objectForKey:kVLCSettingSkipLoopFilter] forKey:kVLCSettingSkipLoopFilter];

#if 0
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
#endif

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

    if (![self _isMediaSuitableForDevice]) {
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DEVICE_TOOSLOW_TITLE", nil)
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"DEVICE_TOOSLOW", nil), [[UIDevice currentDevice] model], self.fileFromMediaLibrary.title]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                otherButtonTitles:NSLocalizedString(@"BUTTON_OPEN", nil), nil];
        [alert show];
    } else
        [self _playNewMedia];
}

- (void)_playNewMedia
{
    NSNumber *playbackPositionInTime = @(0);
    CGFloat lastPosition = .0;
    NSInteger duration = 0;
    MLFile *matchedFile;

    // Set last selected equalizer profile
    unsigned int profile = (unsigned int)[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingEqualizerProfile] integerValue];
    [_mediaPlayer resetEqualizerFromProfile:profile];
    [_mediaPlayer setPreAmplification:[_mediaPlayer preAmplification]];

    if (self.fileFromMediaLibrary)
        matchedFile = self.fileFromMediaLibrary;
    else if (self.mediaList) {
        NSURL *url  = [self.mediaList mediaAtIndex:self.itemInMediaListToBePlayedFirst].url;
        NSArray *files = [MLFile fileForURL:url];
        matchedFile = files.firstObject;
    }
    if (matchedFile.lastPosition) {
        lastPosition = matchedFile.lastPosition.floatValue;
    }
    duration = matchedFile.duration.intValue;
    if (lastPosition < .95) {
        if (duration != 0)
            playbackPositionInTime = @(lastPosition * (duration / 1000.));
    }
    if (playbackPositionInTime.intValue > 0 && (duration * lastPosition - duration) < -60000) {
        [_mediaPlayer.media addOptions:@{@"start-time": playbackPositionInTime}];
        APLog(@"set starttime to %i", playbackPositionInTime.intValue);
    }

    [_mediaPlayer addObserver:self forKeyPath:@"time" options:0 context:nil];
    [_mediaPlayer addObserver:self forKeyPath:@"remainingTime" options:0 context:nil];

    if (self.mediaList)
        [_listPlayer playItemAtIndex:self.itemInMediaListToBePlayedFirst];
    else
        [_listPlayer playMedia:_listPlayer.rootMedia];

    if ([self.delegate respondsToSelector:@selector(prepareForMediaPlayback:)])
        [self.delegate prepareForMediaPlayback:self];

    _currentAspectRatioMask = 0;
    _mediaPlayer.videoAspectRatio = NULL;

    /* some demuxers don't respect :start-time, so re-try here */
    if (lastPosition < .95 && _mediaPlayer.position < lastPosition && (duration * lastPosition - duration) < -60000)
        _mediaPlayer.position = lastPosition;

    [self subscribeRemoteCommands];

    _playerIsSetup = YES;
    _mediaWasJustStarted = YES;

    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackDidStart object:self];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [self _playNewMedia];
    else
        [self stopPlayback];
}

- (void)stopPlayback
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
            [self _savePlaybackState];
            [_mediaPlayer stop];
        }
        if (_mediaPlayer)
            _mediaPlayer = nil;
        if (_listPlayer)
            _listPlayer = nil;
    }
    if (_fileFromMediaLibrary)
        _fileFromMediaLibrary = nil;
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
    _playerIsSetup = NO;

    if (self.errorCallback && _playbackFailed)
        [[UIApplication sharedApplication] openURL:self.errorCallback];
    else if (self.successCallback)
        [[UIApplication sharedApplication] openURL:self.successCallback];

    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
    [self unsubscribeFromRemoteCommand];

    if (_playbackFailed) {
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackDidFail object:self];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackDidStop object:self];
    }
}

- (void)_savePlaybackState
{
    MLFile *fileItem = self.fileFromMediaLibrary;

    if (!fileItem) {
        NSArray *files = [MLFile fileForURL:_mediaPlayer.media.url];
        if (files.count > 0)
            fileItem = files.firstObject;
    }

    if (!fileItem)
        return;

    @try {
        float position = _mediaPlayer.position;
        fileItem.lastPosition = @(position);
        fileItem.lastAudioTrack = @(_mediaPlayer.currentAudioTrackIndex);
        fileItem.lastSubtitleTrack = @(_mediaPlayer.currentVideoSubTitleIndex);

        if ([fileItem isKindOfType:kMLFileTypeAudio])
            return;

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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([self.delegate respondsToSelector:@selector(playbackPositionUpdated:)])
        [self.delegate playbackPositionUpdated:self];
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
    return [_mediaPlayer countOfTitles] > 1 || [_mediaPlayer chaptersForTitleIndex:_mediaPlayer.currentTitleIndex].count > 1;
}

- (BOOL)currentMediaHasTrackToChooseFrom
{
    return [[_mediaPlayer audioTrackIndexes] count] > 2 || [[_mediaPlayer videoSubTitlesIndexes] count] > 1;
}

- (BOOL)activePlaybackSession
{
    return _mediaPlayer != nil;
}

- (BOOL)audioOnlyPlaybackSession
{
    return _mediaIsAudioOnly;
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
        [_mediaPlayer performSelector:@selector(setTextRendererFont:) withObject:[self _resolveFontName]];
        [_mediaPlayer performSelector:@selector(setTextRendererFontSize:) withObject:[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingSubtitlesFontSize]];
        [_mediaPlayer performSelector:@selector(setTextRendererFontColor:) withObject:[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingSubtitlesFontColor]];
    } else if (currentState == VLCMediaPlayerStateError) {
        _playbackFailed = YES;
        [self stopPlayback];
    } else if ((currentState == VLCMediaPlayerStateEnded || currentState == VLCMediaPlayerStateStopped) && _listPlayer.repeatMode == VLCDoNotRepeat) {
        if ([_listPlayer.mediaList indexOfMedia:_mediaPlayer.media] == _listPlayer.mediaList.count - 1) {
            [self stopPlayback];
            return;
        }
    }

    /* disable video decoding if we have no place to show */
    if (_mediaPlayer.numberOfAudioTracks > 0) {
        if (_videoOutputViewWrapper == nil)
            _mediaPlayer.currentVideoTrackIndex = -1;
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
        [self _savePlaybackState];
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackDidPause object:self];
    } else {
        [_listPlayer play];
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackDidResume object:self];
    }
}

- (void)forward
{
    if (_mediaList) {
        [_listPlayer next];
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackMetadataDidChange object:self];
    } else {
        NSNumber *skipLength = [[NSUserDefaults standardUserDefaults] valueForKey:kVLCSettingPlaybackForwardSkipLength];
        [_mediaPlayer jumpForward:skipLength.intValue];
    }
}

- (void)backward
{
    if (_mediaList) {
        [_listPlayer previous];
        [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackMetadataDidChange object:self];
    }
    else {
        NSNumber *skipLength = [[NSUserDefaults standardUserDefaults] valueForKey:kVLCSettingPlaybackBackwardSkipLength];
        [_mediaPlayer jumpBackward:skipLength.intValue];
    }
}

- (void)switchAspectRatio
{
    NSUInteger count = [_aspectRatios count];

    if (_currentAspectRatioMask + 1 > count - 1) {
        _mediaPlayer.videoAspectRatio = NULL;
        _mediaPlayer.videoCropGeometry = NULL;
        _currentAspectRatioMask = 0;
        if ([self.delegate respondsToSelector:@selector(showStatusMessage:forPlaybackController:)])
            [self.delegate showStatusMessage:[NSString stringWithFormat:NSLocalizedString(@"AR_CHANGED", nil), NSLocalizedString(@"DEFAULT", nil)] forPlaybackController:self];
    } else {
        _currentAspectRatioMask++;

        if ([_aspectRatios[_currentAspectRatioMask] isEqualToString:@"FILL_TO_SCREEN"]) {
            UIScreen *screen;
            if (![[UIDevice currentDevice] hasExternalDisplay])
                screen = [UIScreen mainScreen];
            else
                screen = [UIScreen screens][1];

            float f_ar = screen.bounds.size.width / screen.bounds.size.height;

            if (f_ar == (float)(640./1136.)) // iPhone 5 aka 16:9.01
                _mediaPlayer.videoCropGeometry = "16:9";
            else if (f_ar == (float)(2./3.)) // all other iPhones
                _mediaPlayer.videoCropGeometry = "16:10"; // libvlc doesn't support 2:3 crop
            else if (f_ar == (float)(1. + (1./3.))) // all iPads
                _mediaPlayer.videoCropGeometry = "4:3";
            else if (f_ar == .5625) // AirPlay
                _mediaPlayer.videoCropGeometry = "16:9";
            else
                APLog(@"unknown screen format %f, can't crop", f_ar);

            if ([self.delegate respondsToSelector:@selector(showStatusMessage:forPlaybackController:)])
                [self.delegate showStatusMessage:NSLocalizedString(@"FILL_TO_SCREEN", nil) forPlaybackController:self];
            return;
        }

        _mediaPlayer.videoCropGeometry = NULL;
        _mediaPlayer.videoAspectRatio = (char *)[_aspectRatios[_currentAspectRatioMask] UTF8String];

        if ([self.delegate respondsToSelector:@selector(showStatusMessage:forPlaybackController:)])
            [self.delegate showStatusMessage:[NSString stringWithFormat:NSLocalizedString(@"AR_CHANGED", nil), _aspectRatios[_currentAspectRatioMask]] forPlaybackController:self];
    }
}

- (void)setVideoOutputView:(UIView *)videoOutputView
{
    if (videoOutputView) {
        if ([_actualVideoOutputView superview] != nil)
            [_actualVideoOutputView removeFromSuperview];

        _actualVideoOutputView.frame = (CGRect){CGPointZero, videoOutputView.frame.size};
        [_actualVideoOutputView layoutSubviews];
        [_actualVideoOutputView updateConstraints];

        if (_mediaPlayer.currentVideoTrackIndex == -1)
            _mediaPlayer.currentVideoTrackIndex = 0;

        [videoOutputView addSubview:_actualVideoOutputView];
    } else
        [_actualVideoOutputView removeFromSuperview];

    _videoOutputViewWrapper = videoOutputView;
}

- (UIView *)videoOutputView
{
    return _videoOutputViewWrapper;
}

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

#pragma mark - AVSession delegate
- (void)beginInterruption
{
    if ([_mediaPlayer isPlaying]) {
        [_mediaPlayer pause];
        _shouldResumePlaying = YES;
    }
}

- (void)endInterruption
{
    if (_shouldResumePlaying) {
        [_mediaPlayer play];
        _shouldResumePlaying = NO;
    }
}

- (void)audioSessionRouteChange:(NSNotification *)notification
{
    NSArray *outputs = [[AVAudioSession sharedInstance] currentRoute].outputs;
    NSString *portName = [[outputs objectAtIndex:0] portName];

    if (![portName isEqualToString:@"Headphones"] && [_mediaPlayer isPlaying])
        [_listPlayer pause];
}

#pragma mark - Managing the media item

- (void)setFileFromMediaLibrary:(MLFile *)fileFromMediaLibrary
{
    [self stopPlayback];
    _fileFromMediaLibrary = fileFromMediaLibrary;
    _playerIsSetup = NO;
}

- (void)setUrl:(NSURL *)url
{
    [self stopPlayback];
    _url = url;
    _playerIsSetup = NO;
}

- (void)setMediaList:(VLCMediaList *)mediaList
{
    [self stopPlayback];
    _mediaList = mediaList;
    _playerIsSetup = NO;
}

- (MLFile *)currentlyPlayingMediaFile {
    MLFile *mediaFile = self.fileFromMediaLibrary;
    if (mediaFile) {
        return mediaFile;
    } else if (self.mediaList) {
        NSArray *results = [MLFile fileForURL:_mediaPlayer.media.url];
        return results.firstObject;
    }

    return nil;
}

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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self _updateDisplayedMetadata];
        });
    }
}

- (void)_updateDisplayedMetadata
{
    _needsMetadataUpdate = NO;

    MLFile *item;
    NSNumber *trackNumber;

    NSString *title;
    NSString *artist;
    NSString *albumName;
    UIImage* artworkImage;
    BOOL mediaIsAudioOnly = NO;

    if (self.fileFromMediaLibrary)
        item = self.fileFromMediaLibrary;
    else if (self.mediaList) {
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
        NSDictionary * metaDict = _mediaPlayer.media.metaDictionary;

        if (metaDict) {
            title = metaDict[VLCMetaInformationNowPlaying] ? metaDict[VLCMetaInformationNowPlaying] : metaDict[VLCMetaInformationTitle];
            artist = metaDict[VLCMetaInformationArtist];
            albumName = metaDict[VLCMetaInformationAlbum];
            trackNumber = metaDict[VLCMetaInformationTrackNumber];
        }
    }

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
        artworkImage = [VLCThumbnailsCache thumbnailForManagedObject:item];

        if (artworkImage) {
            if (artist)
                title = [title stringByAppendingFormat:@" — %@", artist];
            if (albumName)
                title = [title stringByAppendingFormat:@" — %@", albumName];
        }

        if (title.length < 1)
            title = [[_mediaPlayer.media url] lastPathComponent];
    } else if (_mediaWasJustStarted) {
        _mediaWasJustStarted = NO;

        if (item) {
            if (_mediaPlayer.numberOfAudioTracks > 2) {
                if (item.lastAudioTrack.intValue > 0)
                    _mediaPlayer.currentAudioTrackIndex = item.lastAudioTrack.intValue;
            }
            if (_mediaPlayer.numberOfSubtitlesTracks > 2) {
                if (item.lastSubtitleTrack.intValue > 0)
                    _mediaPlayer.currentVideoSubTitleIndex = item.lastSubtitleTrack.intValue;
            }
        }
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
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingPasscodeOnKey] boolValue]) {
        if (title)
            currentlyPlayingTrackInfo[MPMediaItemPropertyTitle] = title;
        if (artist.length > 0)
            currentlyPlayingTrackInfo[MPMediaItemPropertyArtist] = artist;
        if (albumName.length > 0)
            currentlyPlayingTrackInfo[MPMediaItemPropertyAlbumTitle] = albumName;

        if ([trackNumber intValue] > 0)
            currentlyPlayingTrackInfo[MPMediaItemPropertyAlbumTrackNumber] = trackNumber;

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

setstuff:
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = currentlyPlayingTrackInfo;
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackMetadataDidChange object:self];

    _title = title;
    _artist = artist;
    _albumName = albumName;
    _artworkImage = artworkImage;
    _mediaIsAudioOnly = mediaIsAudioOnly;

}

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
    BOOL enableSkip = [VLCPlaybackController sharedInstance].mediaList == nil;
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
    [self _savePlaybackState];

    _preBackgroundWrapperView = _videoOutputViewWrapper;
    [self setVideoOutputView:nil];

    if (_mediaPlayer.audioTrackIndexes.count > 0)
        _mediaPlayer.currentVideoTrackIndex = -1;

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
    if (_preBackgroundWrapperView) {
        [self setVideoOutputView:_preBackgroundWrapperView];
        _preBackgroundWrapperView = nil;
    }

    if (_mediaPlayer.numberOfVideoTracks > 0) {
        /* re-enable video decoding */
        _mediaPlayer.currentVideoTrackIndex = 1;
    }

    if (_shouldResumePlaying) {
        _shouldResumePlaying = NO;
        [_listPlayer play];
    }
}

#pragma mark - helpers

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

@end
