/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017-2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMetadata.h"
#import <ImageIO/ImageIO.h>
#import <MediaPlayer/MediaPlayer.h>
#import "VLCPlaybackService.h"

#import "VLC-Swift.h"

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
        self.isLiveStream = NO;
    }
    return self;
}
- (void)updateMetadataFromMedia:(nullable VLCMLMedia *)media mediaPlayer:(VLCMediaPlayer*)mediaPlayer
{
    if (media && !media.isExternalMedia) {
        self.title = media.title;
        self.artist = media.artist.name;
        self.genre = media.genre.name;
        self.trackNumber = @(media.trackNumber);
        self.albumTrackCount = @(media.album.numberOfTracks);
        self.discNumber = @(media.discNumber);
        self.albumName = media.album.title;
        self.artworkImage = [media thumbnailImage];
        self.isAudioOnly = ([media subtype] == VLCMLMediaSubtypeAlbumTrack || media.videoTracks.count == 0) ? YES : NO;
        self.identifier = @(media.identifier);
    } else { // We're streaming something
        [self fillFromMetaDict:mediaPlayer];
        if (!self.artworkImage) {
#if TARGET_OS_WATCH
            self.artworkImage = [UIImage imageNamed:@"song-placeholder-dark"];
#else
            BOOL isDarktheme = PresentationTheme.current.isDark;
            self.artworkImage = isDarktheme ? [UIImage imageNamed:@"song-placeholder-dark"]
                                            : [UIImage imageNamed:@"song-placeholder-white"];
#endif
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

#if !TARGET_OS_WATCH && !TARGET_OS_TV
    //Down here because we still need to populate the miniplayer
    if ([[VLCKeychainCoordinator passcodeService] hasSecret]) return;
#endif

    [self populateInfoCenterFromMetadata];
}

- (void)updateExposedTimingFromMediaPlayer:(VLCMediaPlayer*)mediaPlayer
{
    /* just update the timing data and used the cached rest for the update
     * regrettably, in contrast to macOS, we always need to deliver the full dictionary */
    self.elapsedPlaybackTime = @(mediaPlayer.time.value.floatValue / 1000.);
    self.position = @(mediaPlayer.position);

    [self populateInfoCenterFromMetadata];
}

- (void)resetExposedTimingWithDuration:(NSNumber *)duration
{
    self.playbackDuration = duration;
    self.isLiveStream = duration.intValue <= 0;
    self.elapsedPlaybackTime = @(0);
    self.position = @(0);

#if !TARGET_OS_WATCH && !TARGET_OS_TV
    if ([[VLCKeychainCoordinator passcodeService] hasSecret]) return;
#endif

    [self populateInfoCenterFromMetadata];
}

- (void)updatePlaybackRate:(VLCMediaPlayer *)mediaPlayer
{
    self.playbackDuration = @(mediaPlayer.media.length.value.longLongValue / 1000.);
    self.isLiveStream = self.playbackDuration.intValue <= 0;
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
    NSArray *videoTracks = [mediaPlayer videoTracks];
    _isAudioOnly = videoTracks.count == 0;
}

- (void)fillFromMetaDict:(VLCMediaPlayer *)mediaPlayer
{
    VLCMediaMetaData *metadata = mediaPlayer.media.metaData;
    VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];

    if (metadata) {
        if (metadata.nowPlaying != nil) {
            self.title = metadata.nowPlaying;
        } else {
            self.title = metadata.title;
        }
        self.artist = metadata.artist;
        self.albumName = metadata.album;
        self.genre = metadata.genre;
        self.trackNumber = @(metadata.trackNumber);
        self.albumTrackCount = @(metadata.trackTotal);
        self.discNumber = @(metadata.discNumber);
        self.artworkImage = metadata.artwork;

        NSURL *artworkURL = metadata.artworkURL;
        if (!self.artworkImage && artworkURL) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                NSData *imageData = [NSData dataWithContentsOfURL:artworkURL];
                if (imageData) {
                    UIImage *artworkImage = [self downsampledArtworkImageFromData:imageData];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.artworkImage = artworkImage;
                        [playbackService recoverDisplayedMetadata];
#if TARGET_OS_IOS
                        if ([[VLCKeychainCoordinator passcodeService] hasSecret])
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
    VLCPlaybackService *playbackService = [VLCPlaybackService sharedInstance];
    NSNumber *duration = self.playbackDuration;
    currentlyPlayingTrackInfo[MPMediaItemPropertyPlaybackDuration] = duration;
    BOOL isLiveStream = duration.intValue <= 0;
    currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyIsLiveStream] = @(isLiveStream);
    self.isLiveStream = isLiveStream;
    currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyMediaType] = _isAudioOnly ? @(MPNowPlayingInfoMediaTypeAudio) : @(MPNowPlayingInfoMediaTypeVideo);
    currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyPlaybackProgress] = self.position;
    currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyExternalContentIdentifier] = self.identifier;
    if (isLiveStream)
        currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyCurrentPlaybackDate] = [NSDate date];
    currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.elapsedPlaybackTime;
    currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.playbackRate;
    CGFloat configuredDefaultRate = playbackService.defaultPlaybackRate;
    currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = @(configuredDefaultRate > 0 ? configuredDefaultRate : 1.0);

    currentlyPlayingTrackInfo[MPMediaItemPropertyTitle] = self.title;
    currentlyPlayingTrackInfo[MPMediaItemPropertyArtist] = self.artist;
    currentlyPlayingTrackInfo[MPMediaItemPropertyAlbumTitle] = self.albumName;

    if ([self.trackNumber intValue] > 0)
        currentlyPlayingTrackInfo[MPMediaItemPropertyAlbumTrackNumber] = self.trackNumber;

    if (self.genre.length > 0)
        currentlyPlayingTrackInfo[MPMediaItemPropertyGenre] = self.genre;

    if ([self.albumTrackCount intValue] > 0)
        currentlyPlayingTrackInfo[MPMediaItemPropertyAlbumTrackCount] = self.albumTrackCount;

    if ([self.discNumber intValue] > 0)
        currentlyPlayingTrackInfo[MPMediaItemPropertyDiscNumber] = self.discNumber;

    NSInteger chapterCount = playbackService.numberOfChaptersForCurrentTitle;
    if (chapterCount > 1) {
        currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyChapterCount] = @(chapterCount);
        currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyChapterNumber] = @(MAX(0, playbackService.indexOfCurrentChapter));
    }

    if (self.artworkImage) {
        MPMediaItemArtwork *mpartwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:self.artworkImage.size
                                                                        requestHandler:^UIImage * _Nonnull(CGSize size) {
            return self.artworkImage;
        }];
        @try {
            currentlyPlayingTrackInfo[MPMediaItemPropertyArtwork] = mpartwork;
        } @catch (NSException *exception) {
            currentlyPlayingTrackInfo[MPMediaItemPropertyArtwork] = nil;
        }
    }

    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = currentlyPlayingTrackInfo;
}

- (UIImage *)downsampledArtworkImageFromData:(NSData *)imageData
{
    const CGFloat maxPixelSize = 1024.f;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    if (source == NULL) {
        return nil;
    }

    NSDictionary *options = @{
        (__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
        (__bridge NSString *)kCGImageSourceCreateThumbnailWithTransform: @YES,
        (__bridge NSString *)kCGImageSourceShouldCache: @NO,
        (__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize: @(maxPixelSize)
    };

    CGImageRef cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    CFRelease(source);

    if (cgImage == NULL) {
        return nil;
    }

    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}

@end
