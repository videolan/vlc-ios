/*****************************************************************************
 * VLCMediaDataSource.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors:Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMediaDataSource.h"
#import "VLCPlaybackController.h"
#import "NSString+SupportedMedia.h"

@interface VLCMediaDataSource ()
{
    NSMutableArray *_foundMedia;
    NSManagedObject *_currentSelection;
}
@end

@implementation VLCMediaDataSource

- (void)updateContentsForSelection:(NSManagedObject *)selection
{
    NSArray *array = [NSMutableArray new];
    if ([selection isKindOfClass:[MLAlbum class]]) {
        array = [(MLAlbum *)selection sortedTracks];
    } else if ([selection isKindOfClass:[MLShow class]]) {
        array =  [(MLShow *)selection sortedEpisodes];
    } else if ([selection isKindOfClass:[MLLabel class]]) {
        array = [(MLLabel *)selection sortedFolderItems];
    }
    _currentSelection = selection;
    _foundMedia = [NSMutableArray arrayWithArray:array];
}

- (NSManagedObject *)currentSelection
{
    return _currentSelection;
}

- (NSUInteger)numberOfFiles
{
    return [_foundMedia count];
}

- (NSManagedObject *)objectAtIndex:(NSUInteger)index
{
    if (index < _foundMedia.count)
        return  _foundMedia[index];
    return nil;
}

- (NSUInteger)indexOfObject:(NSManagedObject *)object
{
    return [_foundMedia indexOfObject:object];
}

- (void)insertObject:(NSManagedObject *)object atIndex:(NSUInteger)index
{
    [_foundMedia insertObject:object atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [_foundMedia removeObjectAtIndex:index];
}

- (void)moveObjectFromIndex:(NSUInteger)fromIdx toIndex:(NSUInteger)toIdx
{
    MLFile* object = _foundMedia[fromIdx];
    if (![object isKindOfClass:[MLFile class]])
        return;
    [_foundMedia removeObjectAtIndex:fromIdx];
    [_foundMedia insertObject:object atIndex:toIdx];
    object.folderTrackNumber = @(toIdx - 1);
    object = [_foundMedia objectAtIndex:fromIdx];
    if (![object isKindOfClass:[MLFile class]])
        return;
    object.folderTrackNumber = @(fromIdx - 1);
}

- (void)removeAllObjects
{
    _foundMedia = [NSMutableArray new];
}

- (NSArray *)allObjects
{
    return [_foundMedia copy];
}

- (void)addObject:(NSManagedObject *)object
{
    [_foundMedia addObject:object];
}

- (void)addAlbumsInAllAlbumMode:(BOOL)isAllAlbumMode;
{
    for (MLAlbum *album in [MLAlbum allAlbums]) {
        if (album.name.length > 0) {
            if (isAllAlbumMode) {
                [self addObject:album];
            } else if ( album.tracks.count > 1) {
                [self addObject:album];
            }
        }
    }
}

- (void)addAllShows
{
    for (MLShow *show in [MLShow allShows]) {
        if (show.name.length > 0 && show.episodes.count > 1) {
            [self addObject:show];
        }
    }
}

- (void)addAllFolders
{
    for (MLLabel *folder in [MLLabel allLabels]) {
        [self addObject:folder];
    }
}

- (void)addRemainingFiles
{
    for (MLFile *file in [MLFile allFiles]) {
        if (file.labels != nil) {
            if (file.labels.count > 0)
                continue;
        }

        if (!file.isShowEpisode && !file.isAlbumTrack) {
             [self addObject:file];
        } else if (file.isShowEpisode) {
            if (file.showEpisode.show.episodes.count < 2) {
                [self addObject:file];
            }

            /* older MediaLibraryKit versions don't send a show name in a popular
             * corner case. hence, we need to work-around here and force a reload
             * afterwards as this could lead to the 'all my shows are gone'
             * syndrome (see #10435, #10464, #10432 et al) */
            if (file.showEpisode.show.name.length == 0) {
                file.showEpisode.show.name = NSLocalizedString(@"UNTITLED_SHOW", nil);
                [self updateContentsForSelection:_currentSelection];
            }
        } else if (file.isAlbumTrack && file.albumTrack.album.tracks.count < 2) {
            [self addObject:file];
        }
    }
}

- (void)removeMediaObjectFromFolder:(NSManagedObject *)managedObject
{
    NSAssert(([managedObject isKindOfClass:[MLFile class]] && ((MLFile *)managedObject).labels.count > 0), @"All media in a folder should be of type MLFile and it should be in a folder");

    if (![managedObject isKindOfClass:[MLFile class]]) return;

    MLFile *mediaFile = (MLFile *)managedObject;
    [self rearrangeFolderTrackNumbersForRemovedItem:mediaFile];
    mediaFile.labels = nil;
    mediaFile.folderTrackNumber = nil;
}

- (void)removeMediaObject:(NSManagedObject *)managedObject
{
    if ([managedObject isKindOfClass:[MLAlbum class]]) {
        MLAlbum *album = (MLAlbum *)managedObject;
        NSSet *iterAlbumTrack = [NSSet setWithSet:album.tracks];

        for (MLAlbumTrack *track in iterAlbumTrack) {
            NSSet *iterFiles = [NSSet setWithSet:track.files];

            for (MLFile *file in iterFiles)
                [self _deleteMediaObject:file];
        }
        [[MLMediaLibrary sharedMediaLibrary] removeObject: album];
        // delete all episodes from a show
    } else if ([managedObject isKindOfClass:[MLShow class]]) {
        MLShow *show = (MLShow *)managedObject;
        NSSet *iterShowEpisodes = [NSSet setWithSet:show.episodes];

        for (MLShowEpisode *episode in iterShowEpisodes) {
            NSSet *iterFiles = [NSSet setWithSet:episode.files];

            for (MLFile *file in iterFiles)
                [self _deleteMediaObject:file];
        }
        [[MLMediaLibrary sharedMediaLibrary] removeObject: show];
        // delete all files from an episode
    } else if ([managedObject isKindOfClass:[MLShowEpisode class]]) {
        MLShowEpisode *episode = (MLShowEpisode *)managedObject;
        NSSet *iterFiles = [NSSet setWithSet:episode.files];

        for (MLFile *file in iterFiles)
            [self _deleteMediaObject:file];
        // delete all files from a track
        [[MLMediaLibrary sharedMediaLibrary] removeObject: episode];
    } else if ([managedObject isKindOfClass:[MLAlbumTrack class]]) {
        MLAlbumTrack *track = (MLAlbumTrack *)managedObject;
        NSSet *iterFiles = [NSSet setWithSet:track.files];

        for (MLFile *file in iterFiles)
            [self _deleteMediaObject:file];
    } else if ([managedObject isKindOfClass:[MLLabel class]]) {
        MLLabel *folder = (MLLabel *)managedObject;
        NSSet *iterFiles = [NSSet setWithSet:folder.files];
        [folder removeFiles:folder.files];
        for (MLFile *file in iterFiles)
            [self _deleteMediaObject:file];
        [[MLMediaLibrary sharedMediaLibrary] removeObject:folder];
    }
    else
        [self _deleteMediaObject:(MLFile *)managedObject];
}

- (void)_deleteMediaObject:(MLFile *)mediaObject
{
    [self rearrangeFolderTrackNumbersForRemovedItem:mediaObject];

    /* stop playback if needed */
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    VLCMedia *media = [vpc currentlyPlayingMedia];
    MLFile *currentlyPlayingFile = [MLFile fileForURL:media.url].firstObject;
    if (currentlyPlayingFile && currentlyPlayingFile == mediaObject) {
        [vpc stopPlayback];
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folderLocation = [[mediaObject.url path] stringByDeletingLastPathComponent];
    NSArray *allfiles = [fileManager contentsOfDirectoryAtPath:folderLocation error:nil];
    NSString *fileName = [mediaObject.path.lastPathComponent stringByDeletingPathExtension];
    if (!fileName)
        return;
    NSIndexSet *indexSet = [allfiles indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return ([obj rangeOfString:fileName].location != NSNotFound);
    }];
    NSUInteger count = indexSet.count;
    NSString *additionalFilePath;
    NSUInteger currentIndex = [indexSet firstIndex];
    for (unsigned int x = 0; x < count; x++) {
        additionalFilePath = allfiles[currentIndex];
        if ([additionalFilePath isSupportedSubtitleFormat])
            [fileManager removeItemAtPath:[folderLocation stringByAppendingPathComponent:additionalFilePath] error:nil];
        currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    [fileManager removeItemAtURL:mediaObject.url error:nil];
}

- (void)rearrangeFolderTrackNumbersForRemovedItem:(MLFile *) mediaObject
{
    MLLabel *label = [mediaObject.labels anyObject];
    NSSet *allFiles = label.files;
    for (MLFile *file in allFiles) {
        if (file.folderTrackNumber > mediaObject.folderTrackNumber) {
            int value = [file.folderTrackNumber intValue];
            file.folderTrackNumber = [NSNumber numberWithInt:value - 1];
        }
    }
}
@end
