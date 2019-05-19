/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017-2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@class VLCMLMedia;
@interface VLCMetaData: NSObject

@property(readwrite, copy) NSString *title;
@property(readwrite) UIImage *artworkImage;
@property(readwrite, copy) NSString *artist;
@property(readwrite, copy) NSString *albumName;
@property(readwrite, assign) BOOL isAudioOnly;
@property(readwrite) NSNumber *trackNumber;
@property(readwrite) NSNumber *playbackDuration;
@property(readwrite) NSNumber *elapsedPlaybackTime;
@property(readwrite) NSNumber *playbackRate;

#if TARGET_OS_IOS
- (void)updateMetadataFromMedia:(VLCMLMedia *)media mediaPlayer:(VLCMediaPlayer*)mediaPlayer;
#else
- (void)updateMetadataFromMediaPlayer:(VLCMediaPlayer *)mediaPlayer;
#endif
@end
