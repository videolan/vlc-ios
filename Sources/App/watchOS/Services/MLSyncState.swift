/*****************************************************************************
 * MLSyncState.swift
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

/**
 Used to link medialibrary id mappings between iPhone and watch.
 Store at /Library/MediaLibrarySnapshot/ml-sync-state.json

 This mapping becomes invalid if..
 - User tries to send file from a different iPhone
 - iOS app was reinstalled
 - On iPhone, user force rescans media library
 **/
struct MLSyncState: Codable {

    var librarySyncId: String = ""

    var mediaSyncIds: [MLSyncID] = []
    var albumsSyncIds: [MLSyncID] = []
    var artistSyncIds: [MLSyncID] = []

    // Store filename -> iphoneMediaId mapping temporarily to later link with watchos media when it gets created
    var pendingMediaTransfers: [String: VLCMLIdentifier] = [:]
    var pendingAlbumTransfers: [String: VLCMLIdentifier] = [:]
    var pendingArtistTransfers: [String: VLCMLIdentifier] = [:]
}

struct MLSyncID: Codable {
    let iphoneMediaId: VLCMLIdentifier
    var watchMediaId: VLCMLIdentifier
}

extension Collection where Element == MLSyncID {
    var downloadedMediaIds: Set<VLCMLIdentifier> {
        return Set(self.map { $0.watchMediaId })
    }
}
