/*****************************************************************************
 * AlbumModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class AlbumModel: AudioCollectionModel {
    typealias MLType = VLCMLAlbum

    var sortModel = SortModel([.alpha, .duration, .releaseDate, .trackNumber])

    var updateView: (() -> Void)?

    var files = [VLCMLAlbum]()

    var cellType: BaseCollectionViewCell.Type { return MediaCollectionViewCell.self }

    var medialibrary: MediaLibraryService

    var indicatorName: String = NSLocalizedString("ALBUMS", comment: "")

    required init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.albums()
    }

    func append(_ item: VLCMLAlbum) {
        files.append(item)
    }
}

// MARK: - Sort
extension AlbumModel {
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        files = medialibrary.albums(sortingCriteria: criteria, desc: desc)
        sortModel.currentSort = criteria
        sortModel.desc = desc
        updateView?()
    }
}

// MARK: - Search
extension VLCMLAlbum: SearchableMLModel {
    func contains(_ searchString: String) -> Bool {
        var matches = false
        matches = matches || title.lowercased().contains(searchString)
        matches = matches || String(releaseYear()).lowercased().contains(searchString)
        matches = matches || shortSummary.lowercased().contains(searchString)
        matches = matches || albumArtist?.contains(searchString) ?? false
        matches = matches || tracks?.filter({ $0.contains(searchString)}).isEmpty == false
        return matches
    }
}

extension VLCMLAlbumTrack: SearchableMLModel {
    func contains(_ searchString: String) -> Bool {
        var matches = false
        matches = matches || artist?.contains(searchString) ?? false
        matches = matches || genre?.contains(searchString) ?? false
        matches = matches || album?.contains(searchString) ?? false
        return matches
    }
}

// MARK: - MediaLibraryObserver

extension AlbumModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddAlbums albums: [VLCMLAlbum]) {
        albums.forEach({ append($0) })
        updateView?()
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didModifyAlbumsWithIds albumsIds: [NSNumber]) {
        var albums = [VLCMLAlbum]()

        albumsIds.forEach() {
            guard let safeAlbum = medialibrary.medialib.album(withIdentifier: $0.int64Value)
                else {
                    return
            }
            albums.append(safeAlbum)
        }

        files = swapModels(with: albums)
        updateView?()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteAlbumsWithIds albumsIds: [NSNumber]) {
        files.removeAll {
            albumsIds.contains(NSNumber(value: $0.identifier()))
        }
        updateView?()
    }

    func medialibraryDidStartRescan() {
        files.removeAll()
    }
}

extension VLCMLAlbum: MediaCollectionModel {
    func sortModel() -> SortModel? {
        return SortModel([.alpha, .album, .duration, .releaseDate])
    }

    func files(with criteria: VLCMLSortingCriteria,
               desc: Bool = false) -> [VLCMLMedia]? {
        return tracks(with: criteria, desc: desc)
    }

    func title() -> String {
        return title
    }
}

extension VLCMLAlbum {

    func numberOfTracksString() -> String {
        let trackCount = numberOfTracks()
        let tracksString = trackCount > 1 ? NSLocalizedString("TRACKS", comment: "") : NSLocalizedString("TRACK", comment: "")
        return String(format: tracksString, trackCount)
    }

    func albumName() -> String {
        return isUnknownAlbum() ? NSLocalizedString("UNKNOWN_ALBUM", comment: "") : title
    }

    func albumArtistName() -> String {
        guard let artist = albumArtist else {
            return NSLocalizedString("UNKNOWN_ARTIST", comment: "")
        }
        return artist.artistName()
    }

    func accessibilityText(editing: Bool) -> String? {
        if editing {
            return albumName() + " " + albumArtistName() + " " + numberOfTracksString()
        }
        return albumName() + " " + albumArtistName()
    }
}

extension VLCMLAlbumTrack {
    func albumArtistName() -> String {
        guard let artist = artist else {
            return NSLocalizedString("UNKNOWN_ARTIST", comment: "")
        }
        return artist.artistName()
    }
}
