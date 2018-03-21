/*****************************************************************************
 * MLFile.h
 * Lunettes
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2010-2013 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import <CoreData/CoreData.h>
#if TARGET_OS_IOS
#import <CoreSpotlight/CoreSpotlight.h>
#endif
#if TARGET_OS_IPHONE
@class UIImage;
#endif

@class MLShowEpisode;
@class MLAlbumTrack;

extern NSString *kMLFileTypeMovie;
extern NSString *kMLFileTypeClip;
extern NSString *kMLFileTypeTVShowEpisode;
extern NSString *kMLFileTypeAudio;

extern NSString *const MLFileThumbnailWasUpdated;

@interface MLFile :  NSManagedObject

+ (NSArray *)allFiles;
+ (NSArray *)fileForURL:(NSURL *)url;

+ (instancetype)fileForURIRepresentation:(NSURL *)uriRepresentation;

- (BOOL)isKindOfType:(NSString *)type;
- (BOOL)isMovie;
- (BOOL)isClip;
- (BOOL)isShowEpisode;
- (BOOL)isAlbumTrack;
- (BOOL)isSupportedAudioFile;

@property (nonatomic, strong) NSNumber *seasonNumber;
@property (nonatomic, strong) NSNumber *remainingTime;
@property (nonatomic, strong) NSString *releaseYear;
@property (nonatomic, strong) NSNumber *lastPosition;
@property (nonatomic, strong) NSNumber *lastSubtitleTrack;
@property (nonatomic, strong) NSNumber *lastAudioTrack;
@property (nonatomic, strong) NSNumber *playCount;
@property (nonatomic, strong) NSString *artworkURL;
// on iOS the path relative to documents folder on OS X full path
// if you want to set path maybe set url instead which does the right thing depending on the OS
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *shortSummary;
@property (nonatomic, strong) NSNumber *currentlyWatching;
@property (nonatomic, strong) NSNumber *episodeNumber;
@property (nonatomic, strong) NSNumber *unread;
@property (nonatomic, strong) NSNumber *hasFetchedInfo;
@property (nonatomic, strong) NSNumber *noOnlineMetaData;
@property (nonatomic, strong) MLShowEpisode *showEpisode;
@property (nonatomic, strong) NSSet *labels;
@property (nonatomic, strong) NSSet *tracks;
@property (nonatomic, strong) NSNumber *isOnDisk;
@property (nonatomic, strong) NSNumber *duration;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *album;
@property (nonatomic, strong) NSNumber *albumTrackNumber;
@property (nonatomic, strong) NSNumber *folderTrackNumber;
@property (nonatomic, strong) NSString *genre;
@property (nonatomic, strong) MLAlbumTrack *albumTrack;
@property (nonatomic, strong) NSString *thumbnailName;
#if TARGET_OS_IPHONE
- (void)setComputedThumbnailScaledForDevice:(UIImage *)thumbnail;
@property (nonatomic, strong) UIImage *computedThumbnail;
#endif
@property (nonatomic, assign) BOOL isSafe;
@property (nonatomic, assign) BOOL isBeingParsed;
@property (nonatomic, assign) BOOL thumbnailTimeouted;

// always full URL, derived from path
// on Mac directly path as URL
// on iOS combined path appended MLMediaLibrary documentsFolder
@property (nonatomic, strong) NSURL *url;

/**
 * the data in this object are about to be put on screen
 *
 * If multiple MLFile object are processed, this
 * increase the priority of the processing for this MLFile.
 */
- (void)willDisplay;

/**
 * We don't display the data of this object on screen.
 *
 * This put back the eventually increased priority for this MLFile,
 * to a default one.
 * \see willDisplay
 */
- (void)didHide;

/**
 * do not rely on this path unless you are a MLKit object */
- (NSString *)thumbnailPath;

/**
 * Shortcuts to the videoTracks.
 */
- (NSManagedObject *)videoTrack;

- (size_t)fileSizeInBytes;

#if TARGET_OS_IOS
- (CSSearchableItemAttributeSet *)coreSpotlightAttributeSet;
- (void)updateCoreSpotlightEntry;
#endif

@end


@interface MLFile (CoreDataGeneratedAccessors)
- (void)addLabelsObject:(NSManagedObject *)value;
- (void)removeLabelsObject:(NSManagedObject *)value;
- (void)addLabels:(NSSet *)value;
- (void)removeLabels:(NSSet *)value;

- (void)addTracksObject:(NSManagedObject *)value;
- (void)removeTracksObject:(NSManagedObject *)value;
- (void)addTracks:(NSSet *)value;
- (void)removeTracks:(NSSet *)value;
@end

