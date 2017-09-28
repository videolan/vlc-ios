//
//  VLCMediaPlayer + Metadata.h
//  VLC
//
//  Created by Carola Nitz on 9/27/17.
//  Copyright © 2017 VideoLAN. All rights reserved.
//

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

- (void)updateMetadataFromMediaPlayer:(VLCMediaPlayer *)mediaPlayer;
@end
