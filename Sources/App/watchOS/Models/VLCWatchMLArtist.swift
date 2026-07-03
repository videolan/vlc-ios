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
import SwiftUI

// Wrapper around VLCMLArtist to be used in SwiftUI view
struct VLCWatchMLArtist: VLCWatchMLObject {
    let id: VLCMLIdentifier
    let name: String
    let albumsCount: Int
    let tracksCount: Int
    let thumbnail: URL?
    let albums: [VLCWatchMLAlbum]
    let tracks: [VLCWatchMLMedia]


    init(_ artist: VLCMLArtist) {
        self.id = artist.identifier()
        self.name = artist.artistName()
        self.albumsCount = Int(artist.albumsCount())
        self.tracksCount = Int(artist.tracksCount())
        self.thumbnail = artist.artworkMRL()
        self.albums = (artist.albums() ?? []).map { VLCWatchMLAlbum($0) }
        self.tracks = (artist.tracks() ?? []).map { VLCWatchMLMedia($0) }
    }
}

extension VLCWatchMLArtist: VLCWatchMLCellItem {
    func placeholderName(for color: ColorScheme) -> String {
        return color == .light ? "artist-placeholder-white" : "artist-placeholder-dark"
    }
}

// Used for NavigationDestination
extension VLCWatchMLArtist: Hashable { }
