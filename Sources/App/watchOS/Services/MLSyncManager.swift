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

// Need to separate MLSyncManagerProtocol and ObservableObject because ObservableObject is iOS 13.0+
protocol ObservableMLSyncManager: MLSyncManagerProtocol, ObservableObject { }

// This class is repsonsible for mangaging the watch to iPhone media id mapping.
class VLCMLSyncManager: ObservableMLSyncManager {
    @Published var state: MLSyncState?

    private let lock = NSLock()

    init() {
        print("VLCMLSyncManager: init()")
        loadMLSyncState()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didAddTracks(_:)),
                                               name: .VLCWatchDidAddTracksNotification,
                                               object: nil)
    }

    // Called when audio file arrives from iPhone
    func didReceiveFile(iphoneMediaId: VLCMLIdentifier, filename: String) {
//        lock.lock()
        print("VLCMLSyncManager: didReceiveFile")
        guard var state else {
            preconditionFailure("VLCMLSyncManager: MLSyncState has not been init")
        }
        state.pendingTransfers[filename] = iphoneMediaId
        print("VLCMLSyncManager: saveMLSyncState before")
        saveMLSyncState(state)
        print("VLCMLSyncManager: saveMLSyncState after")
//        lock.unlock()
        print("VLCMLSyncManager: release")
    }

    // Called when user adds file to /Documents/ and VLC calls didAddTracks() callback
    @objc func didAddTracks(_ notification: Notification) {
        guard let tracks: [VLCMLMedia] = notification.userInfo?["tracks"] as? [VLCMLMedia] else { return }
        print("VLCMLSyncManager: didAddTracks before")
//        lock.lock()
        print("VLCMLSyncManager: didAddTracks after")
        guard var state else {
            preconditionFailure("VLCMLSyncManager: MLSyncState has not been init")
        }

        for track in tracks {
            guard let iphoneMediaId = state.pendingTransfers[track.fileName()] else {
                preconditionFailure("VLCMLSyncManager: Missing corresponding iPhone media ID for \(track.fileName()).")
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
//        lock.unlock()
    }

    // Save sync state to /Library/MediaLibrarySnapshot/ml-sync-state.json
    func saveMLSyncState(_ state: MLSyncState) {
        guard let snapshotDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            assertionFailure("VLCMLSyncManager: Failed to get Library directory.")
            return
        }

        let mlSyncStateURL = snapshotDir
            .appendingPathComponent("MediaLibrarySnapshot")
            .appendingPathComponent("ml-sync-state.json")

        do {
            let mlSyncStateData = try JSONEncoder().encode(state)
            try mlSyncStateData.write(to: mlSyncStateURL, options: .atomic)
            DispatchQueue.main.async {
                self.state = state
            }
            print("VLCMLSyncManager: Successfully saved ml-sync-state.json: \(state)")
        } catch {
            assertionFailure("VLCMLSyncManager: Failed to save syncMediaIds with error: \(error.localizedDescription)")
        }
    }

    func loadMLSyncState() {
//        lock.lock()
        // Read from file (/Library/MediaLibrarySnapshot/ml-sync-state.json)
        guard let snapshotDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            assertionFailure("VLCMLSyncManager: Failed to get Library directory.")
            return
        }

        let mlSyncStateURL = snapshotDir
            .appendingPathComponent("MediaLibrarySnapshot")
            .appendingPathComponent("ml-sync-state.json")

        guard FileManager.default.fileExists(atPath: mlSyncStateURL.path) else {
            return
        }

        let mediaSyncIdsData: Data
        do {
            mediaSyncIdsData = try Data(contentsOf: mlSyncStateURL)
        } catch {
            assertionFailure("VLCMLSyncManager: Failed to get data from \(mlSyncStateURL.path): \(error)")
            return
        }

        do {
            let state = try JSONDecoder().decode(MLSyncState.self, from: mediaSyncIdsData)
            print("VLCMLSyncManager: Successfully got state: \(state)")
            DispatchQueue.main.async {
                self.state = state
            }
        } catch {
            assertionFailure("VLCMLSyncManager: Failed to decode \(MLSyncState.self): \(error)")
            return
        }
//        lock.unlock()
    }
}

// Used for testing on watch simulator, because transferFile(_:) is not supported on simulator, which is used to transfer files from iphone to watch (vice versa)
// - Place audio files in /Documents directory and it will show on watch simulator
class DummyMLSyncManager: ObservableMLSyncManager {
    @Published var state: MLSyncState?
    private let lock = NSLock()

    init() {
        print("DummyMLSyncManager: init()")
        loadMLSyncState()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didAddTracks(_:)),
                                               name: .VLCWatchDidAddTracksNotification,
                                               object: nil)
    }

    func didReceiveFile(iphoneMediaId: VLCMLIdentifier, filename: String) {

    }

    @objc func didAddTracks(_ notification: Notification) {
        loadMLSyncState()
    }

    func saveMLSyncState(_ state: MLSyncState) {

    }

    func loadMLSyncState() {
        lock.lock()
        let mediaLibraryService = VLCAppCoordinator.sharedInstance().mediaLibraryService
        guard let tracks = mediaLibraryService.medialib.audioFiles() else { return }
        let mediaSyncIds = tracks.map { MediaSyncID(iphoneMediaId: $0.identifier(), watchMediaId: $0.identifier()) }
        DispatchQueue.main.async {
            self.state = MLSyncState(librarySyncId: "", mediaSyncIds: mediaSyncIds, pendingTransfers: [:])
        }
        updateSnapshotDBFile()
        VLCAppCoordinator.sharedInstance().snapshotMediaLibraryService = MediaLibraryService(libraryType: .snapshotLibrary)
        NotificationCenter.default.post(name: .VLCDidUpdateSnapshotLibraryDBFileNotification, object: nil)
        lock.unlock()
    }

    private func updateSnapshotDBFile() {
        guard let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first else {
            preconditionFailure("DummyMLSyncManager: Fail to get library path.")
        }
        let libraryPath = libraryDirectory

        let databasePath = libraryPath + "/MediaLibrary/" + kVLCMediaLibraryDBFileName
        let snapshotPath = libraryPath + "/MediaLibrarySnapshot/" + kVLCSnapshotMediaLibraryDBFileName

        do {
            if FileManager.default.fileExists(atPath: snapshotPath) {
                try FileManager.default.removeItem(atPath: snapshotPath)
            }

            try FileManager.default.createDirectory(
                atPath: libraryPath + "/MediaLibrarySnapshot/",
                withIntermediateDirectories: true
            )

            try FileManager.default.copyItem(
                atPath: databasePath,
                toPath: snapshotPath
            )
        } catch {
            preconditionFailure("DummyMLSyncManager: Failed to update snapshot file.\n\(error.localizedDescription)")
        }
    }
}
