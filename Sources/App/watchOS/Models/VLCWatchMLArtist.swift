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
    var thumbnail: URL?
    let albumsCount: Int
    let tracksCount: Int

    private let _artist: VLCMLArtist

    init(_ artist: VLCMLArtist) {
        self._artist = artist
        self.id = artist.identifier()
        self.name = artist.artistName()
        self.albumsCount = Int(artist.albumsCount())
        self.tracksCount = Int(artist.tracksCount())
    }

    func albums() -> [VLCMLAlbum] {
        return _artist.albums() ?? []
    }

    func tracks() -> [VLCMLMedia] {
        return _artist.tracks() ?? []
    }
}

extension VLCWatchMLArtist: VLCWatchMLCellItem {
    func placeholderName(for color: ColorScheme) -> String {
        return color == .light ? "artist-placeholder-white" : "artist-placeholder-dark"
    }
}

// Used for NavigationDestination
extension VLCWatchMLArtist: Hashable { }
