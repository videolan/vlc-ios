/*****************************************************************************
 * GenreModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class GenreModel: MLBaseModel {
    typealias MLType = VLCMLGenre

    var updateView: (() -> Void)?

    var files = [VLCMLGenre]()

    var cellType: BaseCollectionViewCell.Type { return MovieCollectionViewCell.self }

    var medialibrary: VLCMediaLibraryManager

    var indicatorName: String = NSLocalizedString("GENRES", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.genre()
    }

    func append(_ item: VLCMLGenre) {
        files.append(item)
    }

    func delete(_ items: [VLCMLObject]) {
        preconditionFailure("GenreModel: Cannot delete genre")
    }
}

extension GenreModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddGenres genres: [VLCMLGenre]) {
        genres.forEach({ append($0) })
        updateView?()
    }
}
