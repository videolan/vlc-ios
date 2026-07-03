/*****************************************************************************
 * TracksViewModel.swift
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

class TracksViewModel: TrackModel, ObservableObject {
    @Published var snapshotMedias: [VLCWatchMLMedia] = [] // display metadata from iphone's media library
    @Published var downloadedMediaIDs: Set<VLCMLIdentifier> = [] // track which audio files are downloaded locally on watch
    @Published var mediaSyncIds: [MediaSyncID] = [] // media id mapping between iphone and watch
    @Published var isFirstLoad = true

    lazy var playbackService = PlaybackService.sharedInstance()
    var snapshotMediaLibrary: MediaLibraryService? // medialibrary-snapshot.db, used for displaying ml metadata from iphone

    required init(medialibrary: MediaLibraryService) {
        super.init(medialibrary: medialibrary)
    }

    convenience init(medialibrary: MediaLibraryService, snapshotMediaLibrary: MediaLibraryService) {
        self.init(medialibrary: medialibrary)
        self.snapshotMediaLibrary = snapshotMediaLibrary

        loadMediaSyncIDs()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMediaSyncIdsUpdated(_:)),
                                               name: .VLCMediaSyncIDsUpdatedNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDidReceiveMediaLibraryDBFile),
                                               name: .VLCDidReceiveMediaLibraryDBFileNotification,
                                               object: nil)

        observable.addObserver(self)
    }

    func play(media: VLCWatchMLMedia) {
        let iphoneMediaId = media.id
        guard let watchMediaId = mediaSyncIds.first(where: { $0.iphoneMediaId == iphoneMediaId })?.watchMediaId,
              let mlMedia = files.first(where: { $0.identifier() == watchMediaId })
        else {
            print("\(media.title) (id: \(media.id)) not found ")
            return
        }

        playbackService.play(mlMedia)
        print("Playing media: \(media.title)")
    }

    func loadTracks() {
        loadSnapshotMediaLibrary()
        loadDownloadedTracksOnWatch()
        isFirstLoad = false
    }

    override func medialibrary(_ medialibrary: MediaLibraryService, didAddTracks tracks: [VLCMLMedia]) {
        print("TracksViewModel: didAddTracks \(tracks)")
        super.medialibrary(medialibrary, didAddTracks: tracks)
        MLSyncManager.shared.didAddTracks(tracks)
    }

    @objc private func handleMediaSyncIdsUpdated(_ notification: Notification) {
        guard let syncMediaIDs = notification.userInfo?["mediaSyncIDs"] as? [MediaSyncID] else { return }

        DispatchQueue.main.async {
            self.mediaSyncIds = syncMediaIDs
            print("TracksViewModel: handleMediaSyncIdsUpdated \(syncMediaIDs)")
        }
    }

    @objc private func handleDidReceiveMediaLibraryDBFile() {
        print("handleDidReceiveMediaLibraryDBFile()")
        snapshotMediaLibrary = MediaLibraryService(databaseName: kVLCSnapshotMediaLibraryDBFileName)
        loadSnapshotMediaLibrary()
    }

    // Fetches the audio files from medialibrary.db
    private func loadDownloadedTracksOnWatch() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.sort(by: .default, desc: true)
            self.files = self.anyfiles as? [VLCMLMedia] ?? []
            DispatchQueue.main.async {
                self.downloadedMediaIDs = Set(self.files.map { $0.identifier() })
            }
        }
    }

    // Fetches the audio files metadata from medialibrary-snapshot.db
    private func loadSnapshotMediaLibrary() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let audioFiles = self.snapshotMediaLibrary?.medialib.audioFiles() {
                DispatchQueue.main.async {
                    self.snapshotMedias = audioFiles.map { VLCWatchMLMedia($0) }.sorted { $0.id < $1.id}
                }
            }
        }
    }

    private func loadMediaSyncIDs() {
        guard let state = MLSyncManager.shared.getMLSyncState() else { return }
        self.mediaSyncIds = state.mediaSyncIds
        print("TracksViewModel: mediaSyncIds \(mediaSyncIds)")
    }

    func isDownloaded(iphoneMediaId: VLCMLIdentifier) -> Bool {
        guard let watchMediaId = mediaSyncIds.first(where: { $0.iphoneMediaId == iphoneMediaId })?.watchMediaId else { return false }
        return downloadedMediaIDs.contains(watchMediaId)
    }
}

extension TracksViewModel: MediaLibraryBaseModelObserver {
    func mediaLibraryBaseModelReloadView() {
        DispatchQueue.main.async {
            self.downloadedMediaIDs = Set(self.files.map { $0.identifier() })
            print("TracksViewModel: downloadedMediaIDs \(self.downloadedMediaIDs)")
        }
    }
}
