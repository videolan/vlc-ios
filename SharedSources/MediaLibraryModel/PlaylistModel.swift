/*****************************************************************************
 * PlaylistModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class PlaylistModel: MLBaseModel {
    typealias MLType = VLCMLPlaylist

    var updateView: (() -> Void)?

    var files = [VLCMLPlaylist]()

    var medialibrary: VLCMediaLibraryManager

    var indicatorName: String = NSLocalizedString("PLAYLISTS", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.getPlaylists()
    }

    func append(_ item: VLCMLPlaylist) {
        files.append(item)
    }
}

extension PlaylistModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddPlaylists playlists: [VLCMLPlaylist]) {
        playlists.forEach({ append($0) })
        updateView?()
    }
}
