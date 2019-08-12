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

    func delete(_ items: [VLCMLObject]) {
        preconditionFailure("GenreModel: Genres can not be deleted, they disappear when their last title got deleted")
    }
}

// MARK: - MediaLibraryObserver

extension GenreModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddGenres genres: [VLCMLGenre]) {
        genres.forEach({ append($0) })
        updateView?()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didModifyGenres genres: [VLCMLGenre]) {
        files = swapModels(with: genres)
        updateView?()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteGenresWithIds genreIds: [NSNumber]) {
        files.removeAll {
            genreIds.contains(NSNumber(value: $0.identifier()))
        }
        updateView?()
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
// MARK: - Edit
extension GenreModel: EditableMLModel {
    func editCellType() -> BaseCollectionViewCell.Type {
        return MediaEditCell.self
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

    func thumbnail() -> UIImage? {
        var image: UIImage? = nil
        for track in tracks() ?? [] where track.isThumbnailGenerated() {
            image = UIImage(contentsOfFile: track.thumbnail()?.path ?? "")
            break
        }
        if image == nil {
            let isDarktheme = PresentationTheme.current == PresentationTheme.darkTheme
            image = isDarktheme ? UIImage(named: "song-placeholder-dark") : UIImage(named: "song-placeholder-white")
        }
        return image
    }

    func accessibilityText() -> String? {
        return name + " " + numberOfTracksString()
    }
}

extension VLCMLGenre: MediaCollectionModel {
    func sortModel() -> SortModel? {
        return SortModel([.alpha])
    }

    func files() -> [VLCMLMedia]? {
        return tracks()
    }

    func title() -> String? {
        return name
    }
}
