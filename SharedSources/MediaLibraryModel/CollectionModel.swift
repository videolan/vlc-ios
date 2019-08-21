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

    var sortModel: SortModel

    var mediaCollection: MediaCollectionModel

    var medialibrary: MediaLibraryService

    var updateView: (() -> Void)?

    var files = [VLCMLMedia]()

    var cellType: BaseCollectionViewCell.Type { return MediaCollectionViewCell.self }

    // No indicator for this model so no localization needed.
    var indicatorName: String = "Collections"

    required init(medialibrary: MediaLibraryService) {
        preconditionFailure("")
    }

    required init(mediaService: MediaLibraryService, mediaCollection: MediaCollectionModel) {
        self.medialibrary = mediaService
        self.mediaCollection = mediaCollection
        files = mediaCollection.files() ?? []
        sortModel = mediaCollection.sortModel() ?? SortModel([.default])
        medialibrary.addObserver(self)
    }

    func append(_ item: VLCMLMedia) {
        files.append(item)
    }

    func delete(_ items: [VLCMLObject]) {
        if let playlist = mediaCollection as? VLCMLPlaylist {
            for case let media as VLCMLMedia in items {
                if let index = files.firstIndex(of: media) {
                    playlist.removeMedia(fromPosition: UInt32(index))
                }
            }
        } else {
            do {
                for case let media as VLCMLMedia in items {
                    if let mainFile = media.mainFile() {
                        try FileManager.default.removeItem(atPath: mainFile.mrl.path)
                    }
                }
                medialibrary.reload()
            }
            catch let error as NSError {
                assertionFailure("CollectionModel: Delete failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Edit
extension CollectionModel: EditableMLModel {
    func editCellType() -> BaseCollectionViewCell.Type {
        return MediaEditCell.self
    }
}

// MARK: - MediaLibraryObserver
extension CollectionModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didModifyPlaylists playlists: [VLCMLPlaylist]) {
        if mediaCollection is VLCMLPlaylist {
            files = mediaCollection.files() ?? []
            updateView?()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteMediaWithIds ids: [NSNumber]) {
        files = mediaCollection.files() ?? []
        updateView?()
    }
}

