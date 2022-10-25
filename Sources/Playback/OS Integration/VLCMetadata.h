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
@property(readwrite, nullable) NSNumber *trackNumber;
@property(readwrite, nullable) NSNumber *playbackDuration;
@property(readwrite, nullable) NSNumber *elapsedPlaybackTime;
@property(readwrite, nullable) NSNumber *playbackRate;
@property(readwrite, nullable) NSNumber *position;
@property(readwrite, nullable) NSNumber *identifier;
@property(readwrite, assign) BOOL isLiveStream;

#if TARGET_OS_IOS || TARGET_OS_VISION
- (void)updateMetadataFromMedia:(VLCMLMedia *)media mediaPlayer:(VLCMediaPlayer*)mediaPlayer;
#else
- (void)updateMetadataFromMediaPlayer:(VLCMediaPlayer *)mediaPlayer;
#endif

- (void)updateExposedTimingFromMediaPlayer:(VLCMediaPlayer*)mediaPlayer;

NS_ASSUME_NONNULL_END

@end
