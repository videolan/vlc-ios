/*****************************************************************************
 * MLSyncManager.swift
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

final class MLSyncManager {
    static let shared = MLSyncManager()
    private let lock = NSLock()

    private init() {}

    // Called when audio file arrives from iPhone
    func didReceiveFile(iphoneMediaId: VLCMLIdentifier, filename: String) {
        lock.lock()
        guard var state = getMLSyncState() else {
            preconditionFailure("MLSyncManager: MLSyncState has not been init")
        }
        state.pendingTransfers[filename] = iphoneMediaId
        saveMLSyncState(state)
        lock.unlock()
    }

    // Called when user adds file to /Documents/ and VLC calls didAddTracks() callback
    func didAddTracks(_ tracks: [VLCMLMedia]) {
        print("didAddTracks: \(tracks)")
        lock.lock()
        guard var state = getMLSyncState() else {
            preconditionFailure("MLSyncManager: MLSyncState has not been init")
        }

        for track in tracks {
            guard let iphoneMediaId = state.pendingTransfers[track.fileName()] else {
                preconditionFailure("MLSyncManager: Missing corresponding iPhone media ID for \(track.fileName()).")
                continue
            }
            let watchMediaId = track.identifier()
            if let syncMediaIDIndex = state.mediaSyncIds.firstIndex(where: { $0.iphoneMediaId == iphoneMediaId }) {
                state.mediaSyncIds[syncMediaIDIndex].watchMediaId = watchMediaId
            } else {
                state.mediaSyncIds.append(MediaSyncID(iphoneMediaId: iphoneMediaId, watchMediaId: watchMediaId))
            }
            state.pendingTransfers.removeValue(forKey: track.fileName())
        }

        saveMLSyncState(state)
        lock.unlock()
    }

    func saveMLSyncState(_ state: MLSyncState) {
        guard let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            assertionFailure("MLSyncManager: Failed to get Library directory.")
            return
        }

        let mlSyncStateURL = libraryDir
            .appendingPathComponent("MediaLibrary")
            .appendingPathComponent("ml-sync-state.json")

        do {
            let mlSyncStateData = try JSONEncoder().encode(state)
            try mlSyncStateData.write(to: mlSyncStateURL, options: .atomic)
            NotificationCenter.default.post(name: .VLCMLSyncStateUpdatedNotification, object: nil,
                                            userInfo: ["mlSyncState": state])
            print("MLSyncManager: Successfully saved ml-sync-state.json: \(state)")
        } catch {
            assertionFailure("MLSyncManager: Failed to save syncMediaIds with error: \(error.localizedDescription)")
        }

    }

    func getMLSyncState() -> MLSyncState? {
        // Read from file (/Library/MediaLibrary/ml-sync-state.json)
        guard let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            assertionFailure("MLSyncManager: Failed to get Library directory.")
            return nil
        }

        let mlSyncStateURL = libraryDir
            .appendingPathComponent("MediaLibrary")
            .appendingPathComponent("ml-sync-state.json")

        guard FileManager.default.fileExists(atPath: mlSyncStateURL.path) else {
            return nil
        }

        let mediaSyncIdsData: Data
        do {
            mediaSyncIdsData = try Data(contentsOf: mlSyncStateURL)
        } catch {
            assertionFailure("MLSyncManager: Failed to get data from \(mlSyncStateURL.path): \(error)")
            return nil
        }

        do {
            let state = try JSONDecoder().decode(MLSyncState.self, from: mediaSyncIdsData)
            print("MLSyncManager: Successfully got state: \(state)")
            return state
        } catch {
            assertionFailure("MLSyncManager: Failed to decode \(MLSyncState.self): \(error)")
            return nil
        }
    }
}
