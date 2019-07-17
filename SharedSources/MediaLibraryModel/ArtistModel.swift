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

    var sortModel = SortModel([.alpha])

    var updateView: (() -> Void)?

    var files = [VLCMLArtist]()

    var cellType: BaseCollectionViewCell.Type { return MediaCollectionViewCell.self }

    var medialibrary: MediaLibraryService

    var indicatorName: String = NSLocalizedString("ARTISTS", comment: "")

    required init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.artists()
    }

    func append(_ item: VLCMLArtist) {
        files.append(item)
    }

    func delete(_ items: [VLCMLObject]) {
        preconditionFailure("ArtistModel: Artists can not be deleted, they disappear when their last title got deleted")
    }
}

// MARK: - Sort
extension ArtistModel {
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        files = medialibrary.artists(sortingCriteria: criteria, desc: desc)
        sortModel.currentSort = criteria
        sortModel.desc = desc
        updateView?()
    }
}

// MARK: - Edit
extension ArtistModel: EditableMLModel {
    func editCellType() -> BaseCollectionViewCell.Type {
        return MediaEditCell.self
    }
}

// MARK: - Search
extension VLCMLArtist: SearchableMLModel {
    func contains(_ searchString: String) -> Bool {
        return name.lowercased().contains(searchString)
    }
}

// MARK: - MediaLibraryObserver

extension ArtistModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddArtists artists: [VLCMLArtist]) {
        artists.forEach({ append($0) })
        updateView?()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteArtistsWithIds artistsIds: [NSNumber]) {
        files.removeAll {
            artistsIds.contains(NSNumber(value: $0.identifier()))
        }
        updateView?()
    }

}

extension VLCMLArtist: MediaCollectionModel {

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

extension VLCMLArtist {
    func numberOfTracksString() -> String {
        let tracksString = tracks()?.count == 1 ? NSLocalizedString("TRACK", comment: "") : NSLocalizedString("TRACKS", comment: "")
        return String(format: tracksString, tracks()?.count ?? 0)
    }

    @objc func thumbnail() -> UIImage? {
        var image = UIImage(contentsOfFile: artworkMRL()?.path ?? "")
        if image == nil {
            for track in files() ?? [] where track.isThumbnailGenerated() {
                image = UIImage(contentsOfFile: track.thumbnail()?.path ?? "")
                break
            }
        }
        if image == nil {
            let isDarktheme = PresentationTheme.current == PresentationTheme.darkTheme
            image = isDarktheme ? UIImage(named: "artist-placeholder-dark") : UIImage(named: "artist-placeholder-white")
        }
        return image
    }

    func artistName() -> String {
        if identifier() == UnknownArtistID {
            return NSLocalizedString("UNKNOWN_ARTIST", comment: "")
        } else if identifier() == VariousArtistID {
            return NSLocalizedString("VARIOUS_ARTIST", comment: "")
        } else {
            return name
        }
    }

    func accessibilityText() -> String? {
        return artistName() + " " + numberOfTracksString()
    }
}
