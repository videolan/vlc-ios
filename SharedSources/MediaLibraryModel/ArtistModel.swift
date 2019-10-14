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

class ArtistModel: AudioCollectionModel {
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

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didModifyArtistsWithIds artistsIds: [NSNumber]) {
        var artists = [VLCMLArtist]()

        artistsIds.forEach() {
            guard let safeArtist = medialibrary.medialib.artist(withIdentifier: $0.int64Value)
                else {
                    return
            }
            artists.append(safeArtist)
        }

        files = swapModels(with: artists)
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

    func files(with criteria: VLCMLSortingCriteria = .alpha,
               desc: Bool = false) -> [VLCMLMedia]? {
        return tracks(with: criteria, desc: desc)
    }

    func title() -> String {
        return name
    }

    func sortFilesInCollection(with criteria: VLCMLSortingCriteria,
                               desc: Bool) -> [VLCMLMedia]? {
        return nil
    }
}

extension VLCMLArtist {
    func numberOfTracksString() -> String {
        let tracksString = tracks()?.count == 1 ? NSLocalizedString("TRACK", comment: "") : NSLocalizedString("TRACKS", comment: "")
        return String(format: tracksString, tracks()?.count ?? 0)
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
