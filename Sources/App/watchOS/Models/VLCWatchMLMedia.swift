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
    var thumbnail: URL?
    let trackNumber: Int

    let artist: VLCMLArtist?

    init(_ media: VLCMLMedia) {
        self.id = media.identifier()
        self.title = media.title
        self.trackNumber = Int(media.trackNumber)
        self.artist = media.artist
    }

    func isDownloaded(_ mediaSyncIds: [MLSyncID]) -> Bool {
        guard let mediaId = mediaSyncIds.first(where: { $0.iphoneMediaId == id })?.watchMediaId else { return false }
        return mediaSyncIds.downloadedMediaIds.contains(mediaId)
    }
}

extension VLCWatchMLMedia: VLCWatchMLCellItem {
    func placeholderName(for color: ColorScheme) -> String {
        return color == .light ? "song-placeholder-white" : "song-placeholder-dark"
    }
}

// Used for NavigationDestination
extension VLCWatchMLMedia: Hashable {}
