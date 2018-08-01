/*****************************************************************************
 * ArtistModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class ArtistModel: MLBaseModel {
    typealias MLType = VLCMLArtist

    var updateView: (() -> Void)?

    var files = [VLCMLArtist]()

    var medialibrary: VLCMediaLibraryManager

    var indicatorName: String = NSLocalizedString("ARTISTS", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.getArtists()
    }

    func isIncluded(_ item: VLCMLArtist) {
    }

    func append(_ item: VLCMLArtist) {
        files.append(item)
    }
}

extension ArtistModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddArtist artist: [VLCMLArtist]) {
        artist.forEach({ append($0) })
        updateView?()
    }
}
