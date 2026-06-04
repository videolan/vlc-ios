/*****************************************************************************
 * VLCWatchMLArtist.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Timmy Nguyen <timmypass21 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

// Wrapper around VLCMLArtist to be used in SwiftUI view
struct VLCWatchMLArtist {
    let id: VLCMLIdentifier
    let name: String
    let albumsCount: Int
    let tracksCount: Int
    let thumbnail: URL?

    init(_ artist: VLCMLArtist) {
        self.id = artist.identifier()
        self.name = artist.artistName()
        self.albumsCount = Int(artist.albumsCount())
        self.tracksCount = Int(artist.tracksCount())
        self.thumbnail = artist.artworkMRL()
    }
}

extension VLCWatchMLArtist: VLCWatchMLCellItem {
    var titleText: String {
        return name
    }

    var subtitleText: String {
        return albumsCount == 0 ? numberOfTracksString() : String(format: "%@ · %@", numberOfAlbumsString(), numberOfTracksString())
    }

    private func numberOfTracksString() -> String {
        let tracksString = tracksCount == 1 ? NSLocalizedString("TRACK", comment: "") : NSLocalizedString("TRACKS", comment: "")
        return String(format: tracksString, tracksCount)
    }

    private func numberOfAlbumsString() -> String {
        let albumsString = albumsCount == 1 ? NSLocalizedString("NB_ALBUM_FORMAT", comment: "") : NSLocalizedString("NB_ALBUMS_FORMAT", comment: "")
        return String(format: albumsString, albumsCount)
    }
}
