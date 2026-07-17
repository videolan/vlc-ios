//
//  MLSyncManagerProtocol.swift
//  VLC-watchOS
//
//  Created by Timmy Nguyen on 7/8/26.
//  Copyright © 2026 VideoLAN. All rights reserved.
//

import Foundation

protocol MLSyncManagerProtocol {
    var state: MLSyncState { get set }

    func didReceiveFile(iphoneMediaId: VLCMLIdentifier,
                        filename: String,
                        iphoneAlbumID: VLCMLIdentifier,
                        albumName: String,
                        iphoneArtistID: VLCMLIdentifier,
                        artistName: String)
//    func didAddTracks(_ notification: Notification)
    func saveMLSyncState(_ state: MLSyncState)
    func loadMLSyncState()

    // Gets the corresponding media id from the snapshot media id. Snapshot media id is from iPhone's medialibrary.db.
    func getMediaId(snapshotMediaId: VLCMLIdentifier) -> VLCMLIdentifier?
}

extension MLSyncManagerProtocol {
    func getMediaId(snapshotMediaId: VLCMLIdentifier) -> VLCMLIdentifier? {
        guard let mediaId = state.mediaSyncIds.first(where: { $0.iphoneMediaId == snapshotMediaId })?.watchMediaId
        else {
            print("MLSyncManagerProtocol: Failed to get corresponding media id: \(snapshotMediaId)")
            return nil
        }

        return mediaId
    }
}
