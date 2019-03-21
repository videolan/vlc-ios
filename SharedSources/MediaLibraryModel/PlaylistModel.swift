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

    var sortModel = SortModel([.alpha, .duration])

    var updateView: (() -> Void)?

    var files = [VLCMLPlaylist]()

    var cellType: BaseCollectionViewCell.Type { return MovieCollectionViewCell.self }

    var medialibrary: MediaLibraryService

    var indicatorName: String = NSLocalizedString("PLAYLISTS", comment: "")

    required init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.playlists()
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

    func createPlaylist(_ name: String, _ fileIndexes: Set<IndexPath>? = nil) {
        let playlist = medialibrary.createPlaylist(with: name)

        guard let fileIndexes = fileIndexes else {
            return
        }

        for index in fileIndexes  where index.row < files.count {
            // Get all tracks from a VLCMLPlaylist
            guard let media = files[index.row].media else {
                assertionFailure("PlaylistModel: createPlaylist: Failed to retreive media.")
                return
            }

            media.forEach() {
                playlist.appendMedia(withIdentifier: $0.identifier())
            }
        }
    }
}

// MARK: - Sort

extension PlaylistModel {
    func sort(by criteria: VLCMLSortingCriteria) {
        files = medialibrary.playlists(sortingCriteria: criteria)
        sortModel.currentSort = criteria
        updateView?()
    }
}

// MARK: - MediaLibraryObserver

extension PlaylistModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddPlaylists playlists: [VLCMLPlaylist]) {
        playlists.forEach({ append($0) })
        updateView?()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeletePlaylistsWithIds playlistsIds: [NSNumber]) {
        files = files.filter() {
            for id in playlistsIds where $0.identifier() == id.int64Value {
                return false
            }
            return true
        }
        updateView?()
    }
}

// MARK: - Helpers

extension VLCMLPlaylist {
    func description() -> String {
        let tracksString = media.count == 1 ? NSLocalizedString("TRACK", comment: "") : NSLocalizedString("TRACKS", comment: "")
        return String(format: tracksString, media.count)
    }
}

extension VLCMLPlaylist: MediaCollectionModel {
    func sortModel() -> SortModel? {
        return nil
    }

    func files() -> [VLCMLMedia] {
        return media
    }
}
