/*****************************************************************************
 * VLCMediaDataSource.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

@objc class VLCMediaDataSource: NSObject {

    override init() {
        super.init()
    }
}
//Todo: Move discoverer code here 


// Todo: implement the remove
//    - (void)removeMediaObjectFromFolder:(NSManagedObject *)managedObject
// {
//    NSAssert(([managedObject isKindOfClass:[MLFile class]] && ((MLFile *)managedObject).labels.count > 0), @"All media in a folder should be of type MLFile and it should be in a folder");
//
//    if (![managedObject isKindOfClass:[MLFile class]]) return;
//
//    MLFile *mediaFile = (MLFile *)managedObject;
//    [self rearrangeFolderTrackNumbersForRemovedItem:mediaFile];
//    mediaFile.labels = nil;
//    mediaFile.folderTrackNumber = nil;
//    }
//
//    - (void)removeMediaObject:(NSManagedObject *)managedObject
// {
//    if ([managedObject isKindOfClass:[MLAlbum class]]) {
//        MLAlbum *album = (MLAlbum *)managedObject;
//        NSSet *iterAlbumTrack = [NSSet setWithSet:album.tracks];
//
//        for (MLAlbumTrack *track in iterAlbumTrack) {
//            NSSet *iterFiles = [NSSet setWithSet:track.files];
//
//            for (MLFile *file in iterFiles)
//                [self _deleteMediaObject:file];
//        }
//        [[MLMediaLibrary sharedMediaLibrary] removeObject: album];
//        // delete all episodes from a show
//    } else if ([managedObject isKindOfClass:[MLShow class]]) {
//        MLShow *show = (MLShow *)managedObject;
//        NSSet *iterShowEpisodes = [NSSet setWithSet:show.episodes];
//
//        for (MLShowEpisode *episode in iterShowEpisodes) {
//            NSSet *iterFiles = [NSSet setWithSet:episode.files];
//
//            for (MLFile *file in iterFiles)
//                [self _deleteMediaObject:file];
//        }
//        [[MLMediaLibrary sharedMediaLibrary] removeObject: show];
//        // delete all files from an episode
//    } else if ([managedObject isKindOfClass:[MLShowEpisode class]]) {
//        MLShowEpisode *episode = (MLShowEpisode *)managedObject;
//        NSSet *iterFiles = [NSSet setWithSet:episode.files];
//
//        for (MLFile *file in iterFiles)
//            [self _deleteMediaObject:file];
//        // delete all files from a track
//        [[MLMediaLibrary sharedMediaLibrary] removeObject: episode];
//    } else if ([managedObject isKindOfClass:[MLAlbumTrack class]]) {
//        MLAlbumTrack *track = (MLAlbumTrack *)managedObject;
//        NSSet *iterFiles = [NSSet setWithSet:track.files];
//
//        for (MLFile *file in iterFiles)
//            [self _deleteMediaObject:file];
//    } else if ([managedObject isKindOfClass:[MLLabel class]]) {
//        MLLabel *folder = (MLLabel *)managedObject;
//        NSSet *iterFiles = [NSSet setWithSet:folder.files];
//        [folder removeFiles:folder.files];
//        for (MLFile *file in iterFiles)
//            [self _deleteMediaObject:file];
//        [[MLMediaLibrary sharedMediaLibrary] removeObject:folder];
//    }
//    else
//    [self _deleteMediaObject:(MLFile *)managedObject];
//    }
//
//    - (void)_deleteMediaObject:(MLFile *)mediaObject
// {
//    [self rearrangeFolderTrackNumbersForRemovedItem:mediaObject];
//
//    /* stop playback if needed */
//    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
//    VLCMedia *media = [vpc currentlyPlayingMedia];
//    MLFile *currentlyPlayingFile = [MLFile fileForURL:media.url].firstObject;
//    if (currentlyPlayingFile && currentlyPlayingFile == mediaObject) {
//        [vpc stopPlayback];
//    }
//
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSString *folderLocation = [[mediaObject.url path] stringByDeletingLastPathComponent];
//    NSArray *allfiles = [fileManager contentsOfDirectoryAtPath:folderLocation error:nil];
//    NSString *fileName = [mediaObject.path.lastPathComponent stringByDeletingPathExtension];
//    if (!fileName)
//    return;
//    NSIndexSet *indexSet = [allfiles indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
//        return ([obj rangeOfString:fileName].location != NSNotFound);
//        }];
//    NSUInteger count = indexSet.count;
//    NSString *additionalFilePath;
//    NSUInteger currentIndex = [indexSet firstIndex];
//    for (unsigned int x = 0; x < count; x++) {
//        additionalFilePath = allfiles[currentIndex];
//        if ([additionalFilePath isSupportedSubtitleFormat])
//        [fileManager removeItemAtPath:[folderLocation stringByAppendingPathComponent:additionalFilePath] error:nil];
//        currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
//    }
//    [fileManager removeItemAtURL:mediaObject.url error:nil];
//    }
//
//    - (void)rearrangeFolderTrackNumbersForRemovedItem:(MLFile *) mediaObject
// {
//    MLLabel *label = [mediaObject.labels anyObject];
//    NSSet *allFiles = label.files;
//    for (MLFile *file in allFiles) {
//        if (file.folderTrackNumber > mediaObject.folderTrackNumber) {
//            int value = [file.folderTrackNumber intValue];
//            file.folderTrackNumber = [NSNumber numberWithInt:value - 1];
//        }
//    }
// }
// @end
