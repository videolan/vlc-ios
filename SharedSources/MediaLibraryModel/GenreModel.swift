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

class GenreModel: AudioCollectionModel {
    typealias MLType = VLCMLGenre

    var sortModel = SortModel([.alpha])

    var updateView: (() -> Void)?

    var files = [VLCMLGenre]()

    var cellType: BaseCollectionViewCell.Type { return MediaCollectionViewCell.self }

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
}

// MARK: - MediaLibraryObserver

extension GenreModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddGenres genres: [VLCMLGenre]) {
        genres.forEach({ append($0) })
        updateView?()
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didModifyGenresWithIds genresIds: [NSNumber]) {
        var genres = [VLCMLGenre]()

        genresIds.forEach() {
            guard let safeGenre = medialibrary.medialib.genre(withIdentifier: $0.int64Value) else {
                return
            }
            genres.append(safeGenre)
        }

        files = swapModels(with: genres)
        updateView?()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteGenresWithIds genresIds: [NSNumber]) {
        files.removeAll {
            genresIds.contains(NSNumber(value: $0.identifier()))
        }
        updateView?()
    }

    func medialibraryDidStartRescan() {
        files.removeAll()
    }
}

// MARK: - Sort
extension GenreModel {
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        files = medialibrary.genres(sortingCriteria: criteria, desc: desc)
        sortModel.currentSort = criteria
        sortModel.desc = desc
        updateView?()
    }
}

// MARK: - Search
extension VLCMLGenre: SearchableMLModel {
    func contains(_ searchString: String) -> Bool {
        return name.lowercased().contains(searchString)
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

    func accessibilityText() -> String? {
        return name + " " + numberOfTracksString()
    }
}

extension VLCMLGenre: MediaCollectionModel {
    func sortModel() -> SortModel? {
        return SortModel([.alpha, .album, .duration, .releaseDate])
    }

    func files(with criteria: VLCMLSortingCriteria,
               desc: Bool = false) -> [VLCMLMedia]? {
        return tracks(with: criteria, desc: desc)
    }

    func title() -> String {
        return name
    }
}
