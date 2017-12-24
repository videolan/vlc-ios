//
//  VLCMediaPlayer + Metadata.m
//  VLC
//
//  Created by Carola Nitz on 9/27/17.
//  Copyright © 2017 VideoLAN. All rights reserved.
//

#import "VLCMetadata.h"
#import <MediaPlayer/MediaPlayer.h>
#import "VLCPlaybackController.h"

#if TARGET_OS_IOS
#import "VLC_iOS-Swift.h"
#import "VLCThumbnailsCache.h"
#endif

@implementation VLCMetaData

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)updateMetadataFromMediaPlayer:(VLCMediaPlayer *)mediaPlayer;
{
#if TARGET_OS_IOS
    MLFile *item;

    self.trackNumber = nil;
    self.title = @"";
    self.artist = @"";
    self.albumName = @"";
    self.artworkImage = nil;
    self.isAudioOnly = NO;

    if ([VLCPlaybackController sharedInstance].mediaList) {
        NSArray *matches = [MLFile fileForURL:mediaPlayer.media.url];
        item = matches.firstObject;
    }

    if (item) {
        if (item.isAlbumTrack) {
            self.title = item.albumTrack.title;
            self.artist = item.albumTrack.artist;
            self.albumName = item.albumTrack.album.name;
        } else
            self.title = item.title;

        /* MLKit knows better than us if this thing is audio only or not */
        self.isAudioOnly = [item isSupportedAudioFile];
    } else {
#endif
        NSDictionary * metaDict = mediaPlayer.media.metaDictionary;

        if (metaDict) {
            self.title = metaDict[VLCMetaInformationNowPlaying] ? metaDict[VLCMetaInformationNowPlaying] : metaDict[VLCMetaInformationTitle];
            self.artist = metaDict[VLCMetaInformationArtist];
            self.albumName = metaDict[VLCMetaInformationAlbum];
            self.trackNumber = metaDict[VLCMetaInformationTrackNumber];
        }
#if TARGET_OS_IOS
    }
#endif

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

    if (self.isAudioOnly) {
#if TARGET_OS_IOS
        self.artworkImage = [VLCThumbnailsCache thumbnailForManagedObject:item];

        if (self.artworkImage) {
            if (self.artist)
                self.title = [self.title stringByAppendingFormat:@" — %@", self.artist];
            if (self.albumName)
                self.title = [self.title stringByAppendingFormat:@" — %@", self.albumName];
        }
#endif
        if (self.title.length < 1)
            self.title = [[mediaPlayer.media url] lastPathComponent];
    }
    self.playbackDuration = @(mediaPlayer.media.length.intValue / 1000.);
    self.playbackRate = @(mediaPlayer.rate);
    self.elapsedPlaybackTime = @(mediaPlayer.time.value.floatValue / 1000.);
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackMetadataDidChange object:self];
#if TARGET_OS_IOS
    if ([VLCKeychainCoordinator passcodeLockEnabled]) return;
#endif
    [self populateInfoCenterFromMetadata];
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
