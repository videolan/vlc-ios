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
    @Published var snapshotMedias: [VLCWatchMLMedia] = []
    @Published var isFirstLoad = true

    lazy var playbackService = PlaybackService.sharedInstance()

    required init(medialibrary: MediaLibraryService) {
        super.init(medialibrary: medialibrary)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDidUpdateMLSyncState),
                                               name: .VLCDidUpdateMLSyncStateNotification,
                                               object: nil)
    }

    func play(mediaID: VLCMLIdentifier) {
        guard let media: VLCMLMedia = files.first(where: { $0.identifier() == mediaID })
        else {
            print("TracksViewModel: mediaID \(mediaID) not found")
            return
        }

        playbackService.play(media)
        print("TracksViewModel: Playing track \"\(media.title)\" id: \(mediaID)")
    }

    func loadData(mlSyncIds: [MLSyncID]) {
        loadTracks(mlSyncIds: mlSyncIds)
        isFirstLoad = false
    }

    @objc func handleDidUpdateMLSyncState(_ notification: Notification) {
        guard let mlSyncState = notification.object as? MLSyncState else { return }
        loadSnapshotTracks(mlSyncIds: mlSyncState.mediaSyncIds)
    }

    private func loadTracks(mlSyncIds: [MLSyncID]) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.sort(by: .default, desc: true)
            self.files = self.anyfiles as? [VLCMLMedia] ?? []
            self.loadSnapshotTracks(mlSyncIds: mlSyncIds)
        }
    }

    private func loadSnapshotTracks(mlSyncIds: [MLSyncID]) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let snapshotAudioFiles = VLCAppCoordinator.sharedInstance().snapshotMediaLibraryService.medialib.audioFiles() {
                let snapshotMedias = snapshotAudioFiles.map { VLCWatchMLMedia($0) }.sorted { $0.id < $1.id}
                DispatchQueue.main.async {
                    self.snapshotMedias = snapshotMedias
                    self.loadThumbnails(snapshotMedias: snapshotMedias, mlSyncIds: mlSyncIds)
                }
            }
        }
    }

    private func loadThumbnails(snapshotMedias: [VLCWatchMLMedia], mlSyncIds: [MLSyncID]) {
        for i in 0..<snapshotMedias.count {
            guard let mediaId = mlSyncIds.first(where: { $0.iphoneMediaId == snapshotMedias[i].id })?.watchMediaId,
                  let media = self.files.first(where: { $0.identifier() == mediaId })
            else {
                continue
            }

            self.snapshotMedias[i].thumbnail = media.thumbnail()
        }
    }
}
