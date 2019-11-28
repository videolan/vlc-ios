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

    private func addNewArtists(_ artists: [VLCMLArtist]) {
        let newArtists = artists.filter() {
            for artist in files {
                if artist.identifier() == $0.identifier() {
                    return false
                }
            }
            return true
        }

        for artist in newArtists {
            if !files.contains(where: { $0.identifier() == artist.identifier() }) {
                files.append(artist)
            }
        }
    }

    private func filterGeneratedArtists() {
        for (index, artist) in files.enumerated() {
            if artist.identifier() == UnknownArtistID || artist.identifier() == VariousArtistID {
                if artist.tracksCount() == 0 {
                    files.remove(at: index)
                }
            }
        }
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

        let uniqueArtistsIds = Array(Set(artistsIds))
        var artists = [VLCMLArtist]()

        uniqueArtistsIds.forEach() {
            guard let safeArtist = medialibrary.medialib.artist(withIdentifier: $0.int64Value)
                else {
                    return
            }
            artists.append(safeArtist)
        }

        files = swapModels(with: artists)
        addNewArtists(artists)
        filterGeneratedArtists()
        updateView?()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteArtistsWithIds artistsIds: [NSNumber]) {
        files.removeAll {
            artistsIds.contains(NSNumber(value: $0.identifier()))
        }
        updateView?()
    }

    func medialibraryDidStartRescan() {
        files.removeAll()
    }
}

extension VLCMLArtist: MediaCollectionModel {

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
