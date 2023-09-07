/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017-2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMetadata.h"
#import <MediaPlayer/MediaPlayer.h>
#import "VLCPlaybackService.h"

#if TARGET_OS_IOS
#import "VLC-Swift.h"
#endif

@implementation VLCMetaData

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.trackNumber = nil;
        self.title = @"";
        self.artist = @"";
        self.albumName = @"";
        self.artworkImage = nil;
        self.isAudioOnly = NO;
        self.identifier = nil;
    }
    return self;
}
#if TARGET_OS_TV
- (void)updateMetadataFromMediaPlayer:(VLCMediaPlayer *)mediaPlayer;
{
    [self updateMetadataFromMediaPlayerFortvOS:mediaPlayer];
}
#endif

#if TARGET_OS_IOS
- (void)updateMetadataFromMedia:(VLCMLMedia *)media mediaPlayer:(VLCMediaPlayer*)mediaPlayer
{
    if (media && !media.isExternalMedia) {
        self.title = media.title;
        self.artist = media.artist.name;
        self.trackNumber = @(media.trackNumber);
        self.albumName = media.album.title;
        self.artworkImage = [media thumbnailImage];
        self.isAudioOnly = ([media subtype] == VLCMLMediaSubtypeAlbumTrack || media.videoTracks.count == 0) ? YES : NO;
        self.identifier = @(media.identifier);
    } else { // We're streaming something
        [self fillFromMetaDict:mediaPlayer];
        if (!self.artworkImage) {
            BOOL isDarktheme = PresentationTheme.current.isDark;
            self.artworkImage = isDarktheme ? [UIImage imageNamed:@"song-placeholder-dark"]
                                            : [UIImage imageNamed:@"song-placeholder-white"];
        }

        [self checkIsAudioOnly:mediaPlayer];
    }

    self.descriptiveTitle = nil;
    if (self.isAudioOnly) {
        if (self.artworkImage) {
            if (self.artist)
                self.descriptiveTitle = [self.title stringByAppendingFormat:@" — %@", self.artist];
            if (self.albumName)
                self.descriptiveTitle = [self.title stringByAppendingFormat:@" — %@", self.albumName];
        }
        if (self.title.length < 1)
            self.title = [[mediaPlayer.media url] lastPathComponent];
    }
    [self updatePlaybackRate:mediaPlayer];

    //Down here because we still need to populate the miniplayer
    if ([VLCKeychainCoordinator passcodeLockEnabled]) return;

    [self populateInfoCenterFromMetadata];
}
#else

- (void)updateMetadataFromMediaPlayerFortvOS:(VLCMediaPlayer *)mediaPlayer
{
    [self fillFromMetaDict:mediaPlayer];
    [self checkIsAudioOnly:mediaPlayer];

    if (self.isAudioOnly) {
        if (self.title.length < 1)
            self.title = [[mediaPlayer.media url] lastPathComponent];
    }
    [self updatePlaybackRate:mediaPlayer];
    [self populateInfoCenterFromMetadata];
}
#endif

- (void)updateExposedTimingFromMediaPlayer:(VLCMediaPlayer*)mediaPlayer
{
    /* just update the timing data and used the cached rest for the update
     * regrettably, in contrast to macOS, we always need to deliver the full dictionary */
    self.elapsedPlaybackTime = @(mediaPlayer.time.value.floatValue / 1000.);
    self.position = @(mediaPlayer.position);

    [self populateInfoCenterFromMetadata];
}

- (void)updatePlaybackRate:(VLCMediaPlayer *)mediaPlayer
{
    self.playbackDuration = @(mediaPlayer.media.length.intValue / 1000.);
    self.playbackRate = @(mediaPlayer.rate);
    VLCTime *elapsedPlaybackTime = mediaPlayer.time;
    if (elapsedPlaybackTime) {
        self.elapsedPlaybackTime = @(elapsedPlaybackTime.value.floatValue / 1000.);
    }
    self.position = @(mediaPlayer.position);

    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackMetadataDidChange object:self];
}

- (void)checkIsAudioOnly:(VLCMediaPlayer *)mediaPlayer
{
    _isAudioOnly = mediaPlayer.numberOfVideoTracks == 0;
}

- (void)fillFromMetaDict:(VLCMediaPlayer *)mediaPlayer
{
    VLCMediaMetaData *metadata = mediaPlayer.media.metaData;

    if (metadata) {
        if (metadata.nowPlaying != nil) {
            self.title = metadata.nowPlaying;
        } else {
            self.title = metadata.title;
        }
        self.artist = metadata.artist;
        self.albumName = metadata.album;
        self.trackNumber = @(metadata.trackNumber);
        self.artworkImage = nil;

        NSURL *artworkURL = metadata.artworkURL;
        if (artworkURL) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                NSData *imageData = [NSData dataWithContentsOfURL:artworkURL];
                if (imageData) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.artworkImage = [UIImage imageWithData:imageData];
                        [[VLCPlaybackService sharedInstance] recoverDisplayedMetadata];
#if TARGET_OS_IOS
                        if ([VLCKeychainCoordinator passcodeLockEnabled])
                            return;
#endif
                        [self populateInfoCenterFromMetadata];
                    });
                }
            });
        }
    }
}

- (void)populateInfoCenterFromMetadata
{
    NSMutableDictionary *currentlyPlayingTrackInfo = [NSMutableDictionary dictionary];
    NSNumber *duration = self.playbackDuration;
    currentlyPlayingTrackInfo[MPMediaItemPropertyPlaybackDuration] = duration;
    if (@available(iOS 10.0, *)) {
        currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyIsLiveStream] = @(duration.intValue <= 0);
        currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyMediaType] = _isAudioOnly ? @(MPNowPlayingInfoMediaTypeAudio) : @(MPNowPlayingInfoMediaTypeVideo);
        currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyPlaybackProgress] = self.position;
        currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyExternalContentIdentifier] = self.identifier;
    }
    currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.elapsedPlaybackTime;
    currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.playbackRate;

    currentlyPlayingTrackInfo[MPMediaItemPropertyTitle] = self.title;
    currentlyPlayingTrackInfo[MPMediaItemPropertyArtist] = self.artist;
    currentlyPlayingTrackInfo[MPMediaItemPropertyAlbumTitle] = self.albumName;

    if ([self.trackNumber intValue] > 0)
        currentlyPlayingTrackInfo[MPMediaItemPropertyAlbumTrackNumber] = self.trackNumber;

#if TARGET_OS_IOS
    if (self.artworkImage) {
        MPMediaItemArtwork *mpartwork;
        if (@available(iOS 10.0, *)) {
            mpartwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:self.artworkImage.size
                                                        requestHandler:^UIImage * _Nonnull(CGSize size) {
                return self.artworkImage;
            }];
        } else {
            mpartwork = [[MPMediaItemArtwork alloc] initWithImage:self.artworkImage];
        }
        @try {
            currentlyPlayingTrackInfo[MPMediaItemPropertyArtwork] = mpartwork;
        } @catch (NSException *exception) {
            currentlyPlayingTrackInfo[MPMediaItemPropertyArtwork] = nil;
        }
    }
#endif

    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = currentlyPlayingTrackInfo;
}

@end
