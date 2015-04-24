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

@class VLCPlaybackController;

@protocol VLCPlaybackControllerDelegate <NSObject>

@optional
- (void)playbackPositionUpdated:(VLCPlaybackController *)controller;
- (void)playbackRateUpdated:(float)rate forPlaybackController:(VLCPlaybackController *)controller;
- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
currentMediaHasTrackToChooseFrom:(BOOL)currentMediaHasTrackToChooseFrom
        currentMediaHasChapters:(BOOL)currentMediaHasChapters
          forPlaybackController:(VLCPlaybackController *)controller;
- (void)prepareForMediaPlayback:(VLCPlaybackController *)controller;
- (void)presentingViewControllerShouldBeClosed:(VLCPlaybackController *)controller;
- (void)presentingViewControllerShouldBeClosedAfterADelay:(VLCPlaybackController *)controller;
- (void)showStatusMessage:(NSString *)statusMessage forPlaybackController:(VLCPlaybackController *)controller;
- (void)audioOnlyPlaybackWasDetected:(BOOL)audioOnly forPlaybackController:(VLCPlaybackController *)controller;
- (void)displayMetadataForPlaybackController:(VLCPlaybackController *)controller
                                       title:(NSString *)title
                                     artwork:(UIImage *)artwork
                                      artist:(NSString *)artist
                                       album:(NSString *)album
                                   audioOnly:(BOOL)audioOnly;

@end

@interface VLCPlaybackController : NSObject <VLCEqualizerViewDelegate>

@property (nonatomic, readonly) VLCMediaListPlayer *listPlayer;
@property (nonatomic, readonly) VLCMediaPlayer *mediaPlayer;

@property (nonatomic, strong) UIView *videoOutputView;

@property (nonatomic, strong) MLFile *fileFromMediaLibrary;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURL *successCallback;
@property (nonatomic, strong) NSURL *errorCallback;

@property (nonatomic, strong) NSString *pathToExternalSubtitlesFile;
@property (nonatomic, retain) VLCMediaList *mediaList;
@property (nonatomic, readwrite) int itemInMediaListToBePlayedFirst;

/* returns nil if currenlty plaing item is not a MLFile, e.g. a url */
@property (nonatomic, strong, readonly) MLFile *currentlyPlayingMediaFile;

@property (nonatomic, weak) id<VLCPlaybackControllerDelegate> delegate;

@property (nonatomic, readonly) VLCMediaPlayerState mediaPlayerState;
@property (nonatomic, readonly) NSInteger mediaDuration;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readwrite) VLCRepeatMode repeatMode;
@property (nonatomic, readwrite) float playbackRate;
@property (nonatomic, readonly) BOOL currentMediaHasChapters;
@property (nonatomic, readonly) BOOL currentMediaHasTrackToChooseFrom;

+ (VLCPlaybackController *)sharedInstance;

- (void)startPlayback;
- (void)stopPlayback;

- (void)playPause;
- (void)forward;
- (void)backward;
- (void)switchAspectRatio;

- (void)recoverDisplayedMetadata;

@end
