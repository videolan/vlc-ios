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

    var cellType: BaseCollectionViewCell.Type { return MovieCollectionViewCell.self }

    var medialibrary: VLCMediaLibraryManager

    var indicatorName: String = NSLocalizedString("PLAYLISTS", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.getPlaylists()
    }

    func append(_ item: VLCMLPlaylist) {
        for file in files {
            if file.identifier() == item.identifier() {
                return
            }
        }
        files.append(item)
    }

    func delete(_ items: [VLCMLObject]) {
        for playlist in items where playlist is VLCMLPlaylist {
            if !(medialibrary.deletePlaylist(with: playlist.identifier())) {
                assertionFailure("PlaylistModel: Failed to delete playlist: \(playlist.identifier())")
            }
        }
    }

    // Creates a VLCMLPlaylist appending it and updates linked view
    func create(name: String) {
        append(medialibrary.createPlaylist(with: name))
        updateView?()
    }
}

extension PlaylistModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddPlaylists playlists: [VLCMLPlaylist]) {
        playlists.forEach({ append($0) })
        updateView?()
    }

    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didDeletePlaylistsWithIds playlistsIds: [NSNumber]) {
        files = files.filter() {
            for id in playlistsIds where $0.identifier() == id.int64Value {
                return false
            }
            return true
        }
        updateView?()
    }
}
