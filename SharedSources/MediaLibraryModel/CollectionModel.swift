//
//  CollectionModel.swift
//  VLC-iOS
//
//  Created by Carola Nitz on 08.03.19.
//  Copyright © 2019 VideoLAN. All rights reserved.
//

import Foundation

class CollectionModel: MLBaseModel {
    var sortModel: SortModel
    var mediaCollection: MediaCollectionModel

    typealias MLType = VLCMLMedia // could be anything
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

    var medialibrary: MediaLibraryService
    var updateView: (() -> Void)?

    var files = [VLCMLMedia]()

    var cellType: BaseCollectionViewCell.Type { return MediaCollectionViewCell.self }

    // No indicator for this model so no localization needed.
    var indicatorName: String = "Collections"

    func delete(_ items: [VLCMLObject]) {
        if let playlist = mediaCollection as? VLCMLPlaylist {
            for item in items where item is VLCMLMedia {
                if let index = files.firstIndex(of: item as! VLCMLMedia) {
                    playlist.removeMedia(fromPosition: UInt32(index))
                }
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
}

