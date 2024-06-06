/*****************************************************************************
 * VLCPlaybackService.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2023 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Maxime Chapelet <umxprime # videolabs.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

NS_ASSUME_NONNULL_BEGIN
extern NSString *const VLCPlaybackServicePlaybackDidStart;
extern NSString *const VLCPlaybackServicePlaybackDidPause;
extern NSString *const VLCPlaybackServicePlaybackDidResume;
extern NSString *const VLCPlaybackServicePlaybackWillStop;
extern NSString *const VLCPlaybackServicePlaybackDidStop;
extern NSString *const VLCPlaybackServicePlaybackDidFail;
extern NSString *const VLCPlaybackServicePlaybackMetadataDidChange;
extern NSString *const VLCPlaybackServicePlaybackPositionUpdated;
extern NSString *const VLCPlaybackServicePlaybackModeUpdated;
extern NSString *const VLCPlaybackServiceShuffleModeUpdated;
extern NSString *const VLCPlaybackServicePlaybackDidMoveOnToNextItem;
extern NSString *const VLCLastPlaylistPlayedMedia;

@class VLCPlaybackService;
@class VLCMetaData;
@class VLCMLMedia;
@class VLCPlayerDisplayController;
@class VLCPlaybackServiceAdjustFilter;
@class VLCMediaPlayerTitleDescription;
@class VLCMediaPlayerChapterDescription;

@protocol VLCPlaybackServiceDelegate <NSObject>
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
- (void)playbackServiceDidSwitchAspectRatio:(NSInteger)aspectRatio;
- (void)playbackService:(VLCPlaybackService *)playbackService
              nextMedia:(VLCMedia *)media;
- (void)playModeUpdated;
- (void)reloadPlayQueue;
- (void)pictureInPictureStateDidChange:(BOOL)isEnabled
NS_SWIFT_NAME(pictureInPictureStateDidChange(enabled:));
@end

NS_SWIFT_NAME(PlaybackService)
@interface VLCPlaybackService : NSObject

@property (nonatomic, strong, nullable) UIView *videoOutputView;

@property (nonatomic, retain) VLCMediaList *mediaList;
@property (nonatomic, retain) VLCMediaList *shuffledList;

/* returns nil if currently playing item is not available,*/

@property (nonatomic, strong, readonly, nullable) VLCMedia *currentlyPlayingMedia;

@property (nonatomic, weak) id<VLCPlaybackServiceDelegate> delegate;

@property (nonatomic, readonly) VLCMediaPlayerState mediaPlayerState;
@property (nonatomic, readonly) VLCMetaData *metadata;

@property (nonatomic, readonly) NSInteger mediaDuration;
@property (nonatomic, readonly) VLCTime *mediaLength;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) BOOL playerIsSetup;
@property (nonatomic, readwrite) BOOL playAsAudio;
@property (nonatomic, readwrite) VLCRepeatMode repeatMode;
@property (nonatomic, assign, getter=isShuffleMode) BOOL shuffleMode;
@property (nonatomic, readwrite) float playbackRate; // default = 1.0
@property (nonatomic, readwrite) float audioDelay; // in milliseconds, default = 0.0
@property (nonatomic, readwrite) float playbackPosition; // in seconds, default = 0.0
@property (nonatomic, readwrite) float subtitleDelay; // in milliseconds, default = 0.0
@property (nonatomic, readonly) VLCPlaybackServiceAdjustFilter *adjustFilter;
@property (nonatomic, readonly) CGFloat yaw; //  between ]-180;180]
@property (nonatomic, readonly) CGFloat pitch; // ]-90;90]
@property (nonatomic, readonly) CGFloat roll; // ]-180;180]
@property (nonatomic, readonly) CGFloat fov; // ]0;180[ (default 80.)

@property (readonly) NSInteger indexOfCurrentAudioTrack;
@property (readonly) NSInteger indexOfCurrentSubtitleTrack;
@property (readonly) NSInteger indexOfCurrentTitle;
@property (readonly, nullable) VLCMediaPlayerTitleDescription *currentTitleDescription;
@property (readonly) NSInteger indexOfCurrentChapter;
@property (readonly, nullable) VLCMediaPlayerChapterDescription *currentChapterDescription;
@property (readonly) NSInteger numberOfVideoTracks;
@property (readonly) NSInteger numberOfAudioTracks;
@property (readonly) NSInteger numberOfVideoSubtitlesIndexes;
@property (readonly) NSInteger numberOfTitles;
@property (readonly) NSInteger numberOfChaptersForCurrentTitle;
@property (assign, readonly) BOOL currentMediaHasTrackToChooseFrom;
@property (assign, readwrite) BOOL fullscreenSessionRequested;
@property (assign, readonly) BOOL isSeekable;
@property (assign, readonly) BOOL currentMediaIs360Video;
@property (readonly) BOOL isNextMediaAvailable;
@property (readonly) NSNumber *playbackTime;
@property (nonatomic, readonly) NSDictionary *mediaOptionsDictionary;
@property (nonatomic, readonly) NSTimer *sleepTimer;

@property (nonatomic, readwrite) CGFloat preAmplification;

#if TARGET_OS_IOS
@property (nonatomic, nullable) VLCRendererItem *renderer;
#endif

@property (nonatomic, readonly) NSInteger currentAspectRatio;

@property (nonatomic, readonly) VLCPlayerDisplayController *playerDisplayController;

@property (nonatomic) NSMutableArray *openedLocalURLs;

+ (VLCPlaybackService *)sharedInstance;
- (VLCTime *)playedTime;
#pragma mark - playback
- (void)startPlayback;
- (void)stopPlayback;
- (void)playPause;
- (void)play;
- (void)pause;
- (BOOL)next;
- (BOOL)previous;
- (void)jumpForward:(int)interval;
- (void)jumpBackward:(int)interval;
- (void)toggleRepeatMode;
- (VLCTime *)remainingTime;

- (NSString *)audioTrackNameAtIndex:(NSInteger)index;
- (NSString *)videoSubtitleNameAtIndex:(NSInteger)index;
- (nullable VLCMediaPlayerTitleDescription *)titleDescriptionAtIndex:(NSInteger)index;
- (nullable VLCMediaPlayerChapterDescription *)chapterDescriptionAtIndex:(NSInteger)index;
- (void)selectAudioTrackAtIndex:(NSInteger)index;
- (void)selectVideoSubtitleAtIndex:(NSInteger)index;
- (void)selectTitleAtIndex:(NSInteger)index;
- (void)selectChapterAtIndex:(NSInteger)index;
- (void)setAudioPassthrough:(BOOL)shouldPass;
- (void)switchAspectRatio:(BOOL)toggleFullScreen;
- (void)setCurrentAspectRatio:(NSInteger)currentAspectRatio;

- (void)playItemAtIndex:(NSUInteger)index;

- (BOOL)updateViewpoint:(CGFloat)yaw pitch:(CGFloat)pitch roll:(CGFloat)roll fov:(CGFloat)fov absolute:(BOOL)absolute;
- (NSInteger)currentMediaProjection;

- (void)recoverDisplayedMetadata;
- (void)recoverPlaybackState;
- (void)disableSubtitlesIfNeeded;

- (BOOL)isPlayingOnExternalScreen;

- (void)setPlayerHidden:(BOOL)hidden;
- (void)setPlayerDisplayController:(VLCPlayerDisplayController *)playerDisplayController;

- (void)setNeedsMetadataUpdate;
- (void)scheduleSleepTimerWithInterval:(NSTimeInterval)timeInterval;
- (void)performNavigationAction:(VLCMediaPlaybackNavigationAction)action;
- (void)playMediaList:(VLCMediaList *)mediaList firstIndex:(NSInteger)index subtitlesFilePath:(nullable NSString *)subsFilePath;
- (void)playMediaList:(VLCMediaList *)mediaList firstIndex:(NSInteger)index subtitlesFilePath:(nullable NSString *)subsFilePath completion:(void (^ __nullable)(BOOL success))completion;
- (void)addAudioToCurrentPlaybackFromURL:(NSURL *)audioURL;
- (void)addSubtitlesToCurrentPlaybackFromURL:(NSURL *)subtitleURL;

- (void)setAmplification:(CGFloat)amplification forBand:(unsigned int)index;
- (void)togglePictureInPicture;

#if !TARGET_OS_TV
- (void)savePlaybackState;
- (void)restoreAudioAndSubtitleTrack;
- (BOOL)mediaListContains:(NSURL *)url;
- (void)removeMediaFromMediaListAtIndex:(NSUInteger)index;
- (NSIndexPath *)selectedEqualizerProfile;
#endif

NS_ASSUME_NONNULL_END
@end
