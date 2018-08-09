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

extension Notification.Name {
    static let VLCNewFileAddedNotification = Notification.Name("NewFileAddedNotification")
}

// For objc
extension NSNotification {
    @objc static let VLCNewFileAddedNotification = Notification.Name.VLCNewFileAddedNotification
}

@objc protocol MediaLibraryObserver: class {
    // Video
    @objc optional func medialibrary(_ medialibrary: VLCMediaLibraryManager,
                                     didUpdateVideo video: [VLCMLMedia])

    @objc optional func medialibrary(_ medialibrary: VLCMediaLibraryManager,
                                     didDeleteMediaWithIds ids: [NSNumber])

    @objc optional func medialibrary(_ medialibrary: VLCMediaLibraryManager,
                                     didAddVideos videos: [VLCMLMedia])

    @objc optional func medialibrary(_ medialibrary: VLCMediaLibraryManager,
                                     didAddShowEpisodes showEpisodes: [VLCMLMedia])

    // Audio
    @objc optional func medialibrary(_ medialibrary: VLCMediaLibraryManager,
                                     didAddAudios audios: [VLCMLMedia])

    @objc optional func medialibrary(_ medialibrary: VLCMediaLibraryManager,
                                     didAddAlbumTracks tracks: [VLCMLMedia])

    @objc optional func medialibrary(_ medialibrary: VLCMediaLibraryManager,
                                     didAddArtists artists: [VLCMLArtist])

    @objc optional func medialibrary(_ medialibrary: VLCMediaLibraryManager,
                                     didAddAlbums albums: [VLCMLAlbum])

    @objc optional func medialibrary(_ medialibrary: VLCMediaLibraryManager,
                                     didAddGenres genres: [VLCMLGenre])

    // Playlist

    @objc optional func medialibrary(_ medialibrary: VLCMediaLibraryManager,
                                     didAddPlaylists playlists: [VLCMLPlaylist])
}

class VLCMediaLibraryManager: NSObject {
    private static let databaseName: String = "medialibrary.db"
    private var databasePath: String!
    private var thumbnailPath: String!

    // Using ObjectIdentifier to avoid duplication and facilitate
    // identification of observing object
    private var observers = [ObjectIdentifier: Observer]()

    private lazy var medialib: VLCMediaLibrary = {
        let medialibrary = VLCMediaLibrary()
        medialibrary.delegate = self
        return medialibrary
    }()

    override init() {
        super.init()
        setupMediaLibrary()
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: .VLCNewFileAddedNotification, object: nil)
    }

    // MARK: Private
    private func setupMediaLibrary() {
        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            let dbPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first else {
                preconditionFailure("VLCMediaLibraryManager: Unable to init medialibrary.")
        }

        databasePath = dbPath + "/" + VLCMediaLibraryManager.databaseName
        thumbnailPath = documentPath

        let medialibraryStatus = medialib.setupMediaLibrary(databasePath: databasePath,
                                                            thumbnailPath: thumbnailPath)

        switch medialibraryStatus {
        case .success:
            guard medialib.start() else {
                assertionFailure("VLCMediaLibraryManager: Medialibrary failed to start.")
                return
            }
            medialib.reload()
            medialib.discover(onEntryPoint: "file://" + documentPath)
        case .alreadyInitialized:
            assertionFailure("VLCMediaLibraryManager: Medialibrary already initialized.")
        case .failed:
            preconditionFailure("VLCMediaLibraryManager: Failed to setup medialibrary.")
        case .dbReset:
            // should still start and discover but warn the user that the db has been wipped
            assertionFailure("VLCMediaLibraryManager: The database was resetted, please re-configure.")
        }
    }

    // MARK: Internal

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

    func genre(sortingCriteria sort: VLCMLSortingCriteria = .default, desc: Bool = false) -> [VLCMLGenre] {
        return medialib.genres(with: sort, desc: desc)
    }
}

// MARK: - Observer

private extension VLCMediaLibraryManager {
    struct Observer {
        weak var observer: MediaLibraryObserver?
    }
}

extension VLCMediaLibraryManager {
    func addObserver(_ observer: MediaLibraryObserver) {
        let identifier = ObjectIdentifier(observer)
        observers[identifier] = Observer(observer: observer)
    }

    func removeObserver(_ observer: MediaLibraryObserver) {
        let identifier = ObjectIdentifier(observer)
        observers.removeValue(forKey: identifier)
    }
}

// MARK: MediaLibrary - Audio methods

extension VLCMediaLibraryManager {
    func getArtists() -> [VLCMLArtist] {
        return medialib.artists(with: .artist, desc: false, all: true)
    }

    func getAlbums() -> [VLCMLAlbum] {
        return medialib.albums(with: .album, desc: false)
    }
}

// MARK: MediaLibrary - Video methods

extension VLCMediaLibraryManager {
}

// MARK: MediaLibrary - Playlist methods

extension VLCMediaLibraryManager {
    func getPlaylists(sortingCriteria sort: VLCMLSortingCriteria = .default, desc: Bool = false) -> [VLCMLPlaylist] {
        return medialib.playlists(with: sort, desc: desc)
    }
}

// MARK: - VLCMediaLibraryDelegate - Media

extension VLCMediaLibraryManager: VLCMediaLibraryDelegate {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAddMedia media: [VLCMLMedia]) {
        let videos = media.filter {( $0.type() == .video )}
        let audio = media.filter {( $0.type() == .audio )}
        let showEpisodes = media.filter {( $0.subtype() == .showEpisode )}
        let albumTrack = media.filter {( $0.subtype() == .albumTrack )}

        for observer in observers {
            observer.value.observer?.medialibrary?(self, didAddVideos: videos)
            observer.value.observer?.medialibrary?(self, didAddAudios: audio)
            observer.value.observer?.medialibrary?(self, didAddShowEpisodes: showEpisodes)
            observer.value.observer?.medialibrary?(self, didAddAlbumTracks: albumTrack)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didDeleteMediaWithIds mediaIds: [NSNumber]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didDeleteMediaWithIds: mediaIds)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Artists

extension VLCMediaLibraryManager {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd artists: [VLCMLArtist]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didAddArtists: artists)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Albums

extension VLCMediaLibraryManager {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd albums: [VLCMLAlbum]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didAddAlbums: albums)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Playlists

extension VLCMediaLibraryManager {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd playlists: [VLCMLPlaylist]) {
        for observer in observers {
            observer.value.observer?.medialibrary?(self, didAddPlaylists: playlists)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Discovery

extension VLCMediaLibraryManager {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didStartDiscovery entryPoint: String) {
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didCompleteDiscovery entryPoint: String) {
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didProgressDiscovery entryPoint: String) {
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didUpdateParsingStatsWithPercent percent: UInt32) {
    }
}
