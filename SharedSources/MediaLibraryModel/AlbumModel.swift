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

class AlbumModel: MLBaseModel {
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

    func delete(_ items: [VLCMLObject]) {
        preconditionFailure("AlbumModel: Albums can not be deleted, they disappear when their last title got deleted")
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

// MARK: - Edit
extension AlbumModel: EditableMLModel {
    func editCellType() -> BaseCollectionViewCell.Type {
        return MediaEditCell.self
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

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteAlbumsWithIds albumsIds: [NSNumber]) {
        files.removeAll {
            albumsIds.contains(NSNumber(value: $0.identifier()))
        }
        updateView?()
    }
}

extension VLCMLAlbum: MediaCollectionModel {
    func sortModel() -> SortModel? {
        return nil
    }

    func files() -> [VLCMLMedia]? {
        return tracks
    }

    func title() -> String? {
        return title
    }
}

extension VLCMLAlbum {

    func numberOfTracksString() -> String {
        let trackCount = numberOfTracks()
        let tracksString = trackCount > 1 ? NSLocalizedString("TRACKS", comment: "") : NSLocalizedString("TRACK", comment: "")
        return String(format: tracksString, trackCount)
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
            image = isDarktheme ? UIImage(named: "album-placeholder-dark") : UIImage(named: "album-placeholder-white")
        }
        return image
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
