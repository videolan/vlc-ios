/*****************************************************************************
 * AlbumModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class AlbumModel: MLBaseModel {
    typealias MLType = VLCMLAlbum

    var updateView: (() -> Void)?

    var files = [VLCMLAlbum]()

    var cellType: BaseCollectionViewCell.Type { return AlbumCollectionViewCell.self }

    var medialibrary: VLCMediaLibraryManager

    var indicatorName: String = NSLocalizedString("ALBUMS", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.getAlbums()
    }

    func append(_ item: VLCMLAlbum) {
        files.append(item)
    }

    func delete(_ items: [VLCMLObject]) {
        preconditionFailure("AlbumModel: Cannot delete album")
    }
}

extension AlbumModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddAlbums albums: [VLCMLAlbum]) {
        albums.forEach({ append($0) })
        updateView?()
    }
}
