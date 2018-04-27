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

@objc enum VLCMediaCategory: Int {
    case unknown
    case audio
    case video
}

@objc enum VLCMediaSubcategory: Int {
    case unknown
    case movies
    case episodes
    case artists
    case albums
    case tracks
    case genres
    case videoPlaylists
    case audioPlaylists
    case allVideos
}

struct VLCMediaType {
    let category: VLCMediaCategory
    var subcategory: VLCMediaSubcategory
}

@objc class VLCMediaDataSource: NSObject {

    var foundVideos = [MLFile]()
    var foundAudio = [MLFile]()

    var movies = [MLFile]()
    var episodes = [MLFile]()
    var artists = [MLFile]()
    var albums = [MLFile]()
    var tracks = [MLFile]() // might be just foundAudio
    var genres = [MLFile]()
    var audioPlaylist = [MLFile]()
    var videoPlaylist = [MLFile]()
    var allVideos = [MLFile]() // might be just foundVideo

    override init() {
        super.init()
        getAllVideos()
        getAllAudio()
    }

    @objc func numberOfFiles(subcategory: VLCMediaSubcategory) -> Int {
        return array(for: subcategory).count
    }

    private func array(for subcategory: VLCMediaSubcategory ) -> [MLFile] {
        switch subcategory {
        case .unknown:
            preconditionFailure("No")
        case .movies:
            preconditionFailure("TODO")
            return movies
        case .episodes:
            preconditionFailure("TODO")
            return episodes
        case .artists:
            preconditionFailure("TODO")
            return artists
        case .albums:
            preconditionFailure("TODO")
            return albums
        case .tracks:
            return tracks
        case .genres:
            preconditionFailure("TODO")
            return genres
        case .audioPlaylists:
            preconditionFailure("TODO")
            return audioPlaylist
        case .videoPlaylists:
            preconditionFailure("TODO")
            return videoPlaylist
        case .allVideos:
            return allVideos
        }
    }
    @objc func object(at index: Int, subcategory: VLCMediaSubcategory) -> NSManagedObject {

        guard index >= 0 else {
            preconditionFailure("a negative value ? I don't think so!")
        }

        let categoryArray = array(for: subcategory)
        if index < categoryArray.count {
            return categoryArray[Int(index)]
        }
        preconditionFailure("index is taller than count")
    }

    func allObjects(for subcategory: VLCMediaSubcategory) -> [MLFile] {
        return array(for:subcategory)
    }

    internal func removeObject(at index: Int, subcategory: VLCMediaSubcategory) {
        guard index >= 0 else {
            preconditionFailure("a negative value ? I don't think so!")
        }
        var categoryArray = array(for: subcategory)
        if index < categoryArray.count {
            categoryArray.remove(at: index)
        }
        preconditionFailure("index is taller than count")
    }

    internal func insert(_ item: MLFile, at index: Int, subcategory: VLCMediaSubcategory) {
        guard index >= 0 else {
            preconditionFailure("a negative value ? I don't think so!")
        }
        var categoryArray = array(for: subcategory)
        if index < categoryArray.count {
            categoryArray.insert(item, at: index)
        }
        categoryArray.append(item)
    }

    private func getAllVideos() {
        let files = MLFile.allFiles() as! [MLFile]
        foundVideos = files.filter {
            ($0 as MLFile).isKind(ofType: kMLFileTypeMovie) ||
                ($0 as MLFile).isKind(ofType: kMLFileTypeTVShowEpisode) ||
                ($0 as MLFile).isKind(ofType: kMLFileTypeClip)
        }
        allVideosFromVideos()
        //TODO: generate video subcategories
    }

    private func getAllAudio() {
        let files = MLFile.allFiles() as! [MLFile]
        foundAudio = files.filter { $0.isSupportedAudioFile() }
        tracksFromAudio()
        //TODO: generate remaining subcategories
    }

    private func tracksFromAudio() {
        if tracks != foundAudio {
            tracks = foundAudio
            NotificationCenter.default.post(name: .VLCTracksDidChangeNotification, object: tracks)
        }
    }

    private func allVideosFromVideos() {
        if allVideos != foundVideos {
            allVideos = foundVideos
            NotificationCenter.default.post(name: .VLCAllVideosDidChangeNotification, object: allVideos)
        }
    }
}
//Todo: implement the remove
//    - (void)removeMediaObjectFromFolder:(NSManagedObject *)managedObject
//{
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
//{
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
//{
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
//{
//    MLLabel *label = [mediaObject.labels anyObject];
//    NSSet *allFiles = label.files;
//    for (MLFile *file in allFiles) {
//        if (file.folderTrackNumber > mediaObject.folderTrackNumber) {
//            int value = [file.folderTrackNumber intValue];
//            file.folderTrackNumber = [NSNumber numberWithInt:value - 1];
//        }
//    }
//}
//@end
