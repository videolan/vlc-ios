/*****************************************************************************
 * VLCMediaLibraryManager.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2018 VideoLAN. All rights reserved.
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class VLCMediaLibraryManager: NSObject {

    private static let databaseName: String = "medialibrary.db"
    private var databasePath: String!
    private var thumbnailPath: String!

    private lazy var medialibrary: VLCMediaLibrary = {
        let medialibrary = VLCMediaLibrary()
        medialibrary.delegate = self
        return medialibrary
    }()

    override init() {
        super.init()
        setupMediaLibrary()
    }

    // MARK: Private
    private func setupMediaLibrary() {
        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            let dbPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first else {
                preconditionFailure("VLCMediaLibraryManager: Unable to init medialibrary.")
        }

        medialibrary.setVerbosity(.info)

        databasePath = dbPath + "/" + VLCMediaLibraryManager.databaseName
        thumbnailPath = documentPath

        let medialibraryStatus = medialibrary.setupMediaLibrary(databasePath: databasePath,
                                                                thumbnailPath: thumbnailPath)

        switch medialibraryStatus {
        case .success:
            guard medialibrary.start() else {
                assertionFailure("VLCMediaLibraryManager: Medialibrary failed to start.")
                return
            }
            medialibrary.reload()
            medialibrary.discover(onEntryPoint: "file://" + documentPath)
            break
        case .alreadyInitialized:
            assertionFailure("VLCMediaLibraryManager: Medialibrary already initialized.")
            break
        case .failed:
            preconditionFailure("VLCMediaLibraryManager: Failed to setup medialibrary.")
            break
        case .dbReset:
            // should still start and discover but warn the user that the db has been wipped
            assertionFailure("VLCMediaLibraryManager: The database was resetted, please re-configure.")
            break
        }
    }

    // MARK: Internal

    /// Returns number of *ALL* files(audio and video) present in the medialibrary database
    func numberOfFiles() -> Int {
        var media = medialibrary.audioFiles(with: .filename, desc: false)

        media += medialibrary.videoFiles(with: .filename, desc: false)
        return media.count
    }


    /// Returns *ALL* file found for a specified VLCMLMediaType
    ///
    /// - Parameter type: Type of the media
    /// - Returns: Array of VLCMLMedia
    func media(ofType type: VLCMLMediaType) -> [VLCMLMedia] {
        return type == .video ? medialibrary.videoFiles(with: .filename, desc: false) : medialibrary.audioFiles(with: .filename, desc: false)
    }

    func addMedia(withMrl mrl: URL) {
        medialibrary.addMedia(withMrl: mrl)
    }
}

// MARK: MediaDataSource - Other methods

extension VLCMediaLibraryManager {
//    @objc enum VLCMediaCategory: Int {
//        case unknown
//        case audio
//        case video
//    }
//
//    @objc enum VLCMediaSubcategory: Int {
//        case unknown
//        case movies
//        case episodes
//        case artists
//        case albums
//        case tracks
//        case genres
//        case videoPlaylists
//        case audioPlaylists
//        case allVideos
//    }
//
//    struct VLCMediaType {
//        let category: VLCMediaCategory
//        var subcategory: VLCMediaSubcategory
//    }
//
//
//        var foundVideos = [VLCMLMedia]()
//        var foundAudio = [VLCMLMedia]()
//
//        var movies = [VLCMLMedia]()
//        var episodes = [VLCMLMedia]()
//        var artists = [String]()
//        var albums = [MLAlbum]()
//        var genres = [String]()
//        var audioPlaylist = [MLLabel]()
//        var videoPlaylist = [MLLabel]()
//

//    @objc func numberOfFiles(subcategory: VLCMediaSubcategory) -> Int {
//        return array(for: subcategory).countSources/MediaViewController.swift
//    }
//
//    private func array(for subcategory: VLCMediaSubcategory) -> [Any] {
//        switch subcategory {
//        case .unknown:
//            preconditionFailure("No")
//        case .movies:
//            return movies
//        case .episodes:
//            return episodes
//        case .artists:
//            return artists
//        case .albums:
//            return albums
//        case .tracks:
//            return foundAudio
//        case .genres:
//            return genres
//        case .audioPlaylists:
//            return audioPlaylist
//        case .videoPlaylists:
//            return videoPlaylist
//        case .allVideos:
//            return foundVideos
//        }
//    }
//
//    func indicatorInfo(for subcategory: VLCMediaSubcategory) -> IndicatorInfo {
//        switch subcategory {
//        case .unknown:
//            preconditionFailure("No")
//        case .movies:
//            return IndicatorInfo(title: NSLocalizedString("MOVIES", comment: ""))
//        case .episodes:
//            return IndicatorInfo(title: NSLocalizedString("EPISODES", comment: ""))
//        case .artists:
//            return IndicatorInfo(title: NSLocalizedString("ARTISTS", comment: ""))
//        case .albums:
//            return IndicatorInfo(title: NSLocalizedString("ALBUMS", comment: ""))
//        case .tracks:
//            return IndicatorInfo(title: NSLocalizedString("SONGS", comment: ""))
//        case .genres:
//            return IndicatorInfo(title: NSLocalizedString("GENRES", comment: ""))
//        case .audioPlaylists:
//            return IndicatorInfo(title: NSLocalizedString("AUDIO_PLAYLISTS", comment: ""))
//        case .videoPlaylists:
//            return IndicatorInfo(title: NSLocalizedString("VIDEO_PLAYLISTS", comment: ""))
//        case .allVideos:
//            return IndicatorInfo(title: NSLocalizedString("VIDEOS", comment: ""))
//        }
//
//    }
//
//    @objc func object(at index: Int, subcategory: VLCMediaSubcategory) -> Any {
//
//        guard index >= 0 else {
//            preconditionFailure("a negative value ? I don't think so!")
//        }
//
//        let categoryArray = array(for: subcategory)
//        if index < categoryArray.count {
//            return categoryArray[Int(index)]
//        }
//        preconditionFailure("index is taller than count")
//    }
//
//    func allObjects(for subcategory: VLCMediaSubcategory) -> [Any] {
//        return array(for:subcategory)
//    }
//
//    func removeObject(at index: Int, subcategory: VLCMediaSubcategory) {
//        guard index >= 0 else {
//            preconditionFailure("a negative value ? I don't think so!")
//        }
//        var categoryArray = array(for: subcategory)
//        if index < categoryArray.count {
//            categoryArray.remove(at: index)
//        }
//        preconditionFailure("index is taller than count")
//    }
//
//    func insert(_ item: MLFile, at index: Int, subcategory: VLCMediaSubcategory) {
//        guard index >= 0 else {
//            preconditionFailure("a negative value ? I don't think so!")
//        }
//        var categoryArray = array(for: subcategory)
//        if index < categoryArray.count {
//            categoryArray.insert(item, at: index)
//        }
//        categoryArray.append(item)
//    }
}

// MARK: MediaDataSource - Audio methods

extension VLCMediaLibraryManager {
    private func getAllAudio() {
//        foundAudio = medialibrary.media(ofType: .audio)
//        artistsFromAudio()
//        albumsFromAudio()
//        audioPlaylistsFromAudio()
//        genresFromAudio()
    }

    private func getArtists() {
//        let albumtracks = MLAlbumTrack.allTracks() as! [MLAlbumTrack]
//        let tracksWithArtist = albumtracks.filter { $0.artist != nil && $0.artist != "" }
//        artists = tracksWithArtist.map { $0.artist }
    }

    private func getAlbums() {
//        albums = MLAlbum.allAlbums() as! [MLAlbum]
    }

    private func getAudioPlaylists() {
//        let labels = MLLabel.allLabels() as! [MLLabel]
//        audioPlaylist = labels.filter {
//            let audioFiles = $0.files.filter {
//                if let file = $0 as? MLFile {
//                    return file.isSupportedAudioFile()
//                }
//                return false
//            }
//            return !audioFiles.isEmpty
//        }
    }

    private func genresFromAudio() {
//        let albumtracks = MLAlbumTrack.allTracks() as! [MLAlbumTrack]
//        let tracksWithArtist = albumtracks.filter { $0.genre != nil && $0.genre != "" }
//        genres = tracksWithArtist.map { $0.genre }
    }
}

// MARK: MediaDataSource - Video methods

extension VLCMediaLibraryManager {
    private func getAllVideos() {
//        foundVideos = medialibrary.media(ofType: .video)
//        moviesFromVideos()
//        episodesFromVideos()
        //        videoPlaylistsFromVideos()
    }

    private func getMovies() {
//        movies = foundVideos.filter { $0.subtype() == .movie }
    }

    private func getShowEpisodes() {
//        episodes = foundVideos.filter { $0.subtype() == .showEpisode }
    }

    private func getVideoPlaylists() {
//        let labels = MLLabel.allLabels() as! [MLLabel]
//        audioPlaylist = labels.filter {
//            let audioFiles = $0.files.filter {
//                if let file = $0 as? MLFile {
//                    return file.isShowEpisode() || file.isMovie() || file.isClip()
//                }
//                return false
//            }
//            return !audioFiles.isEmpty
//        }
    }
}

// MARK: VLCMediaLibraryDelegate
extension VLCMediaLibraryManager: VLCMediaLibraryDelegate {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAddMedia media: [VLCMLMedia]) {
        NotificationCenter.default.post(name: .VLCVideosDidChangeNotification, object: media)
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didStartDiscovery entryPoint: String) {
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didCompleteDiscovery entryPoint: String) {
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didProgressDiscovery entryPoint: String) {
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didUpdateParsingStatsWithPercent percent: UInt32) {
    }
}

// MARK: Future MediaDataSource extension

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
