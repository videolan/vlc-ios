/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMetadata.h"
#import <MediaPlayer/MediaPlayer.h>
#import "VLCPlaybackController.h"

#if TARGET_OS_IOS
#import "VLC-Swift.h"
#import "VLCThumbnailsCache.h"
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
    if (media) {
        self.title = media.title;
        self.artist = media.albumTrack.artist.name;
        self.trackNumber = @(media.albumTrack.trackNumber);
        self.albumName = media.albumTrack.album.title;
        self.artworkImage = [media thumbnailImage];
        self.isAudioOnly = [media subtype] == VLCMLMediaSubtypeAlbumTrack;
    } else { // We're streaming something
        self.artworkImage = nil;
        self.trackNumber = nil;
        self.artist = nil;
        self.albumName = nil;
        [self fillFromMetaDict:mediaPlayer];
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
- (void)updatePlaybackRate:(VLCMediaPlayer *)mediaPlayer
{
    self.playbackDuration = @(mediaPlayer.media.length.intValue / 1000.);
    self.playbackRate = @(mediaPlayer.rate);
    self.elapsedPlaybackTime = @(mediaPlayer.time.value.floatValue / 1000.);
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackMetadataDidChange object:self];
}

- (void)checkIsAudioOnly:(VLCMediaPlayer *)mediaPlayer
{
    if (!self.isAudioOnly) {
        /* either what we are playing is not a file known to MLKit or
         * MLKit fails to acknowledge that it is audio-only.
         * Either way, do a more expensive check to see if it is really audio-only */
        NSArray *tracks = mediaPlayer.media.tracksInformation;
        NSUInteger trackCount = tracks.count;
        self.isAudioOnly = YES;
        for (NSUInteger x = 0 ; x < trackCount; x++) {
            if ([[tracks[x] objectForKey:VLCMediaTracksInformationType] isEqualToString:VLCMediaTracksInformationTypeVideo]) {
                self.isAudioOnly = NO;
                break;
            }
        }
    }
}

- (void)fillFromMetaDict:(VLCMediaPlayer *)mediaPlayer
{
    NSDictionary *metaDict = mediaPlayer.media.metaDictionary;

    if (metaDict) {
        self.title = metaDict[VLCMetaInformationNowPlaying] ?: metaDict[VLCMetaInformationTitle];
        self.artist = metaDict[VLCMetaInformationArtist];
        self.albumName = metaDict[VLCMetaInformationAlbum];
        self.trackNumber = metaDict[VLCMetaInformationTrackNumber];
    }
}

- (void)populateInfoCenterFromMetadata
{
    NSMutableDictionary *currentlyPlayingTrackInfo = [NSMutableDictionary dictionary];
    currentlyPlayingTrackInfo[MPMediaItemPropertyPlaybackDuration] = self.playbackDuration;
    currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.elapsedPlaybackTime;
    currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.playbackRate;

    currentlyPlayingTrackInfo[MPMediaItemPropertyTitle] = self.title;
    currentlyPlayingTrackInfo[MPMediaItemPropertyArtist] = self.artist;
    currentlyPlayingTrackInfo[MPMediaItemPropertyAlbumTitle] = self.albumName;

    if ([self.trackNumber intValue] > 0)
        currentlyPlayingTrackInfo[MPMediaItemPropertyAlbumTrackNumber] = self.trackNumber;

#if TARGET_OS_IOS
    if (self.artworkImage) {
        MPMediaItemArtwork *mpartwork = [[MPMediaItemArtwork alloc] initWithImage:self.artworkImage];
        currentlyPlayingTrackInfo[MPMediaItemPropertyArtwork] = mpartwork;
    }
#endif

    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = currentlyPlayingTrackInfo;
}

@end
