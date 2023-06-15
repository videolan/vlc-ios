/*****************************************************************************
 * CollectionModel.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class CollectionModel: MLBaseModel {
    typealias MLType = VLCMLMedia

    var sortModel = SortModel([.alpha, .duration, .insertionDate, .releaseDate, .fileSize, .lastPlaybackDate, .playCount])

    var mediaCollection: MediaCollectionModel

    var thumbnail: UIImage?

    var medialibrary: MediaLibraryService

    var observable = Observable<MediaLibraryBaseModelObserver>()

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
            for case let media in items {
                if let index = files.firstIndex(of: media) {
                    playlist.removeMedia(fromPosition: UInt32(index))
                }
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

    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files = mediaCollection.files(with: criteria, desc: desc) ?? []
        sortModel.currentSort = criteria
        sortModel.desc = desc
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }
    }
}

// MARK: - MediaLibraryObserver
extension CollectionModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService,
                      didModifyPlaylistsWithIds playlistsIds: [NSNumber]) {
        defer {
            fileArrayLock.unlock()
        }
        if mediaCollection is VLCMLPlaylist {
            fileArrayLock.lock()
            files = mediaCollection.files() ?? []
            observable.observers.forEach() {
                $0.value.observer?.mediaLibraryBaseModelReloadView()
            }

            sort(by: sortModel.currentSort, desc: sortModel.desc)
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didModifyTracks tracks: [VLCMLMedia]) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files = mediaCollection.files() ?? []
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }

        sort(by: sortModel.currentSort, desc: sortModel.desc)
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteMediaWithIds ids: [NSNumber]) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files = mediaCollection.files() ?? []
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }

        sort(by: sortModel.currentSort, desc: sortModel.desc)
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      thumbnailReady media: VLCMLMedia,
                      type: VLCMLThumbnailSizeType, success: Bool) {
        guard success else {
            return
        }
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files = mediaCollection.files() ?? []
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }

        sort(by: sortModel.currentSort, desc: sortModel.desc)
    }

    func medialibraryDidStartRescan() {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files.removeAll()
    }
}

