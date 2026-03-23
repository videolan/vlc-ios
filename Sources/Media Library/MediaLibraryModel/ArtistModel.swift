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

    var sortModel = SortModel([.alpha, .lastPlaybackDate, .nbAlbum, .playCount])

    var observable = VLCObservable<MediaLibraryBaseModelObserver>()

    var files = [VLCMLArtist]()
    var fileArrayLock = NSRecursiveLock()

    var cellType: BaseCollectionViewCell.Type {
        return UserDefaults.standard.bool(forKey: "\(kVLCAudioLibraryGridLayout)\(name)") ? MediaGridCollectionCell.self : MediaCollectionViewCell.self
    }

    var medialibrary: MediaLibraryService

    var name: String = "ARTISTS"

    var indicatorName: String = NSLocalizedString("ARTISTS", comment: "")

    var hideFeatArtists: Bool {
        return UserDefaults.standard.bool(forKey: "\(kVLCAudioLibraryHideFeatArtists)")
    }

    var currentPage = 0
    var hasMorePages = true
    var isLoading = false
    var firstTime = true

    required init(medialibrary: MediaLibraryService) {
        defer {
            fileArrayLock.unlock()
        }
        self.medialibrary = medialibrary
        medialibrary.observable.addObserver(self)
        fileArrayLock.lock()
    }

    func append(_ item: VLCMLArtist) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files.append(item)
    }

    private func addNewArtists(_ artists: [VLCMLArtist]) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
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
        for (index, artist) in files.enumerated().reversed() {
            if artist.identifier() == UnknownArtistID || artist.identifier() == VariousArtistID {
                if artist.tracksCount() == 0 {
                    files.remove(at: index)
                }
            }
        }
    }

    func fetchPage(offset: Int, limit: Int) -> [VLCMLArtist] {
        return hideFeatArtists
            ? medialibrary.artists(sortingCriteria: sortModel.currentSort, desc: sortModel.desc,
                                   listAll: true, items: UInt32(limit), offset: UInt32(offset))
            : medialibrary.artists(sortingCriteria: sortModel.currentSort, desc: sortModel.desc,
                                   listAll: false, items: UInt32(limit), offset: UInt32(offset))
    }

    func getMedia() {
        currentPage += 1
        let offset = (currentPage - 1) * kVLCDefaultPageSize
        let mediaAtOffset = hideFeatArtists ? medialibrary.artists(sortingCriteria: sortModel.currentSort, desc: sortModel.desc, listAll: true, items: UInt32(kVLCDefaultPageSize), offset: UInt32(offset)) : medialibrary.artists(sortingCriteria: sortModel.currentSort, desc: sortModel.desc, listAll: false, items: UInt32(kVLCDefaultPageSize), offset: UInt32(offset))
            for artist in mediaAtOffset {
                files.append(artist)
            }
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }
}

// MARK: - Sort
extension ArtistModel {
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        defer {
            fileArrayLock.unlock()
        }
        sortModel.currentSort = criteria
        sortModel.desc = desc
        if firstTime {
            getMedia()
            firstTime = false
        } else {
            files.removeAll()
            currentPage = 0
            getMedia()
        }
    }
}

// MARK: - Search
extension VLCMLArtist: SearchableMLModel {
    func contains(_ searchString: String) -> Bool {
        return search(searchString, in: name)
    }
}

// MARK: - MediaLibraryObserver

extension ArtistModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddArtists artists: [VLCMLArtist]) {
        artists.forEach({ append($0) })
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didModifyArtistsWithIds artistsIds: [NSNumber]) {
        defer {
            fileArrayLock.unlock()
        }
        let uniqueArtistsIds = Array(Set(artistsIds))
        var artists = [VLCMLArtist]()

        uniqueArtistsIds.forEach() {
            guard let safeArtist = medialibrary.medialib.artist(withIdentifier: $0.int64Value)
                else {
                    return
            }
            artists.append(safeArtist)
        }

        fileArrayLock.lock()
        files = swapModels(with: artists)
        addNewArtists(artists)
        filterGeneratedArtists()
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteArtistsWithIds artistsIds: [NSNumber]) {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files.removeAll {
            artistsIds.contains(NSNumber(value: $0.identifier()))
        }
        observable.notifyObservers {
            $0.mediaLibraryBaseModelReloadView()
        }
    }

    func medialibraryDidStartRescan() {
        defer {
            fileArrayLock.unlock()
        }
        fileArrayLock.lock()
        files.removeAll()
    }
}

extension VLCMLArtist: MediaCollectionModel {
    func sortModel() -> SortModel? {
        if albumsCount() == 1 {
            return SortModel([.alpha, .trackID, .duration, .releaseDate])
        }

        return SortModel([.alpha, .album, .duration, .releaseDate])
    }

    func files(with criteria: VLCMLSortingCriteria,
               desc: Bool = false) -> [VLCMLMedia]? {
        return tracks(with: criteria, desc: desc)
    }

    func title() -> String {
        return artistName()
    }
}

extension VLCMLArtist {
    @objc func numberOfTracksString() -> String {
        let tracksCount = tracksCount()
        let tracksString = tracksCount == 1 ? NSLocalizedString("TRACK", comment: "") : NSLocalizedString("TRACKS", comment: "")
        return String(format: tracksString, tracksCount)
    }

    @objc func numberOfAlbumsString() -> String {
        let albumCount = albumsCount()
        let albumsString = albumCount == 1 ? NSLocalizedString("NB_ALBUM_FORMAT", comment: "") : NSLocalizedString("NB_ALBUMS_FORMAT", comment: "")
        return String(format: albumsString, albumCount)
    }

    @objc func artistName() -> String {
        if identifier() == UnknownArtistID {
            return NSLocalizedString("UNKNOWN_ARTIST", comment: "")
        } else if identifier() == VariousArtistID {
            return NSLocalizedString("VARIOUS_ARTIST", comment: "")
        } else {
            return name
        }
    }

    @objc func accessibilityText() -> String? {
        return artistName() + " " + numberOfTracksString()
    }
}
