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

    var sortModel = SortModel([.alpha, .duration, .insertionDate, .releaseDate, .fileSize])

    var mediaCollection: MediaCollectionModel

    var medialibrary: MediaLibraryService

    var observable = Observable<MediaLibraryBaseModelObserver>()

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
        files = mediaCollection.files() ?? []
        medialibrary.observable.addObserver(self)
    }

    func append(_ item: VLCMLMedia) {
        files.append(item)
    }

    func delete(_ items: [MLType]) {
        if let playlist = mediaCollection as? VLCMLPlaylist {
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
            filterFilesFromDeletion(of: items)
        }
    }

    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
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
        if mediaCollection is VLCMLPlaylist {
            files = mediaCollection.files() ?? []
            observable.observers.forEach() {
                $0.value.observer?.mediaLibraryBaseModelReloadView()
            }
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didModifyTracks tracks: [VLCMLMedia]) {
        files = mediaCollection.files() ?? []
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteMediaWithIds ids: [NSNumber]) {
        files = mediaCollection.files() ?? []
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      thumbnailReady media: VLCMLMedia,
                      type: VLCMLThumbnailSizeType, success: Bool) {
        guard success else {
            return
        }
        files = mediaCollection.files() ?? []
        observable.observers.forEach() {
            $0.value.observer?.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibraryDidStartRescan() {
        files.removeAll()
    }
}

