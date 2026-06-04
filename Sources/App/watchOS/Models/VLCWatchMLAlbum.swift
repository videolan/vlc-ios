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

// Wrapper around VLCMLAlbum to be used in SwiftUI view
struct VLCWatchMLAlbum {
    let id: VLCMLIdentifier
    let title: String
    let artists: [VLCMLArtist]
    let thumbnail: URL?
    let albumArtistName: String?
    let tracks: [VLCMLMedia]

    init(_ album: VLCMLAlbum) {
        self.id = album.identifier()
        self.title = album.title
        self.artists = album.artists() ?? []
        self.thumbnail = album.artworkMRL()
        self.albumArtistName = album.albumArtistName()
        self.tracks = album.tracks ?? []
    }
}

extension VLCWatchMLAlbum: VLCWatchMLCellItem {
    var titleText: String {
        return title
    }

    var subtitleText: String {
        return albumArtistName ?? ""
    }
}

extension VLCWatchMLAlbum: Hashable { }
