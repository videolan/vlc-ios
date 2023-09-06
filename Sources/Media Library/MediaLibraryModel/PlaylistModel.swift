/*****************************************************************************
 * PlaylistModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class PlaylistModel: MLBaseModel {
    typealias MLType = VLCMLPlaylist

    var sortModel = SortModel([.alpha, .duration])

    var observable = Observable<MediaLibraryBaseModelObserver>()

    var fileArrayLock = NSRecursiveLock()
    var files = [VLCMLPlaylist]()

    var cellType: BaseCollectionViewCell.Type {
        return UserDefaults.standard.bool(forKey: "\(kVLCAudioLibraryGridLayout)\(name)") ? MovieCollectionViewCell.self : MediaCollectionViewCell.self
    }

    var medialibrary: MediaLibraryService

    var name: String = "PLAYLISTS"

    var indicatorName: String = NSLocalizedString("PLAYLISTS", comment: "")

    required init(medialibrary: MediaLibraryService) {
        defer {
            fileArrayLock.unlock()
        }
        self.medialibrary = medialibrary
        medialibrary.observable.addObserver(self)
        fileArrayLock.lock()
        files = medialibrary.playlists()
    }

    func append(_ item: VLCMLPlaylist) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        for file in files {
            if file.identifier() == item.identifier() {
                return
            }
        }
        files.append(item)
    }

    func delete(_ items: [VLCMLPlaylist]) {
        defer {
            fileArrayLock.unlock()
        }
        for case let playlist in items {
            if !(medialibrary.deletePlaylist(with: playlist.identifier())) {
                assertionFailure("PlaylistModel: Failed to delete playlist: \(playlist.identifier())")
            }
            if playlist.isReadOnly {
                do {
                    if let path = playlist.mrl?.path, !path.isEmpty {
                        try FileManager.default.removeItem(atPath: path)
                    }
                } catch let error as NSError {
                    assertionFailure("PlaylistModel: Delete failed: \(error.localizedDescription)")
                }
            }
        }

        // Update directly the UI without waiting the delegate to avoid showing 'ghost' items
        fileArrayLock.lock()
        filterFilesFromDeletion(of: items)
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }
    }

    // Creates a VLCMLPlaylist appending it and updates linked view
    func create(name: String) {
        guard let playlist = medialibrary.createPlaylist(with: name) else {
            assertionFailure("PlaylistModel: create: Failed to create a playlist.")
            return
        }
        append(playlist)
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }
    }
}

// MARK: - Sort
extension PlaylistModel {
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files = medialibrary.playlists(sortingCriteria: criteria, desc: desc)
        sortModel.currentSort = criteria
        sortModel.desc = desc
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }
    }
}

// MARK: - Search
extension VLCMLPlaylist: SearchableMLModel {
    func contains(_ searchString: String) -> Bool {
        return name.lowercased().contains(searchString)
    }
}

// MARK: - MediaLibraryObserver
extension PlaylistModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddPlaylists playlists: [VLCMLPlaylist]) {
        playlists.forEach({ append($0) })
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didModifyPlaylistsWithIds playlistsIds: [NSNumber]) {
        defer {
            fileArrayLock.unlock()
        }
        var playlists = [VLCMLPlaylist]()

        playlistsIds.forEach() {
            guard let safePlaylist = medialibrary.medialib.playlist(withIdentifier: $0.int64Value)
                else {
                    return
            }
            playlists.append(safePlaylist)
        }

        fileArrayLock.lock()
        files = swapModels(with: playlists)
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeletePlaylistsWithIds playlistsIds: [NSNumber]) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files = files.filter() {
            for id in playlistsIds where $0.identifier() == id.int64Value {
                return false
            }
            return true
        }
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibraryDidStartRescan() {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files.removeAll()
    }
}

// MARK: - Helpers

extension VLCMLPlaylist {
    func numberOfTracksString() -> String {
        let mediaCount = media?.count ?? 0
        let tracksString = mediaCount > 1 ? NSLocalizedString("TRACKS", comment: "") : NSLocalizedString("TRACK", comment: "")
        return String(format: tracksString, mediaCount)
    }

    func durationString() -> String {
        return String(format: "%@", VLCTime(number: NSNumber.init(value: duration())))
    }

    @objc func thumbnailImage() -> UIImage? {
        let artworkMRL = URL.init(string: artworkMrl())
        var image = VLCThumbnailsCache.thumbnail(for: artworkMRL)
        if image == nil {
            guard let tracks = media else {
                return nil
            }
            for iter in tracks {
                if iter.thumbnailStatus() == .available {
                    image = iter.thumbnailImage()
                    break
                }
            }
        }
        return image
    }

    func accessibilityText() -> String? {
        return name + " " + numberOfTracksString()
    }
}

extension VLCMLPlaylist: MediaCollectionModel {
    func sortModel() -> SortModel? {
        return nil
    }

    func files(with criteria: VLCMLSortingCriteria = .alpha,
               desc: Bool = false) -> [VLCMLMedia]? {
        return media
    }

    func title() -> String {
        return name
    }
}
