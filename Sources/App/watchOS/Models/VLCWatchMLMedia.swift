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
import SwiftUI

protocol VLCWatchMLObject: Identifiable {
    var id: VLCMLIdentifier { get }
}

// Wrapper around VLCMLMedia to be used in SwiftUI view
struct VLCWatchMLMedia: VLCWatchMLObject {
    let id: VLCMLIdentifier
    let title: String
    let artist: VLCMLArtist?    // TODO: VLCMLArtist is a class, is this fine to have as field for SwiftUI struct?
    let thumbnail: URL?
    let trackNumber: Int

    init(_ media: VLCMLMedia) {
        self.id = media.identifier()
        self.title = media.title
        self.artist = media.artist
        self.thumbnail = media.thumbnail()
        self.trackNumber = Int(media.trackNumber)
    }

    func isDownloaded(_ mediaSyncIds: [MediaSyncID]) -> Bool {
        guard let watchMediaId = mediaSyncIds.first(where: { $0.iphoneMediaId == id })?.watchMediaId else { return false }
        return mediaSyncIds.downloadedMediaIds.contains(watchMediaId)
    }
}

extension VLCWatchMLMedia: VLCWatchMLCellItem {
    func placeholderName(for color: ColorScheme) -> String {
        return color == .light ? "song-placeholder-white" : "song-placeholder-dark"
    }
}

// Used for NavigationDestination
extension VLCWatchMLMedia: Hashable {}
