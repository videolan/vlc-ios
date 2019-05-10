/*****************************************************************************
 * LibrarySearchDataSource.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class LibrarySearchDataSource: NSObject, UICollectionViewDataSource {

    var searchData = [VLCMLObject]()
    var model: MediaLibraryBaseModel

    init(model: MediaLibraryBaseModel) {
        self.model = model
        super.init()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier:model.cellType.defaultReuseIdentifier, for: indexPath) as? BaseCollectionViewCell else {
            assertionFailure("you forgot to register the cell or the cell is not a subclass of BaseCollectionViewCell")
            return UICollectionViewCell()
        }
        let mediaObject = searchData[indexPath.row]
        if let media = mediaObject as? VLCMLMedia {
            assert(media.mainFile() != nil, "The mainfile is nil")
            mediaCell.media = media.mainFile() != nil ? media : nil
        } else {
            mediaCell.media = mediaObject
        }
        return mediaCell
    }

    func objectAtIndex(index: Int) -> VLCMLObject? {
         return index < searchData.count ? searchData[index] : nil
    }

    func shouldReloadFor(searchString: String) {
        guard searchString != "" else {
            searchData = model.anyfiles
            return
        }
        searchData.removeAll()
        let lowercaseSearchString = searchString.lowercased()
        model.anyfiles.forEach {
            if let media = $0 as? VLCMLMedia {
                if media.contains(lowercaseSearchString) { searchData.append($0) }
            } else if let album = $0 as? VLCMLAlbum {
                if album.contains(lowercaseSearchString) { searchData.append($0) }
            } else if let genre = $0 as? VLCMLGenre {
                if genre.contains(lowercaseSearchString) { searchData.append($0) }
            } else if let playlist = $0 as? VLCMLPlaylist {
                if playlist.contains(lowercaseSearchString) { searchData.append($0) }
            } else if let artist = $0 as? VLCMLArtist {
                if artist.contains(lowercaseSearchString) { searchData.append($0) }
            } else if let albumtrack = $0 as? VLCMLAlbumTrack {
                if albumtrack.contains(lowercaseSearchString) { searchData.append($0) }
            } else {
                assertionFailure("unhandled type")
            }
        }
    }
}

extension VLCMLObject {
    func contains(_ searchString: String) -> Bool {
        return false
    }
}

extension VLCMLMedia {
    func contains(_ searchString: String) -> Bool {
        return title.lowercased().contains(searchString)
    }
}

extension VLCMLAlbum {
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

extension VLCMLGenre {
    func contains(_ searchString: String) -> Bool {
        return name.lowercased().contains(searchString)
    }
}

extension VLCMLPlaylist {
    func contains(_ searchString: String) -> Bool {
        return name.lowercased().contains(searchString)
    }
}

extension VLCMLArtist {
    func contains(_ searchString: String) -> Bool {
        return name.lowercased().contains(searchString)
    }
}

extension VLCMLAlbumTrack {
    func contains(_ searchString: String) -> Bool {
        var matches = false
        matches = matches || artist?.contains(searchString) ?? false
        matches = matches || genre?.contains(searchString) ?? false
        matches = matches || album?.contains(searchString) ?? false
        return matches
    }
}
