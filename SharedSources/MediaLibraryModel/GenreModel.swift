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

    var sortModel = SortModel([.alpha])

    var updateView: (() -> Void)?

    var files = [VLCMLGenre]()

    var cellType: BaseCollectionViewCell.Type { return GenreCollectionViewCell.self }

    var medialibrary: MediaLibraryService

    var indicatorName: String = NSLocalizedString("GENRES", comment: "")

    required init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.genres()
    }

    func append(_ item: VLCMLGenre) {
        files.append(item)
    }

    func delete(_ items: [VLCMLObject]) {
        preconditionFailure("GenreModel: Genres can not be deleted, they disappear when their last title got deleted")
    }

    func createPlaylist(_ name: String, _ fileIndexes: Set<IndexPath>? = nil) {
        let playlist = medialibrary.createPlaylist(with: name)

        guard let fileIndexes = fileIndexes else {
            return
        }

        for index in fileIndexes  where index.row < files.count {
            // Get all tracks from a VLCMLGenre
            guard let tracks = files[index.row].tracks(with: .default, desc: false) else {
                assertionFailure("GenreModel: createPlaylist: Fail to retreive tracks.")
                return
            }

            tracks.forEach() {
                playlist.appendMedia(withIdentifier: $0.identifier())
            }
        }
    }
}

// MARK: - Sort

extension GenreModel {
    func sort(by criteria: VLCMLSortingCriteria) {
        files = medialibrary.genres(sortingCriteria: criteria)
        sortModel.currentSort = criteria
        updateView?()
    }
}

// MARK: - MediaLibraryObserver

extension GenreModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddGenres genres: [VLCMLGenre]) {
        genres.forEach({ append($0) })
        updateView?()
    }
}

// MARK: - Edit

extension GenreModel: EditableMLModel {
    func editCellType() -> BaseCollectionViewCell.Type {
        return MediaEditCell.self
    }
}

// MARK: - Helpers

extension VLCMLGenre {
    @objc func numberOfTracksString() -> String {
        let numberOftracks = numberOfTracks()
        if numberOftracks != 1 {
            return String(format: NSLocalizedString("TRACKS", comment: ""), numberOftracks)
        }
        return String(format: NSLocalizedString("TRACK", comment: ""), numberOftracks)
    }
}

extension VLCMLGenre: MediaCollectionModel {
    func sortModel() -> SortModel? {
        return SortModel([.alpha])
    }

    func files() -> [VLCMLMedia] {
        return tracks()
    }
}
