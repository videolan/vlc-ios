/*****************************************************************************
 * VLCWatchMLMedia.swift
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

// Wrapper around VLCMLMedia to be used in SwiftUI view
struct VLCWatchMLMedia: Identifiable {
    let id: VLCMLIdentifier
    let title: String
    let artist: VLCMLArtist?    // TODO: VLCMLArtist is a class, is this fine to have as field for SwiftUI struct?
    let thumbnail: URL?

    init(_ media: VLCMLMedia) {
        self.id = media.identifier()
        self.title = media.title
        self.artist = media.artist
        self.thumbnail = media.thumbnail()
    }
}
