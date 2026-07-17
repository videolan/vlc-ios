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

// This class is repsonsible for managing the watch to iPhone media id mapping.
class VLCMLSyncManager: ObservableMLSyncManager, MediaLibraryObserver {
    @Published var state = MLSyncState()

    private let lock = NSLock()

    init() {
        print("VLCMLSyncManager: init()")
        loadMLSyncState()
        VLCAppCoordinator.sharedInstance().mediaLibraryService.observable.addObserver(self)
    }

    // Called when audio file arrives from iPhone
    func didReceiveFile(iphoneMediaId: VLCMLIdentifier,
                        filename: String,
                        iphoneAlbumID: VLCMLIdentifier,
                        albumName: String,
                        iphoneArtistID: VLCMLIdentifier,
                        artistName: String) {
        lock.lock()
        defer { lock.unlock() }
        guard !state.librarySyncId.isEmpty else {
            preconditionFailure("VLCMLSyncManager: MLSyncState has not been init")
        }
        state.pendingMediaTransfers[filename] = iphoneMediaId
        state.pendingAlbumTransfers[albumName] = iphoneAlbumID
        state.pendingArtistTransfers[artistName] = iphoneArtistID
        saveMLSyncState(state)
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didAddTracks tracks: [VLCMLMedia]) {
        lock.lock()
        defer { lock.unlock() }
        guard !state.librarySyncId.isEmpty else {
            preconditionFailure("VLCMLSyncManager: MLSyncState has not been init")
        }
        for track in tracks {
            guard let iphoneMediaId = state.pendingMediaTransfers[track.fileName()] else {
                preconditionFailure("VLCMLSyncManager: Missing corresponding iPhone media ID for track \(track.fileName()).")
                continue
            }
            let watchMediaId = track.identifier()
            if let syncMediaIDIndex = state.mediaSyncIds.firstIndex(where: { $0.iphoneMediaId == iphoneMediaId }) {
                state.mediaSyncIds[syncMediaIDIndex].watchMediaId = watchMediaId
            } else {
                state.mediaSyncIds.append(MLSyncID(iphoneMediaId: iphoneMediaId, watchMediaId: watchMediaId))
            }
            state.pendingMediaTransfers.removeValue(forKey: track.fileName())
        }

        saveMLSyncState(state)
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didAddAlbums albums: [VLCMLAlbum]) {
        lock.lock()
        defer { lock.unlock() }
        guard !state.librarySyncId.isEmpty else {
            preconditionFailure("VLCMLSyncManager: MLSyncState has not been init")
        }
        for album in albums {
            guard let iphoneMediaId = state.pendingAlbumTransfers[album.title] else {
                preconditionFailure("VLCMLSyncManager: Missing corresponding iPhone media ID for album \(album.title).")
                continue
            }
            let watchAlbumId = album.identifier()
            if let syncMediaIDIndex = state.albumsSyncIds.firstIndex(where: { $0.iphoneMediaId == iphoneMediaId }) {
                state.albumsSyncIds[syncMediaIDIndex].watchMediaId = watchAlbumId
            } else {
                state.albumsSyncIds.append(MLSyncID(iphoneMediaId: iphoneMediaId, watchMediaId: watchAlbumId))
            }
            state.pendingAlbumTransfers.removeValue(forKey: album.title)
        }

        saveMLSyncState(state)
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didAddArtists artists: [VLCMLArtist]) {
        lock.lock()
        defer { lock.unlock() }
        guard !state.librarySyncId.isEmpty else {
            preconditionFailure("VLCMLSyncManager: MLSyncState has not been init")
        }
        for artist in artists {
            guard let iphoneMediaId = state.pendingArtistTransfers[artist.artistName()] else {
                preconditionFailure("VLCMLSyncManager: Missing corresponding iPhone media ID for artist \(artist.artistName()).")
                continue
            }
            let watchArtistId = artist.identifier()
            if let syncMediaIDIndex = state.artistSyncIds.firstIndex(where: { $0.iphoneMediaId == iphoneMediaId }) {
                state.artistSyncIds[syncMediaIDIndex].watchMediaId = watchArtistId
            } else {
                state.artistSyncIds.append(MLSyncID(iphoneMediaId: iphoneMediaId, watchMediaId: watchArtistId))
            }
            state.pendingArtistTransfers.removeValue(forKey: artist.artistName())
        }

        saveMLSyncState(state)
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
                NotificationCenter.default.post(
                    name: .VLCDidUpdateMLSyncStateNotification,
                    object: state
                )
            }
            print("VLCMLSyncManager: Successfully saved ml-sync-state.json: \(state)")
        } catch {
            assertionFailure("VLCMLSyncManager: Failed to save syncMediaIds with error: \(error.localizedDescription)")
        }
    }

    func loadMLSyncState() {
        lock.lock()

        // Read from file (/Library/MediaLibrarySnapshot/ml-sync-state.json)
        guard let snapshotDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            assertionFailure("VLCMLSyncManager: Failed to get Library directory.")
            lock.unlock()
            return
        }

        let mlSyncStateURL = snapshotDir
            .appendingPathComponent("MediaLibrarySnapshot")
            .appendingPathComponent("ml-sync-state.json")

        guard FileManager.default.fileExists(atPath: mlSyncStateURL.path) else {
            lock.unlock()
            return
        }

        let mediaSyncIdsData: Data
        do {
            mediaSyncIdsData = try Data(contentsOf: mlSyncStateURL)
        } catch {
            assertionFailure("VLCMLSyncManager: Failed to get data from \(mlSyncStateURL.path): \(error)")
            lock.unlock()
            return
        }

        do {
            let state = try JSONDecoder().decode(MLSyncState.self, from: mediaSyncIdsData)
            print("VLCMLSyncManager: Successfully got state: \(state)")
            DispatchQueue.main.async {
                self.state = state
                NotificationCenter.default.post(
                    name: .VLCDidUpdateMLSyncStateNotification,
                    object: state
                )
                print("loadMLSyncState VLCDidUpdateMLSyncStateNotification: \(state)")
                self.lock.unlock()
            }
        } catch {
            assertionFailure("VLCMLSyncManager: Failed to decode \(MLSyncState.self): \(error)")
            lock.unlock()
            return
        }
    }
}

// Used for testing on watch simulator, because transferFile(_:) is not supported on simulator, which is used to transfer files from iphone to watch (vice versa)
// - Place audio files in /Documents directory and it will show on watch simulator
class DummyMLSyncManager: ObservableMLSyncManager, MediaLibraryObserver {
    @Published var state = MLSyncState()
    private let lock = NSLock()

    init() {
        print("DummyMLSyncManager: init()")
        loadMLSyncState()
        VLCAppCoordinator.sharedInstance().mediaLibraryService.observable.addObserver(self)
    }

    func didReceiveFile(iphoneMediaId: VLCMLIdentifier,
                        filename: String,
                        iphoneAlbumID: VLCMLIdentifier,
                        albumName: String,
                        iphoneArtistID: VLCMLIdentifier,
                        artistName: String) {
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didAddTracks tracks: [VLCMLMedia]) {
        loadMLSyncState()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didAddAlbums albums: [VLCMLAlbum]) {
        loadMLSyncState()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didAddArtists artists: [VLCMLArtist]) {
        loadMLSyncState()
    }

    func saveMLSyncState(_ state: MLSyncState) {
    }

    func loadMLSyncState() {
        lock.lock()
        let mediaLibraryService = VLCAppCoordinator.sharedInstance().mediaLibraryService
        guard let tracks = mediaLibraryService.medialib.audioFiles(),
              let albums = mediaLibraryService.medialib.albums(),
              let artists = mediaLibraryService.medialib.artists(true)
        else {
            lock.unlock()
            return
        }

        let mediaSyncIds = tracks.map { MLSyncID(iphoneMediaId: $0.identifier(), watchMediaId: $0.identifier()) }
        let albumSyncIds = albums.map { MLSyncID(iphoneMediaId: $0.identifier(), watchMediaId: $0.identifier()) }
        let artistsSyncIds = artists.map { MLSyncID(iphoneMediaId: $0.identifier(), watchMediaId: $0.identifier()) }

        self.createSnapshotDBFile()

        VLCAppCoordinator.sharedInstance().snapshotMediaLibraryService = MediaLibraryService(libraryType: .snapshotLibrary)

        DispatchQueue.main.async {
            let state = MLSyncState(
                librarySyncId: "",
                mediaSyncIds: mediaSyncIds,
                albumsSyncIds: albumSyncIds,
                artistSyncIds: artistsSyncIds
            )
            self.state = state
            NotificationCenter.default.post(
                name: .VLCDidUpdateMLSyncStateNotification,
                object: state
            )
            self.lock.unlock()
        }
    }

    private func createSnapshotDBFile() {
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
