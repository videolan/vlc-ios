/*****************************************************************************
 * VLCWatchMLAlbum.swift
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

// Wrapper around VLCMLAlbum to be used in SwiftUI view
struct VLCWatchMLAlbum: VLCWatchMLObject {
    let id: VLCMLIdentifier
    let title: String
    var thumbnail: URL?
    let albumArtistName: String?

    private let _album: VLCMLAlbum

    init(_ album: VLCMLAlbum) {
        self._album = album
        self.id = album.identifier()
        self.title = album.title
        self.albumArtistName = album.albumArtistName()
    }

    func tracks() -> [VLCMLMedia] {
        return _album.tracks ?? []
    }
}

extension VLCWatchMLAlbum: VLCWatchMLCellItem {
    func placeholderName(for color: ColorScheme) -> String {
        return color == .light ? "album-placeholder-white" : "album-placeholder-dark"
    }
}

// Used for NavigationDestination
extension VLCWatchMLAlbum: Hashable { }
