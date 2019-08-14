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
        guard let playlist = medialibrary.createPlaylist(with: name) else {
            assertionFailure("PlaylistModel: create: Failed to create a playlist.")
            return
        }
        append(playlist)
        updateView?()
    }
}

// MARK: - Sort
extension PlaylistModel {
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        files = medialibrary.playlists(sortingCriteria: criteria, desc: desc)
        sortModel.currentSort = criteria
        sortModel.desc = desc
        updateView?()
    }
}

// MARK: - Edit
extension PlaylistModel: EditableMLModel {
    func editCellType() -> BaseCollectionViewCell.Type {
        return MediaEditCell.self
    }
}

// MARK: - Search
extension VLCMLPlaylist: SearchableMLModel {
    func contains(_ searchString: String) -> Bool {
        return name.lowercased().contains(searchString)
    }
}

// MARK: - MediaLibraryObserver
extension PlaylistModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddPlaylists playlists: [VLCMLPlaylist]) {
        playlists.forEach({ append($0) })
        updateView?()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didModifyPlaylists playlists: [VLCMLPlaylist]) {
        files = swapModels(with: playlists)
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
    func numberOfTracksString() -> String {
        let mediaCount = media?.count ?? 0
        let tracksString = mediaCount > 1 ? NSLocalizedString("TRACKS", comment: "") : NSLocalizedString("TRACK", comment: "")
        return String(format: tracksString, mediaCount)
    }

    @objc func thumbnail() -> UIImage? {
        var image = UIImage(contentsOfFile: artworkMrl())
        if image == nil {
            for track in files() ?? [] where track.isThumbnailGenerated() {
                image = UIImage(contentsOfFile: track.thumbnail()?.path ?? "")
                break
            }
        }
        if image == nil {
            let isDarktheme = PresentationTheme.current == PresentationTheme.darkTheme
            image = isDarktheme ? UIImage(named: "movie-placeholder-dark") : UIImage(named: "movie-placeholder-white")
        }
        return image
    }

    func accessibilityText() -> String? {
        return name + " " + numberOfTracksString()
    }
}

extension VLCMLPlaylist: MediaCollectionModel {
    func sortModel() -> SortModel? {
        return nil
    }

    func files() -> [VLCMLMedia]? {
        return media
    }

    func title() -> String? {
        return name
    }
}
