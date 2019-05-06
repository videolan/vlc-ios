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
                                     didModifyVideo video: [VLCMLMedia])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didDeleteMediaWithIds ids: [NSNumber])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddVideos videos: [VLCMLMedia])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddShowEpisodes showEpisodes: [VLCMLMedia])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     thumbnailReady media: VLCMLMedia)

    // Audio
    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddAudios audios: [VLCMLMedia])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddArtists artists: [VLCMLArtist])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didDeleteArtistsWithIds artistsIds: [NSNumber])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddAlbums albums: [VLCMLAlbum])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didDeleteAlbumsWithIds albumsIds: [NSNumber])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddAlbumTracks albumTracks: [VLCMLMedia])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddGenres genres: [VLCMLGenre])

    // Playlist
    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddPlaylists playlists: [VLCMLPlaylist])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didModifyPlaylists playlists: [VLCMLPlaylist])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didDeletePlaylistsWithIds playlistsIds: [NSNumber])
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

    private var didMigrate = UserDefaults.standard.bool(forKey: MediaLibraryService.migrationKey)
    private var didFinishDiscovery = false
    // Using ObjectIdentifier to avoid duplication and facilitate
    // identification of observing object
    private var observers = [ObjectIdentifier: Observer]()

    private var medialib: VLCMediaLibrary!

    weak var migrationDelegate: MediaLibraryMigrationDelegate?

    override init() {
        super.init()
        medialib = VLCMediaLibrary()
        medialib.delegate = self
        setupMediaLibrary()
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: .VLCNewFileAddedNotification, object: nil)
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

    private func setupMediaLibrary() {
        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first else {
                preconditionFailure("MediaLibraryService: Unable to init medialibrary.")
        }

        setupMediaDiscovery(at: documentPath)

        let databasePath = libraryPath + "/MediaLibrary/" + MediaLibraryService.databaseName
        let thumbnailPath = libraryPath + "/MediaLibrary/Thumbnails"

        do {
            try FileManager.default.createDirectory(atPath: thumbnailPath,
                                                    withIntermediateDirectories: true)
        } catch let error as NSError {
            assertionFailure("Failed to create directory: \(error.localizedDescription)")
        }

        let medialibraryStatus = medialib.setupMediaLibrary(databasePath: databasePath,
                                                            thumbnailPath: thumbnailPath)

        switch medialibraryStatus {
        case .success:
            guard medialib.start() else {
                assertionFailure("MediaLibraryService: Medialibrary failed to start.")
                return
            }
            medialib.reload()
            medialib.discover(onEntryPoint: "file://" + documentPath)
        case .alreadyInitialized:
            assertionFailure("MediaLibraryService: Medialibrary already initialized.")
        case .failed:
            preconditionFailure("MediaLibraryService: Failed to setup medialibrary.")
        case .dbReset:
            // should still start and discover but warn the user that the db has been wipped
            assertionFailure("MediaLibraryService: The database was resetted, please re-configure.")
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
        guard migrateToNewMediaLibrary() else {
            migrationDelegate?.medialibraryDidStopMigration(self)
            return
        }

        migrationDelegate?.medialibraryDidFinishMigration(self)
    }

    func migrateMedia(_ oldMedialibrary: MLMediaLibrary) -> Bool {
        guard let allFiles = MLFile.allFiles() as? [MLFile] else {
            assertionFailure("MediaLibraryService: Migration: Unable to retreive all files")
            return false
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
        oldMedialibrary.save()
        return true
    }

    // This private method migrates old playlist and removes file and playlist
    // from the old medialibrary.
    // Note: This removes **only** files that are in a playlist
    func migratePlaylists(_ oldMedialibrary: MLMediaLibrary) -> Bool {
        guard let allLabels = MLLabel.allLabels() as? [MLLabel] else {
            assertionFailure("MediaLibraryService: Migration: Unable to retreive all labels")
            return false
        }

        for label in allLabels {
            let newPlaylist = createPlaylist(with: label.name)

            guard let files = label.files as? Set<MLFile> else {
                assertionFailure("MediaLibraryService: Migration: Unable to retreive files from label")
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
        oldMedialibrary.save()
        return true
    }

    func migrateToNewMediaLibrary() -> Bool {
        guard let oldMedialibrary = MLMediaLibrary.sharedMediaLibrary() as? MLMediaLibrary else {
            assertionFailure("MediaLibraryService: Migration: Unable to retreive old medialibrary")
            return false
        }

        if migrateMedia(oldMedialibrary) && migratePlaylists(oldMedialibrary) {
            UserDefaults.standard.set(true, forKey: MediaLibraryService.migrationKey)
            didMigrate = true
            return true
        }
        return false
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

extension MediaLibraryService {
    @objc func reload() {
        medialib.reload()
    }

    /// Returns number of *ALL* files(audio and video) present in the medialibrary database
    func numberOfFiles() -> Int {
        var media = medialib.audioFiles(with: .filename, desc: false)

        media += medialib.videoFiles(with: .filename, desc: false)
        return media.count
    }

    /// Returns *ALL* file found for a specified VLCMLMediaType
    ///
    /// - Parameter type: Type of the media
    /// - Returns: Array of VLCMLMedia
    func media(ofType type: VLCMLMediaType, sortingCriteria sort: VLCMLSortingCriteria = .filename, desc: Bool = false) -> [VLCMLMedia] {
        return type == .video ? medialib.videoFiles(with: sort, desc: desc) : medialib.audioFiles(with: sort, desc: desc)
    }

    func fetchMedia(with mrl: URL?) -> VLCMLMedia? {
        guard let mrl = mrl  else {
            return nil
        }
        return medialib.media(withMrl: mrl)
    }
}

// MARK: - Audio methods

extension MediaLibraryService {
    func artists(sortingCriteria sort: VLCMLSortingCriteria = .artist, desc: Bool = false) -> [VLCMLArtist] {
        return medialib.artists(with: sort, desc: desc, all: true)
    }

    func albums(sortingCriteria sort: VLCMLSortingCriteria = .album, desc: Bool = false) -> [VLCMLAlbum] {
        return medialib.albums(with: sort, desc: desc)
    }
}

// MARK: - Video methods

extension MediaLibraryService {
    func requestThumbnail(for media: [VLCMLMedia]) {
        media.forEach() {
            guard !$0.isThumbnailGenerated() else { return }

            if !medialib.requestThumbnail(for: $0) {
                assertionFailure("MediaLibraryService: Failed to generate thumbnail for: \($0.identifier())")
            }
        }
    }
}

// MARK: - Playlist methods

extension MediaLibraryService {
    func createPlaylist(with name: String) -> VLCMLPlaylist {
        return medialib.createPlaylist(withName: name)
    }

    func deletePlaylist(with identifier: VLCMLIdentifier) -> Bool {
        return medialib.deletePlaylist(withIdentifier: identifier)
    }

    func playlists(sortingCriteria sort: VLCMLSortingCriteria = .default, desc: Bool = false) -> [VLCMLPlaylist] {
        return medialib.playlists(with: sort, desc: desc)
    }
}

// MARK: - Genre methods

extension MediaLibraryService {
    func genres(sortingCriteria sort: VLCMLSortingCriteria = .default, desc: Bool = false) -> [VLCMLGenre] {
        return medialib.genres(with: sort, desc: desc)
    }
}

// MARK: - VLCMediaFileDiscovererDelegate

extension MediaLibraryService: VLCMediaFileDiscovererDelegate {
    func mediaFileAdded(_ filePath: String!, loading isLoading: Bool) {
        guard !isLoading else {
            return
        }
        /* exclude media files from backup (QA1719) */
        var excludeURL = URL(fileURLWithPath: filePath)
        var resourceValue = URLResourceValues()

        resourceValue.isExcludedFromBackup = true

        do {
            try excludeURL.setResourceValues(resourceValue)
        } catch let error {
            assertionFailure("MediaLibraryService: VLCMediaFileDiscovererDelegate: \(error.localizedDescription)")
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
        let videos = media.filter {( $0.type() == .video )}
        let audio = media.filter {( $0.type() == .audio )}

        // thumbnails only for videos
        requestThumbnail(for: videos)

        for observer in observers {
            observer.value.observer?.medialibrary?(self, didAddVideos: videos)
            observer.value.observer?.medialibrary?(self, didAddAudios: audio)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didModifyMedia media: [VLCMLMedia]) {
        let showEpisodes = media.filter {( $0.subtype() == .showEpisode )}
        let albumTrack = media.filter {( $0.subtype() == .albumTrack )}

        for observer in observers {
            observer.value.observer?.medialibrary?(self, didAddShowEpisodes: showEpisodes)
            observer.value.observer?.medialibrary?(self, didAddAlbumTracks: albumTrack)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didDeleteMediaWithIds mediaIds: [NSNumber]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didDeleteMediaWithIds: mediaIds)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, thumbnailReadyFor media: VLCMLMedia, withSuccess success: Bool) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, thumbnailReady: media)
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

    func medialibrary(_ medialibrary: VLCMediaLibrary, didDeleteAlbumsWithIds albumsIds: [NSNumber]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didDeleteAlbumsWithIds: albumsIds)
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

    func medialibrary(_ medialibrary: VLCMediaLibrary, didModifyPlaylists playlists: [VLCMLPlaylist]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didModifyPlaylists: playlists)
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
