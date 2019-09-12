/*****************************************************************************
 * VLCPlaybackService.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCEqualizerView.h"

typedef NS_ENUM(NSUInteger, VLCAspectRatio) {
    VLCAspectRatioDefault = 0,
    VLCAspectRatioFillToScreen,
    VLCAspectRatioFourToThree,
    VLCAspectRatioSixteenToNine,
    VLCAspectRatioSixteenToTen,
};

NS_ASSUME_NONNULL_BEGIN
extern NSString *const VLCPlaybackServicePlaybackDidStart;
extern NSString *const VLCPlaybackServicePlaybackDidPause;
extern NSString *const VLCPlaybackServicePlaybackDidResume;
extern NSString *const VLCPlaybackServicePlaybackDidStop;
extern NSString *const VLCPlaybackServicePlaybackDidFail;
extern NSString *const VLCPlaybackServicePlaybackMetadataDidChange;
extern NSString *const VLCPlaybackServicePlaybackPositionUpdated;

@class VLCPlaybackService;
@class VLCMetaData;
@class VLCMLMedia;
@class VLCPlayerDisplayController;

@protocol VLCPlaybackServiceDelegate <NSObject>
#if TARGET_OS_IOS
- (void)savePlaybackState:(VLCPlaybackService *)playbackService;
- (VLCMLMedia *_Nullable)mediaForPlayingMedia:(nullable VLCMedia *)media;
#endif
@optional
- (void)playbackPositionUpdated:(VLCPlaybackService *)playbackService;
- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
currentMediaHasTrackToChooseFrom:(BOOL)currentMediaHasTrackToChooseFrom
        currentMediaHasChapters:(BOOL)currentMediaHasChapters
             forPlaybackService:(VLCPlaybackService *)playbackService;
- (void)prepareForMediaPlayback:(VLCPlaybackService *)playbackService;
- (void)showStatusMessage:(NSString *)statusMessage;
- (void)displayMetadataForPlaybackService:(VLCPlaybackService *)playbackService
                                 metadata:(VLCMetaData *)metadata;
- (void)playbackServiceDidSwitchAspectRatio:(VLCAspectRatio)aspectRatio;

@end

NS_SWIFT_NAME(PlaybackService)
@interface VLCPlaybackService : NSObject <VLCEqualizerViewDelegate>

@property (nonatomic, strong, nullable) UIView *videoOutputView;

@property (nonatomic, retain) VLCMediaList *mediaList;

/* returns nil if currently playing item is not available,*/

@property (nonatomic, strong, readonly) VLCMedia *currentlyPlayingMedia;

@property (nonatomic, weak) id<VLCPlaybackServiceDelegate> delegate;

@property (nonatomic, readonly) VLCMediaPlayerState mediaPlayerState;
@property (nonatomic, readonly) VLCMetaData *metadata;

@property (nonatomic, readonly) NSInteger mediaDuration;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) BOOL willPlay;
@property (nonatomic, readonly) BOOL playerIsSetup;
@property (nonatomic, readwrite) VLCRepeatMode repeatMode;
@property (nonatomic, assign, getter=isShuffleMode) BOOL shuffleMode;
@property (nonatomic, readwrite) float playbackRate; // default = 1.0
@property (nonatomic, readwrite) float audioDelay; // in milliseconds, default = 0.0
@property (nonatomic, readwrite) float playbackPosition; // in seconds, default = 0.0
@property (nonatomic, readwrite) float subtitleDelay; // in milliseconds, default = 0.0

@property (nonatomic, readwrite) float hue; // default = 0.0
@property (nonatomic, readwrite) float contrast; // default = 1.0
@property (nonatomic, readwrite) float brightness; // default = 1.0
@property (nonatomic, readwrite) float saturation; // default = 1.0
@property (nonatomic, readwrite) float gamma; // default = 1.0

@property (nonatomic, readonly) CGFloat yaw; //  between ]-180;180]
@property (nonatomic, readonly) CGFloat pitch; // ]-90;90]
@property (nonatomic, readonly) CGFloat roll; // ]-180;180]
@property (nonatomic, readonly) CGFloat fov; // ]0;180[ (default 80.)

@property (readonly) NSInteger indexOfCurrentAudioTrack;
@property (readonly) NSInteger indexOfCurrentSubtitleTrack;
@property (readonly) NSInteger indexOfCurrentTitle;
@property (readonly) NSInteger indexOfCurrentChapter;
@property (readonly) NSInteger numberOfAudioTracks;
@property (readonly) NSInteger numberOfVideoSubtitlesIndexes;
@property (readonly) NSInteger numberOfTitles;
@property (readonly) NSInteger numberOfChaptersForCurrentTitle;
@property (assign, readonly) BOOL currentMediaHasTrackToChooseFrom;
@property (assign, readwrite) BOOL fullscreenSessionRequested;
@property (assign, readonly) BOOL isSeekable;
@property (assign, readonly) BOOL currentMediaIs360Video;
@property (readonly) NSNumber *playbackTime;
@property (nonatomic, readonly) NSDictionary *mediaOptionsDictionary;
@property (nonatomic, readonly) NSTimer *sleepTimer;

@property (nonatomic, nullable) VLCRendererItem *renderer;

@property (nonatomic, readonly) VLCAspectRatio currentAspectRatio;

+ (VLCPlaybackService *)sharedInstance;
- (VLCTime *)playedTime;
#pragma mark - playback
- (void)startPlayback;
- (void)stopPlayback;
- (void)playPause;
- (void)play;
- (void)pause;
- (void)next;
- (void)previous;
- (void)jumpForward:(int)interval;
- (void)jumpBackward:(int)interval;
- (void)toggleRepeatMode;
- (void)resetFilters;
- (VLCTime *)remainingTime;

- (NSString *)audioTrackNameAtIndex:(NSInteger)index;
- (NSString *)videoSubtitleNameAtIndex:(NSInteger)index;
- (NSDictionary *)titleDescriptionsDictAtIndex:(NSInteger)index;
- (NSDictionary *)chapterDescriptionsDictAtIndex:(NSInteger)index;
- (void)selectAudioTrackAtIndex:(NSInteger)index;
- (void)selectVideoSubtitleAtIndex:(NSInteger)index;
- (void)selectTitleAtIndex:(NSInteger)index;
- (void)selectChapterAtIndex:(NSInteger)index;
- (void)setAudioPassthrough:(BOOL)shouldPass;
- (void)switchAspectRatio:(BOOL)toggleFullScreen;

#if !TARGET_OS_TV
- (BOOL)updateViewpoint:(CGFloat)yaw pitch:(CGFloat)pitch roll:(CGFloat)roll fov:(CGFloat)fov absolute:(BOOL)absolute;
- (NSInteger)currentMediaProjection;
#endif
- (void)recoverDisplayedMetadata;
- (void)recoverPlaybackState;

- (BOOL)isPlayingOnExternalScreen;

- (void)setPlayerHidden:(BOOL)hidden;
- (void)setPlayerDisplayController:(VLCPlayerDisplayController *)playerDisplayController;

- (void)setNeedsMetadataUpdate;
- (void)scheduleSleepTimerWithInterval:(NSTimeInterval)timeInterval;
- (void)performNavigationAction:(VLCMediaPlaybackNavigationAction)action;
- (void)playMediaList:(VLCMediaList *)mediaList firstIndex:(NSInteger)index subtitlesFilePath:(nullable NSString *)subsFilePath;
- (void)playMediaList:(VLCMediaList *)mediaList firstIndex:(NSInteger)index subtitlesFilePath:(nullable NSString *)subsFilePath completion:(void (^ __nullable)(BOOL success))completion;
- (void)openVideoSubTitlesFromFile:(NSString *)pathToFile;

NS_ASSUME_NONNULL_END
@end
