/*****************************************************************************
 * VLCPlaybackController.h
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
extern NSString *const VLCPlaybackControllerPlaybackDidStart;
extern NSString *const VLCPlaybackControllerPlaybackDidPause;
extern NSString *const VLCPlaybackControllerPlaybackDidResume;
extern NSString *const VLCPlaybackControllerPlaybackDidStop;
extern NSString *const VLCPlaybackControllerPlaybackDidFail;
extern NSString *const VLCPlaybackControllerPlaybackMetadataDidChange;
extern NSString *const VLCPlaybackControllerPlaybackPositionUpdated;

@class VLCPlaybackController;
@class VLCMetaData;

@protocol VLCPlaybackControllerDelegate <NSObject>
@optional
- (void)playbackPositionUpdated:(VLCPlaybackController *)controller;
- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
currentMediaHasTrackToChooseFrom:(BOOL)currentMediaHasTrackToChooseFrom
        currentMediaHasChapters:(BOOL)currentMediaHasChapters
          forPlaybackController:(VLCPlaybackController *)controller;
- (void)prepareForMediaPlayback:(VLCPlaybackController *)controller;
- (void)showStatusMessage:(NSString *)statusMessage forPlaybackController:(VLCPlaybackController *)controller;
- (void)displayMetadataForPlaybackController:(VLCPlaybackController *)controller metadata:(VLCMetaData *)metadata;

@end

@interface VLCPlaybackController : NSObject <VLCEqualizerViewDelegate>

@property (nonatomic, strong) UIView *videoOutputView;

@property (nonatomic, strong) NSURL *successCallback;
@property (nonatomic, strong) NSURL *errorCallback;

@property (nonatomic, retain) VLCMediaList *mediaList;

/* returns nil if currently playing item is not available,*/

@property (nonatomic, strong, readonly) VLCMedia *currentlyPlayingMedia;

@property (nonatomic, weak) id<VLCPlaybackControllerDelegate> delegate;

@property (nonatomic, readonly) VLCMediaPlayerState mediaPlayerState;
@property (nonatomic, readonly) VLCMetaData *metadata;

@property (nonatomic, readonly) NSInteger mediaDuration;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) BOOL willPlay;
@property (nonatomic, readwrite) VLCRepeatMode repeatMode;
@property (nonatomic, assign, getter=isShuffleMode) BOOL shuffleMode;
@property (nonatomic, readwrite) float playbackRate; // default = 1.0
@property (nonatomic, readwrite) float audioDelay; // in seconds, default = 0.0
@property (nonatomic, readwrite) float playbackPosition; // in seconds, default = 0.0
@property (nonatomic, readwrite) float subtitleDelay; // in seconds, default = 0.0

@property (nonatomic, readwrite) float hue; // default = 0.0
@property (nonatomic, readwrite) float contrast; // default = 1.0
@property (nonatomic, readwrite) float brightness; // default = 1.0
@property (nonatomic, readwrite) float saturation; // default = 1.0
@property (nonatomic, readwrite) float gamma; // default = 1.0

@property (readonly) NSInteger indexOfCurrentAudioTrack;
@property (readonly) NSInteger indexOfCurrentSubtitleTrack;
@property (readonly) NSInteger indexOfCurrentTitle;
@property (readonly) NSInteger indexOfCurrentChapter;
@property (readonly) NSInteger numberOfAudioTracks;
@property (readonly) NSInteger numberOfVideoSubtitlesIndexes;
@property (readonly) NSInteger numberOfTitles;
@property (readonly) NSInteger numberOfChaptersForCurrentTitle;
@property (nonatomic, readonly) BOOL currentMediaHasTrackToChooseFrom;
@property (nonatomic, readwrite) BOOL fullscreenSessionRequested;
@property (nonatomic, readonly) BOOL isSeekable;
@property (readonly) NSNumber *playbackTime;
@property (nonatomic, readonly) NSDictionary *mediaOptionsDictionary;
@property (nonatomic, readonly) NSTimer* sleepTimer;

+ (VLCPlaybackController *)sharedInstance;
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

- (void)switchAspectRatio;
- (void)switchIPhoneXFullScreen;
#if !TARGET_OS_TV
- (BOOL)updateViewpoint:(CGFloat)yaw pitch:(CGFloat)pitch roll:(CGFloat)roll fov:(CGFloat)fov absolute:(BOOL)absolute;
- (NSInteger)currentMediaProjection;
#endif
- (void)recoverDisplayedMetadata;
- (void)recoverPlaybackState;

- (void)setNeedsMetadataUpdate;
- (void)scheduleSleepTimerWithInterval:(NSTimeInterval)timeInterval;
- (void)performNavigationAction:(VLCMediaPlaybackNavigationAction)action;
- (void)playMediaList:(VLCMediaList *)mediaList firstIndex:(NSInteger)index subtitlesFilePath:(NSString *)subsFilePath;
- (void)openVideoSubTitlesFromFile:(NSString *)pathToFile;

@end
