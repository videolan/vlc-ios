/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017-2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@class VLCMLMedia;
@interface VLCMetaData: NSObject

NS_ASSUME_NONNULL_BEGIN

@property(readwrite, copy, nullable) NSString *title;
@property(readwrite, copy, nullable) NSString *descriptiveTitle;
@property(readwrite, nullable) UIImage *artworkImage;
@property(readwrite, copy, nullable) NSString *artist;
@property(readwrite, copy, nullable) NSString *albumName;
@property(readwrite, assign) BOOL isAudioOnly;
@property(readwrite, copy, nullable) NSString *genre;
@property(readwrite, nullable) NSNumber *trackNumber;
@property(readwrite, nullable) NSNumber *albumTrackCount;
@property(readwrite, nullable) NSNumber *discNumber;
@property(readwrite, nullable) NSNumber *playbackDuration;
@property(readwrite, nullable) NSNumber *elapsedPlaybackTime;
@property(readwrite, nullable) NSNumber *playbackRate;
@property(readwrite, nullable) NSNumber *position;
@property(readwrite, nullable) NSNumber *identifier;
@property(readwrite, assign) BOOL isLiveStream;

- (void)updateMetadataFromMedia:(nullable VLCMLMedia *)media mediaPlayer:(VLCMediaPlayer*)mediaPlayer;

- (void)updateExposedTimingFromMediaPlayer:(VLCMediaPlayer*)mediaPlayer;

- (void)resetExposedTimingWithDuration:(NSNumber *)duration;

NS_ASSUME_NONNULL_END

@end
