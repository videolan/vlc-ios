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

class GenreModel: MediaLibraryBaseModel {
    typealias MLType = VLCMLGenre

    var updateView: (() -> Void)?

    var files = [VLCMLGenre]()

    var indicatorName: String = NSLocalizedString("GENRE", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
        medialibrary.addObserver(self)
        // created too late so missed the callback asking if he has anything
        files = medialibrary.genre()
    }

    func isIncluded(_ item: VLCMLGenre) {
    }

    func append(_ item: VLCMLGenre) {
        // need to check more for duplicate and stuff
        files.append(item)
    }
}

extension GenreModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddGenre genre: [VLCMLGenre]) {
        genre.forEach({ append($0) })
        updateView?()
    }
}
