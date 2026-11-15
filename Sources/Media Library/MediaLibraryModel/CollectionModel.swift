/*****************************************************************************
 * CollectionModel.swift
 *
 * Copyright © 2019-2026 VLC authors and VideoLAN
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class CollectionModel: MLBaseModel {
    var currentPage: Int = 0
    var hasMorePages: Bool = false
    var isLoading: Bool = false

    func fetchPage(offset: Int, limit: Int) -> [VLCMLMedia] {
        return []
    }

    func getMedia() {
        // dummy
    }

    typealias MLType = VLCMLMedia

    var sortModel = SortModel([.alpha, .duration, .insertionDate, .releaseDate, .fileSize, .lastPlaybackDate, .playCount])

    var mediaCollection: MediaCollectionModel

    var thumbnail: UIImage?

    var medialibrary: MediaLibraryService

    var observable = VLCObservable<MediaLibraryBaseModelObserver>()

    var fileArrayLock = NSRecursiveLock()
    var files = [VLCMLMedia]()

    var cellType: BaseCollectionViewCell.Type {
        if mediaCollection is VLCMLMediaGroup {
            return UserDefaults.standard.bool(forKey: "\(kVLCVideoLibraryGridLayout)\(String(describing: type(of: mediaCollection)) + name)") ?
                                              MovieCollectionViewCell.self : MediaCollectionViewCell.self
        } else {
            return UserDefaults.standard.bool(forKey: "\(kVLCAudioLibraryGridLayout)\(String(describing: type(of: mediaCollection)) + name)") ?
                                              MediaGridCollectionCell.self : MediaCollectionViewCell.self
        }
    }

    var name: String = "Collections"

    var indicatorName: String = NSLocalizedString("SONGS", comment: "")

    required init(medialibrary: MediaLibraryService) {
        preconditionFailure("")
    }

    required init(mediaService: MediaLibraryService, mediaCollection: MediaCollectionModel) {
        defer {
            fileArrayLock.unlock()
        }
        self.medialibrary = mediaService
        self.mediaCollection = mediaCollection
        self.name += String(describing: type(of: mediaCollection))

        self.sortModel = mediaCollection.sortModel() ?? self.sortModel

        var sortingCriteria: VLCMLSortingCriteria = .default

        if mediaCollection is VLCMLArtist
            || mediaCollection is VLCMLGenre
            || mediaCollection is VLCMLAlbum {
            sortingCriteria = .album
        }

        self.sortModel.currentSort = sortingCriteria

        self.thumbnail = mediaCollection.thumbnail()

        fileArrayLock.lock()
        files = mediaCollection.files() ?? []
        medialibrary.observable.addObserver(self)
    }

    func append(_ item: VLCMLMedia) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files.append(item)
    }

    func delete(_ items: [MLType]) {
        defer {
            fileArrayLock.unlock()
        }
        if let playlist = mediaCollection as? VLCMLPlaylist {
            fileArrayLock.lock()
            let tracks = playlist.media ?? []
            var positions = [Int]()
            for (identifier, selected) in Dictionary(grouping: items, by: { $0.identifier() }) {
                let copies = tracks.indices.filter { tracks[$0].identifier() == identifier }
                let displayedCopies = files.filter { $0.identifier() == identifier }
                let ranks = selected.compactMap { media in displayedCopies.firstIndex { $0 === media } }
                let chosenRanks = ranks.count == selected.count ? ranks : Array(0..<selected.count)
                positions += chosenRanks.filter { $0 < copies.count }.map { copies[$0] }
            }
            for position in positions.sorted(by: >) {
                playlist.removeMedia(fromPosition: UInt32(position))
            }
        } else {
            do {
                for case let media in items {
                    if let mainFile = media.mainFile() {
                        mainFile.delete()
                    }
                }
                medialibrary.reload()
            }
            fileArrayLock.lock()
            filterFilesFromDeletion(of: items)
        }
    }

    func reorderFiles(to order: [Int]) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        guard let playlist = mediaCollection as? VLCMLPlaylist,
              order.count == files.count else {
            return
        }

        var currentOrder = Array(files.indices)
        for (position, index) in order.enumerated() where currentOrder[position] != index {
            guard let currentPosition = currentOrder.firstIndex(of: index) else {
                continue
            }
            playlist.moveMedia(fromPosition: UInt32(currentPosition), toDestination: UInt32(position))
            currentOrder.remove(at: currentPosition)
            currentOrder.insert(index, at: position)
        }
        files = order.map { files[$0] }
    }

    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files = mediaCollection.files(with: criteria, desc: desc) ?? []
        sortModel.currentSort = criteria
        sortModel.desc = desc
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    private func updateMediaCollection(_ updatedCollection: MediaCollectionModel) {
        DispatchQueue.main.async {
            self.fileArrayLock.lock()
            defer { self.fileArrayLock.unlock() }
            self.mediaCollection = updatedCollection
            self.thumbnail = updatedCollection.thumbnail()
            self.files = updatedCollection.files(with: self.sortModel.currentSort, desc: self.sortModel.desc) ?? []
            self.observable.notifyObservers {
                $0.mediaLibraryBaseModelReloadView()
            }
        }
    }
}

// MARK: - MediaLibraryObserver
extension CollectionModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService,
                      didModifyPlaylistsWithIds playlistsIds: [NSNumber]) {
        guard let playlist = mediaCollection as? VLCMLPlaylist,
              playlistsIds.contains(where: { $0.int64Value == playlist.identifier() }),
              let updatedPlaylist = medialibrary.medialib.playlist(withIdentifier: playlist.identifier()) else {
            return
        }
        updateMediaCollection(updatedPlaylist)
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didModifyAlbumsWithIds albumsIds: [NSNumber]) {
        guard let album = mediaCollection as? VLCMLAlbum,
              albumsIds.contains(where: { $0.int64Value == album.identifier() }),
              let updatedAlbum = medialibrary.medialib.album(withIdentifier: album.identifier()) else {
            return
        }
        updateMediaCollection(updatedAlbum)
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didModifyArtistsWithIds artistsIds: [NSNumber]) {
        guard let artist = mediaCollection as? VLCMLArtist,
              artistsIds.contains(where: { $0.int64Value == artist.identifier() }),
              let updatedArtist = medialibrary.medialib.artist(withIdentifier: artist.identifier()) else {
            return
        }
        updateMediaCollection(updatedArtist)
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didModifyGenresWithIds genresIds: [NSNumber]) {
        guard let genre = mediaCollection as? VLCMLGenre,
              genresIds.contains(where: { $0.int64Value == genre.identifier() }),
              let updatedGenre = medialibrary.medialib.genre(withIdentifier: genre.identifier()) else {
            return
        }
        updateMediaCollection(updatedGenre)
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didModifyMediaGroupsWithIds mediaGroupsIds: [NSNumber]) {
        guard let mediaGroup = mediaCollection as? VLCMLMediaGroup,
              mediaGroupsIds.contains(where: { $0.int64Value == mediaGroup.identifier() }),
              let updatedMediaGroup = medialibrary.medialib.mediaGroup(withIdentifier: mediaGroup.identifier()) else {
            return
        }
        updateMediaCollection(updatedMediaGroup)
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didModifyTracks tracks: [VLCMLMedia]) {
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        files = mediaCollection.files(with: sortModel.currentSort, desc: sortModel.desc) ?? []
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteMediaWithIds ids: [NSNumber]) {
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        files = mediaCollection.files(with: sortModel.currentSort, desc: sortModel.desc) ?? []
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      thumbnailReady media: VLCMLMedia,
                      type: VLCMLThumbnailSizeType, success: Bool) {
        guard success else {
            return
        }
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        files = mediaCollection.files(with: sortModel.currentSort, desc: sortModel.desc) ?? []
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
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

