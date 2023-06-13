/*****************************************************************************
 * MediaLibraryService.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2018-2022 VideoLAN. All rights reserved.
 * Copyright © 2018-2022 Videolabs
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import CoreSpotlight
import VLCMediaLibraryKit
import UIKit

// MARK: - Notification names

extension Notification.Name {
    static let VLCNewFileAddedNotification = Notification.Name("NewFileAddedNotification")
}

// For objc
extension NSNotification {
    @objc static let VLCNewFileAddedNotification = Notification.Name.VLCNewFileAddedNotification
}

// MARK: -

@objc protocol MediaLibraryObserver: AnyObject {
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

    // MediaGroups
    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didAddMediaGroups mediaGroups: [VLCMLMediaGroup])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didModifyMediaGroupsWithIds mediaGroupsIds: [NSNumber])

    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     didDeleteMediaGroupsWithIds mediaGroupsIds: [NSNumber])
    
    // History
    @objc optional func medialibrary(_ medialibrary: MediaLibraryService,
                                     historyChangedOfType type: VLCMLHistoryType)

    // Force Rescan
    @objc optional func medialibraryDidStartRescan()
}

// MARK: - Delegate for "Backup Media Library" setting

@objc protocol MediaLibraryDeviceBackupDelegate: AnyObject {
    @objc func medialibraryDidStartExclusion()

    @objc func medialibraryDidCompleteExclusion()
}

// MARK: - Delegate for hiding Media Library

@objc protocol MediaLibraryHidingDelegate: AnyObject {
    @objc func medialibraryDidStartHiding()

    @objc func medialibraryDidCompleteHiding()
}

// MARK: -

class MediaLibraryService: NSObject {
    private static let databaseName: String = "medialibrary.db"
    private static let didForceRescan: String = "MediaLibraryDidForceRescan"
    private var triedToRecoverFromInitializationErrorOnce = false

    private var didFinishDiscovery = false

    private var desiredThumbnailWidth = UInt(320)
    private var desiredThumbnailHeight = UInt(200)

    private(set) var observable = Observable<MediaLibraryObserver>()

    private(set) lazy var medialib = VLCMediaLibrary()

    @objc weak var deviceBackupDelegate: MediaLibraryDeviceBackupDelegate?
    @objc weak var hidingDelegate: MediaLibraryHidingDelegate?

    @objc var isExcludingFromBackup: Bool = false
    @objc var isHidingLibrary: Bool = false

    override init() {
        super.init()
        setupMediaLibrary()
        medialib.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: .VLCNewFileAddedNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(handleWillEnterForegroundNotification),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)

        let screen = UIScreen.main
        let cellSizeWidth = MovieCollectionViewCell.cellSizeForWidth(screen.bounds.width).width
        let scaledCellWidth = cellSizeWidth * screen.scale
        desiredThumbnailWidth = UInt(scaledCellWidth)
        desiredThumbnailHeight = UInt(scaledCellWidth / 1.6)
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
        let excludeMediaLibrary = !UserDefaults.standard.bool(forKey: kVLCSettingBackupMediaLibrary)
        let hideML = UserDefaults.standard.bool(forKey: kVLCSettingHideLibraryInFilesApp)
        excludeFromDeviceBackup(excludeMediaLibrary)
        hideMediaLibrary(hideML)

        if UserDefaults.standard.bool(forKey: MediaLibraryService.didForceRescan) == false {
            medialib.forceRescan()
            UserDefaults.standard.set(true, forKey: MediaLibraryService.didForceRescan)
        }

        FileManager.default.createFile(atPath: "\(path)/\(NSLocalizedString("MEDIALIBRARY_FILES_PLACEHOLDER", comment: ""))", contents: nil, attributes: nil)
        try? FileManager.default.removeItem(atPath: "\(path)/\(NSLocalizedString("MEDIALIBRARY_ADDING_PLACEHOLDER", comment: ""))")

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
            if triedToRecoverFromInitializationErrorOnce == false {
                triedToRecoverFromInitializationErrorOnce = true
                do {
                    APLog(String(format: "MediaLibraryService: Failed to setup medialibrary, trying to recover by deleting previous database (%@)", databasePath))
                    try FileManager.default.removeItem(atPath: databasePath)
                    setupMediaLibrary()
                    return
                } catch let error as NSError {
                    APLog(String(format: "Failed to delete previous database (%@)", error.localizedDescription))
                }
            }
            preconditionFailure("MediaLibraryService: Permanently failed to setup medialibrary.")
        case .dbCorrupted:
            medialib.clearDatabase(restorePlaylists: true)
            startMediaLibrary(on: documentPath)
        @unknown default:
            assertionFailure("MediaLibraryService: unhandled case")
        }
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


    private func saveMetaData(of media: VLCMLMedia?, from player: PlaybackService) {
        guard let mlMedia = media else {
            return
        }

        mlMedia.isNew = false
        mlMedia.progress = player.playbackPosition
        mlMedia.audioTrackIndex = Int64(player.indexOfCurrentAudioTrack)
        mlMedia.subtitleTrackIndex = Int64(player.indexOfCurrentSubtitleTrack)
        mlMedia.chapterIndex = Int64(player.indexOfCurrentChapter)
        mlMedia.titleIndex = Int64(player.indexOfCurrentTitle)

        if mlMedia.type() != .audio {
            if let thumbnailURL = mlMedia.thumbnail() {
                if mlMedia.progress < 0.90 {
                    mlMedia.removeThumbnail(of: .thumbnail)
                    VLCThumbnailsCache.invalidateThumbnail(for: thumbnailURL)
                }
            }
            mlMedia.requestThumbnail(of: .thumbnail, desiredWidth: desiredThumbnailWidth,
                                     desiredHeight: desiredThumbnailHeight, atPosition: player.playbackPosition)
        }
    }

    func savePlaybackState(from player: PlaybackService) {
        let media: VLCMedia? = player.currentlyPlayingMedia

        guard let mrl = media?.url?.absoluteURL else {
            // No URL from currently played media
            return
        }

        var mlMedia: VLCMLMedia? = medialib.media(withMrl: mrl)

        if mlMedia == nil {
            // Add media unknown to the medialibrary.
            mlMedia = medialib.addExternalMedia(withMrl: mrl)
        }
        saveMetaData(of: mlMedia, from: player)
    }

    @objc func excludeFromDeviceBackup(_ exclude: Bool) {
        if let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            var documentURL = URL(fileURLWithPath: documentPath)
            isExcludingFromBackup = true
            deviceBackupDelegate?.medialibraryDidStartExclusion()
            DispatchQueue.global().async {
                documentURL.setExcludedFromBackup(exclude, recursive: true, onlyFirstLevel: true) {
                    self.isExcludingFromBackup = false
                    self.deviceBackupDelegate?.medialibraryDidCompleteExclusion()
                }
            }
        }
        if let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first {
            var mlURL = URL(fileURLWithPath: libraryPath).appendingPathComponent("MediaLibrary")
            DispatchQueue.global().async {
                mlURL.setExcludedFromBackup(exclude, recursive: true, onlyFirstLevel: true)
            }
        }
    }

    @objc func hideMediaLibrary(_ hide: Bool) {
        if let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            var documentURL = URL(fileURLWithPath: documentPath)
            isHidingLibrary = true
            hidingDelegate?.medialibraryDidStartHiding()
            DispatchQueue.global().async {
                documentURL.setHidden(hide, recursive: true, onlyFirstLevel: false) {
                    self.isHidingLibrary = false
                    self.hidingDelegate?.medialibraryDidCompleteHiding()
                }
            }
        }
    }

    @objc func exportMediaLibrary() {
        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first else {
                preconditionFailure("MediaLibraryService: Unable to find medialibrary.")
        }

        let databasePath = libraryPath + "/MediaLibrary/" + MediaLibraryService.databaseName
        let targetPath = documentPath + "/Logs/" + MediaLibraryService.databaseName

        do {
            try FileManager.default.createDirectory(atPath: targetPath,
                                                    withIntermediateDirectories: true)
        } catch let error as NSError {
            assertionFailure("Failed to create directory: \(error.localizedDescription)")
        }

        _ = try? FileManager.default.removeItem(atPath: targetPath)
        _ = try? FileManager.default.copyItem(atPath: databasePath, toPath: targetPath)
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
        // Run this on a background queue to not block the main thread and have the app killed on launch for taking too long
        DispatchQueue.global(qos: .userInitiated).async {
            _ = try? FileManager.default.removeItem(atPath: documentPath + "/.Trash")

            DispatchQueue.main.async {
                // Reload in order to make sure that there is no old artifacts left
                self.reload()
            }
        }
    }
}

// MARK: - Audio methods

@objc extension MediaLibraryService {
    func artists(sortingCriteria sort: VLCMLSortingCriteria = .alpha,
                 desc: Bool = false, listAll all: Bool = true) -> [VLCMLArtist] {
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
        switch media.thumbnailStatus() {
        case .available, .persistentFailure, .crash:
            return
        case .missing, .failure:
            break
        @unknown default:
            assertionFailure("MediaLibraryService: requestThumbnail: unknown case.")
        }

        if !media.requestThumbnail(of: .thumbnail, desiredWidth: desiredThumbnailWidth, desiredHeight: desiredThumbnailHeight, atPosition: 0.03) {
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

@objc extension MediaLibraryService {
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

        for observer in observable.observers {
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
        for observer in observable.observers {
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

        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, didDeleteMediaWithIds: mediaIds)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, thumbnailReadyFor media: VLCMLMedia,
                      of type: VLCMLThumbnailSizeType, withSuccess success: Bool) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, thumbnailReady: media,
                                                   type: type, success: success)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Artists

extension MediaLibraryService {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd artists: [VLCMLArtist]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, didAddArtists: artists)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary,
                      didModifyArtistsWithIds artistsIds: [NSNumber]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, didModifyArtistsWithIds: artistsIds)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didDeleteArtistsWithIds artistsIds: [NSNumber]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, didDeleteArtistsWithIds: artistsIds)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Albums

extension MediaLibraryService {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd albums: [VLCMLAlbum]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, didAddAlbums: albums)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary,
                      didModifyAlbumsWithIds albumsIds: [NSNumber]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, didModifyAlbumsWithIds: albumsIds)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didDeleteAlbumsWithIds albumsIds: [NSNumber]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, didDeleteAlbumsWithIds: albumsIds)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Genres

extension MediaLibraryService {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd genres: [VLCMLGenre]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, didAddGenres: genres)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary,
                      didModifyGenresWithIds genresIds: [NSNumber]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, didModifyGenresWithIds: genresIds)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary,
                      didDeleteGenresWithIds genresIds: [NSNumber]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, didDeleteGenresWithIds: genresIds)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Playlists

extension MediaLibraryService {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd playlists: [VLCMLPlaylist]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, didAddPlaylists: playlists)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary,
                      didModifyPlaylistsWithIds playlistsIds: [NSNumber]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, didModifyPlaylistsWithIds: playlistsIds)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didDeletePlaylistsWithIds playlistsIds: [NSNumber]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, didDeletePlaylistsWithIds: playlistsIds)
        }
    }
}

// MARK: - VLCMediaLibraryDelegate - Media groups

extension MediaLibraryService {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd mediaGroups: [VLCMLMediaGroup]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self,
                                                   didAddMediaGroups: mediaGroups)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary,
                      didModifyMediaGroupsWithIds mediaGroupsIds: [NSNumber]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self,
                                                   didModifyMediaGroupsWithIds: mediaGroupsIds)
        }
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary,
                      didDeleteMediaGroupsWithIds mediaGroupsIds: [NSNumber]) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self,
                                                   didDeleteMediaGroupsWithIds: mediaGroupsIds)
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
        for observer in observable.observers {
            observer.value.observer?.medialibraryDidStartRescan?()
        }
    }
}

extension MediaLibraryService {
    func medialibrary(_ medialibrary: VLCMediaLibrary, historyChangedOf type: VLCMLHistoryType) {
        for observer in observable.observers {
            observer.value.observer?.medialibrary?(self, historyChangedOfType: type)
        }
    }
}
