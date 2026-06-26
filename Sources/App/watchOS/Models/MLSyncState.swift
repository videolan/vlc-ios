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

// Save as ml-sync-state.json
struct MLSyncState: Codable {
    // Used to link an iPhone to a watch
    // - This should only change if user tries to send file from a different iPhone or iOS app was reinstalled
    let librarySyncId: String
    var mediaSyncIds: [MediaSyncID]
    // Store filename -> iphoneMediaId mapping temporarily to later link with watchos media when it gets created
    var pendingTransfers: [String: VLCMLIdentifier]
}

struct MediaSyncID: Codable {
    let iphoneMediaId: VLCMLIdentifier
    var watchMediaId: VLCMLIdentifier
}
