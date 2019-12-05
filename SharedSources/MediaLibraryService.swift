/*****************************************************************************
 * MediaLibraryService.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2018 VideoLAN. All rights reserved.
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

// MARK: - Notification names

extension Notification.Name {
    static let VLCNewFileAddedNotification = Notification.Name("NewFileAddedNotification")
}

// For objc
extension NSNotification {
    @objc static let VLCNewFileAddedNotification = Notification.Name.VLCNewFileAddedNotification
}

// MARK: -

@objc protocol MediaLibraryObserver: class {
    // Video
    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddVideos videos: [VLCMLMedia])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didModifyVideos videos: [VLCMLMedia])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didDeleteMediaWithIds ids: [NSNumber])

    // ShowEpisodes
    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddShowEpisodes showEpisodes: [VLCMLMedia])

    // Tumbnail
    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     thumbnailReady media: VLCMLMedia,
                                     type: VLCMLThumbnailSizeType, success: Bool)

    // Tracks
    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddTracks tracks: [VLCMLMedia])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didModifyTracks tracks: [VLCMLMedia])

    // Artists
    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddArtists artists: [VLCMLArtist])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didModifyArtistsWithIds artistsIds: [NSNumber])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didDeleteArtistsWithIds artistsIds: [NSNumber])

    // Albums
    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddAlbums albums: [VLCMLAlbum])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didModifyAlbumsWithIds albumsIds: [NSNumber])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didDeleteAlbumsWithIds albumsIds: [NSNumber])

    // AlbumTracks
    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddAlbumTracks albumTracks: [VLCMLMedia])

    // Genres
    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddGenres genres: [VLCMLGenre])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didModifyGenresWithIds genresIds: [NSNumber])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didDeleteGenresWithIds genresIds: [NSNumber])

    // Playlist
    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddPlaylists playlists: [VLCMLPlaylist])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didModifyPlaylistsWithIds playlistsIds: [NSNumber])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didDeletePlaylistsWithIds playlistsIds: [NSNumber])

    // Force Rescan
    @objc optional func medialibraryDidStartRescan()
}

// MARK: -

protocol MediaLibraryMigrationDelegate: class {
    func medialibraryDidStartMigration(_ medialibrary: MediaLibraryService)

    func medialibraryDidFinishMigration(_ medialibrary: MediaLibraryService)

    func medialibraryDidStopMigration(_ medialibrary: MediaLibraryService)
}

// MARK: -

class MediaLibraryService: NSObject {
    private static let databaseName: String = "medialibrary.db"
    private static let migrationKey: String = "MigratedToVLCMediaLibraryKit"
    private static let didForceRescan: String = "MediaLibraryDidForceRescan"

    private var didMigrate = UserDefaults.standard.bool(forKey: MediaLibraryService.migrationKey)
    private var didFinishDiscovery = false
    // Using ObjectIdentifier to avoid duplication and facilitate
    // identification of observing object
    private var observers = [ObjectIdentifier: Observer]()

    private(set) lazy var medialib = VLCMediaLibrary()

    weak var migrationDelegate: MediaLibraryMigrationDelegate?

    override init() {
        super.init()
        medialib.delegate = self
        setupMediaLibrary()
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: .VLCNewFileAddedNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(handleWillEnterForegroundNotification),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
    }
}

// MARK: - Private initializers

private extension MediaLibraryService {
    private func setupMediaDiscovery(at path: String) {
        let mediaFileDiscoverer = VLCMediaFileDiscoverer.sharedInstance()
        mediaFileDiscoverer?.directoryPath = path
        mediaFileDiscoverer?.addObserver(self)
        mediaFileDiscoverer?.startDiscovering()
    }

    private func startMediaLibrary(on path: String) {
        guard medialib.start() else {
            assertionFailure("MediaLibraryService: Medialibrary failed to start.")
            return
        }

        if UserDefaults.standard.bool(forKey: MediaLibraryService.didForceRescan) == false {
            medialib.forceRescan()
            UserDefaults.standard.set(true, forKey: MediaLibraryService.didForceRescan)
        }

        /* exclude Document directory from backup (QA1719) */
        if let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            var excludeURL = URL(fileURLWithPath: documentPath)
            var resourceValue = URLResourceValues()
            let excludeMediaLibrary = !UserDefaults.standard.bool(forKey: kVLCSettingBackupMediaLibrary)

            resourceValue.isExcludedFromBackup = excludeMediaLibrary

            do {
                try excludeURL.setResourceValues(resourceValue)
            } catch let error {
                assertionFailure("MediaLibraryService: start: \(error.localizedDescription)")
            }
        }

        medialib.reload()
        medialib.discover(onEntryPoint: "file://" + path)
    }

    private func setupMediaLibrary() {
        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first else {
                preconditionFailure("MediaLibraryService: Unable to init medialibrary.")
        }

        setupMediaDiscovery(at: documentPath)

        let databasePath = libraryPath + "/MediaLibrary/" + MediaLibraryService.databaseName
        let thumbnailPath = libraryPath + "/MediaLibrary/Thumbnails"
        let medialibraryPath = libraryPath + "/MediaLibrary/Internal"

        _ = try? FileManager.default.removeItem(atPath: thumbnailPath)

        do {
            try FileManager.default.createDirectory(atPath: medialibraryPath,
                                                    withIntermediateDirectories: true)
        } catch let error as NSError {
            assertionFailure("Failed to create directory: \(error.localizedDescription)")
        }

        let medialibraryStatus = medialib.setupMediaLibrary(databasePath: databasePath,
                                                            medialibraryPath: medialibraryPath)

        switch medialibraryStatus {
        case .success, .dbReset:
            startMediaLibrary(on: documentPath)
        case .alreadyInitialized:
            assertionFailure("MediaLibraryService: Medialibrary already initialized.")
        case .failed:
            preconditionFailure("MediaLibraryService: Failed to setup medialibrary.")
        case .dbCorrupted:
            medialib.clearDatabase(restorePlaylists: true)
            startMediaLibrary(on: documentPath)
        @unknown default:
            assertionFailure("MediaLibraryService: unhandled case")
        }
    }
}

// MARK: - Migration

private extension MediaLibraryService {
    func startMigrationIfNeeded() {
        guard !didMigrate else {
            return
        }
        migrationDelegate?.medialibraryDidStartMigration(self)

        migrateToNewMediaLibrary() {
            [unowned self] success in
            if success {
                self.migrationDelegate?.medialibraryDidFinishMigration(self)
            } else {
                self.migrationDelegate?.medialibraryDidStopMigration(self)
            }
        }
    }

    func migrateMedia(_ oldMedialibrary: MLMediaLibrary,
                      completionHandler: @escaping (Bool) -> Void) {
        guard let allFiles = MLFile.allFiles() as? [MLFile] else {
            assertionFailure("MediaLibraryService: Migration: Unable to retrieve all files")
            completionHandler(false)
            return
        }

        for media in allFiles {
            if let newMedia = fetchMedia(with: media.url) {
                newMedia.updateTitle(media.title)
                newMedia.setPlayCount(media.playCount.uint32Value)
                newMedia.setMetadataOf(.progress, intValue: media.lastPosition.int64Value)
                newMedia.setMetadataOf(.seen, intValue: media.unread.int64Value)
                // Only delete files that are not in playlist
                if media.labels.isEmpty {
                    oldMedialibrary.remove(media)
                }
            }
        }

        oldMedialibrary.save {
            success in
            completionHandler(success)
        }
    }

    // This private method migrates old playlist and removes file and playlist
    // from the old medialibrary.
    // Note: This removes **only** files that are in a playlist
    func migratePlaylists(_ oldMedialibrary: MLMediaLibrary,
                          completionHandler: @escaping (Bool) -> Void) {
        guard let allLabels = MLLabel.allLabels() as? [MLLabel] else {
            assertionFailure("MediaLibraryService: Migration: Unable to retrieve all labels")
            completionHandler(false)
            return
        }

        for label in allLabels {
            guard let newPlaylist = createPlaylist(with: label.name) else {
                assertionFailure("MediaLibraryService: Migration: Unable to create playlist.")
                continue
            }

            guard let files = label.files as? Set<MLFile> else {
                assertionFailure("MediaLibraryService: Migration: Unable to retrieve files from label")
                oldMedialibrary.remove(label)
                continue
            }

            for file in files {
                if let newMedia = fetchMedia(with: file.url) {
                    if newPlaylist.appendMedia(withIdentifier: newMedia.identifier()) {
                        oldMedialibrary.remove(file)
                    }
                }
            }
            oldMedialibrary.remove(label)
        }
        oldMedialibrary.save() {
            success in
            completionHandler(success)
        }
    }

    func migrateToNewMediaLibrary(completionHandler: @escaping (Bool) -> Void) {
        guard let oldMedialibrary = MLMediaLibrary.sharedMediaLibrary() as? MLMediaLibrary else {
            assertionFailure("MediaLibraryService: Migration: Unable to retrieve old medialibrary")
            completionHandler(false)
            return
        }

        migrateMedia(oldMedialibrary) {
            [unowned self] success in

            guard success else {
                assertionFailure("MediaLibraryService: Failed to migrate Media.")
                completionHandler(false)
                return
            }

            self.migratePlaylists(oldMedialibrary) {
                [unowned self] success in
                if success {
                    UserDefaults.standard.set(true, forKey: MediaLibraryService.migrationKey)
                    self.didMigrate = true
                } else {
                    assertionFailure("MediaLibraryService: Failed to migrate Playlist.")
                }
                completionHandler(success)
            }
        }
    }
}

// MARK: - Observer

private extension MediaLibraryService {
    struct Observer {
        weak var observer: MediaLibraryObserver?
    }
}

extension MediaLibraryService {
    func addObserver(_ observer: MediaLibraryObserver) {
        let identifier = ObjectIdentifier(observer)
        observers[identifier] = Observer(observer: observer)
    }

    func removeObserver(_ observer: MediaLibraryObserver) {
        let identifier = ObjectIdentifier(observer)
        observers.removeValue(forKey: identifier)
    }
}

// MARK: - Helpers

@objc extension MediaLibraryService {
    @objc func reload() {
        medialib.reload()
    }

    @objc func forceRescan() {
        medialib.forceRescan()
    }

    @objc func reindexAllMediaForSpotlight() {
        media(ofType: .video).forEach { $0.updateCoreSpotlightEntry() }
        media(ofType: .audio).forEach { $0.updateCoreSpotlightEntry() }
    }
    /// Returns number of *ALL* files(audio and video) present in the medialibrary database
    func numberOfFiles() -> Int {
        return (medialib.audioFiles()?.count ?? 0) + (medialib.videoFiles()?.count ?? 0)
    }

    /// Returns *ALL* file found for a specified VLCMLMediaType
    ///
    /// - Parameter type: Type of the media
    /// - Returns: Array of VLCMLMedia
    func media(ofType type: VLCMLMediaType,
               sortingCriteria sort: VLCMLSortingCriteria = .alpha,
               desc: Bool = false) -> [VLCMLMedia] {
        return type == .video ? medialib.videoFiles(with: sort, desc: desc) ?? []
                              : medialib.audioFiles(with: sort, desc: desc) ?? []
    }

    @objc func fetchMedia(with mrl: URL?) -> VLCMLMedia? {
        guard let mrl = mrl  else {
            return nil //Happens when we have a URL or there is no currently playing file
        }
        return medialib.media(withMrl: mrl)
    }


    @objc func media(for identifier: VLCMLIdentifier) -> VLCMLMedia? {
        return medialib.media(withIdentifier: identifier)
    }

    func savePlaybackState(from player: PlaybackService) {
        let media: VLCMedia? = player.currentlyPlayingMedia
        guard let mlMedia = fetchMedia(with: media?.url.absoluteURL) else {
            // we opened a url and not a local file
            return
        }

        mlMedia.isNew = false
        mlMedia.progress = player.playbackPosition
        mlMedia.audioTrackIndex = Int64(player.indexOfCurrentAudioTrack)
        mlMedia.subtitleTrackIndex = Int64(player.indexOfCurrentSubtitleTrack)
        mlMedia.chapterIndex = Int64(player.indexOfCurrentChapter)
        mlMedia.titleIndex = Int64(player.indexOfCurrentTitle)

        if mlMedia.type() == .video {
            mlMedia.requestThumbnail(of: .thumbnail, desiredWidth: 320,
                                     desiredHeight: 200, atPosition: player.playbackPosition)
        }
    }
}

// MARK: - Application notifications

@objc private extension MediaLibraryService {
    @objc private func handleWillEnterForegroundNotification() {
        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            assertionFailure("MediaLibraryService: handleWillEnterForegroundNotification: Failed to retrieve documentPath")
            return
        }
        // On each foreground notification we check if there is a `.Trash` folder which is invisible
        // for the user that can be created by deleting media from the Files app.
        // This could lead to disk space issues.
        // For now since we do not handle restoration, we delete the `.Trash` folder every time.
         _ = try? FileManager.default.removeItem(atPath: documentPath + "/.Trash")

        // Reload in order to make sure that there is no old artifacts left
        reload()
    }
}

// MARK: - Audio methods

@objc extension MediaLibraryService {
    func artists(sortingCriteria sort: VLCMLSortingCriteria = .alpha,
                 desc: Bool = false, listAll all: Bool = false) -> [VLCMLArtist] {
        return medialib.artists(with: sort, desc: desc, all: all) ?? []
    }

    func albums(sortingCriteria sort: VLCMLSortingCriteria = .alpha,
                desc: Bool = false) -> [VLCMLAlbum] {
        return medialib.albums(with: sort, desc: desc) ?? []
    }
}

// MARK: - Video methods

extension MediaLibraryService {
    func requestThumbnail(for media: VLCMLMedia) {
        if media.isThumbnailGenerated() || media.thumbnail() != nil {
            return
        }

        if !media.requestThumbnail(of: .thumbnail, desiredWidth: 320, desiredHeight: 200, atPosition: 0.03) {
            assertionFailure("MediaLibraryService: Failed to generate thumbnail for: \(media.identifier())")
        }
    }

    func requestThumbnail(for media: [VLCMLMedia]) {
        media.forEach() {
            requestThumbnail(for: $0)
        }
    }
}

// MARK: - Playlist methods

@objc extension MediaLibraryService {
    func createPlaylist(with name: String) -> VLCMLPlaylist? {
        return medialib.createPlaylist(withName: name)
    }

    func deletePlaylist(with identifier: VLCMLIdentifier) -> Bool {
        return medialib.deletePlaylist(withIdentifier: identifier)
    }

    func playlists(sortingCriteria sort: VLCMLSortingCriteria = .default,
                   desc: Bool = false) -> [VLCMLPlaylist] {
        return medialib.playlists(with: sort, desc: desc) ?? []
    }
}

// MARK: - Genre methods

extension MediaLibraryService {
    func genres(sortingCriteria sort: VLCMLSortingCriteria = .alpha,
                desc: Bool = false) -> [VLCMLGenre] {
        return medialib.genres(with: sort, desc: desc) ?? []
    }
}

// MARK: - VLCMediaFileDiscovererDelegate

extension MediaLibraryService: VLCMediaFileDiscovererDelegate {
    func mediaFileAdded(_ filePath: String!, loading isLoading: Bool) {
        guard !isLoading else {
            return
        }

        reload()
    }

    func mediaFileDeleted(_ filePath: String!) {
        reload()
    }
}

// MARK: - VLCMediaLibraryDelegate - Media

extension MediaLibraryService: VLCMediaLibraryDelegate {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAddMedia media: [VLCMLMedia]) {

        media.forEach { $0.updateCoreSpotlightEntry() }

        let videos = media.filter {( $0.type() == .video )}
        let tracks = media.filter {( $0.type() == .audio )}

        for observer in observers {
            observer.value.observer?.medialibrary?(self, didAddVideos: videos)
            observer.value.observer?.medialibrary?(self, didAddTracks: tracks)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didModifyMediaWithIds mediaIds: [NSNumber]) {
        var media = [VLCMLMedia]()

        mediaIds.forEach() {
            guard let safeMedia = medialib.media(withIdentifier: $0.int64Value) else {
                return
            }
            media.append(safeMedia)
        }

        media.forEach { $0.updateCoreSpotlightEntry() }

        let showEpisodes = media.filter {( $0.subtype() == .showEpisode )}
        let albumTrack = media.filter {( $0.subtype() == .albumTrack )}
        let videos = media.filter {( $0.type() == .video)}
        let tracks = media.filter {( $0.type() == .audio)}

        // Shows and albumtracks are known only after when the medialibrary calls didModifyMedia
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didAddShowEpisodes: showEpisodes)
            observer.value.observer?.medialibrary?(self, didAddAlbumTracks: albumTrack)
            observer.value.observer?.medialibrary?(self, didModifyVideos: videos)
            observer.value.observer?.medialibrary?(self, didModifyTracks: tracks)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didDeleteMediaWithIds mediaIds: [NSNumber]) {
        var stringIds = [String]()
        mediaIds.forEach { stringIds.append("\($0)") }
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: stringIds, completionHandler: nil)

        for observer in observers {
            observer.value.observer?.medialibrary?(self, didDeleteMediaWithIds: mediaIds)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, thumbnailReadyFor media: VLCMLMedia,
                      of type: VLCMLThumbnailSizeType, withSuccess success: Bool) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, thumbnailReady: media,
                                                   type: type, success: success)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Artists

extension MediaLibraryService {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd artists: [VLCMLArtist]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didAddArtists: artists)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary,
                      didModifyArtistsWithIds artistsIds: [NSNumber]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didModifyArtistsWithIds: artistsIds)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didDeleteArtistsWithIds artistsIds: [NSNumber]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didDeleteArtistsWithIds: artistsIds)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Albums

extension MediaLibraryService {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd albums: [VLCMLAlbum]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didAddAlbums: albums)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary,
                      didModifyAlbumsWithIds albumsIds: [NSNumber]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didModifyAlbumsWithIds: albumsIds)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didDeleteAlbumsWithIds albumsIds: [NSNumber]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didDeleteAlbumsWithIds: albumsIds)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Genres

extension MediaLibraryService {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd genres: [VLCMLGenre]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didAddGenres: genres)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary,
                      didModifyGenresWithIds genresIds: [NSNumber]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didModifyGenresWithIds: genresIds)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary,
                      didDeleteGenresWithIds genresIds: [NSNumber]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didDeleteGenresWithIds: genresIds)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Playlists

extension MediaLibraryService {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd playlists: [VLCMLPlaylist]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didAddPlaylists: playlists)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary,
                      didModifyPlaylistsWithIds playlistsIds: [NSNumber]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didModifyPlaylistsWithIds: playlistsIds)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didDeletePlaylistsWithIds playlistsIds: [NSNumber]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didDeletePlaylistsWithIds: playlistsIds)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Discovery

extension MediaLibraryService {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didStartDiscovery entryPoint: String) {
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didCompleteDiscovery entryPoint: String) {
        didFinishDiscovery = true
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didProgressDiscovery entryPoint: String) {
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didUpdateParsingStatsWithPercent percent: UInt32) {
        if didFinishDiscovery && percent == 100 {
             startMigrationIfNeeded()
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Exception handling

extension MediaLibraryService {
    func medialibrary(_ medialibrary: VLCMediaLibrary,
                      unhandledExceptionWithContext context: String,
                      errorMessage: String, clearSuggested: Bool) -> Bool {
        if clearSuggested {
            medialib.clearDatabase(restorePlaylists: true)
            setupMediaLibrary()
            return true
        }
        return false
    }
}

// MARK: - VLCMLMediaLibraryDelegate - Force rescan

extension MediaLibraryService {
    func medialibraryDidStartRescan(_ medialibrary: VLCMediaLibrary) {
        for observer in observers {
            observer.value.observer?.medialibraryDidStartRescan?()
        }
    }
}
