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

    var indicatorName: String = NSLocalizedString("ALBUMS", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
        medialibrary.addObserver(self)
        // created too late so missed the callback asking if he has anything
        files = medialibrary.getAlbums()
    }

    func isIncluded(_ item: VLCMLAlbum) {
    }

    func append(_ item: VLCMLAlbum) {
        // need to check more for duplicate and stuff
        files.append(item)
    }
}

extension AlbumModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddAlbum album: [VLCMLAlbum]) {
        album.forEach({ append($0) })
        updateView?()
    }
}
