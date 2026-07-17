//
//  AlbumDetailViewModel.swift
//  VLC-watchOS
//
//  Created by Timmy Nguyen on 7/10/26.
//  Copyright © 2026 VideoLAN. All rights reserved.
//

import Foundation

class AlbumDetailViewModel: ObservableObject {
    @Published var snapshotMedias: [VLCWatchMLMedia] = []
    @Published var isFirstLoad = true

    let snapshotAlbum: VLCWatchMLAlbum
    var tracks: [VLCMLMedia] = []

    lazy var playbackService = PlaybackService.sharedInstance()

    init(snapshotAlbum: VLCWatchMLAlbum) {
        self.snapshotAlbum = snapshotAlbum
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDidUpdateMLSyncState),
                                               name: .VLCDidUpdateMLSyncStateNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .VLCDidUpdateMLSyncStateNotification, object: nil)
    }

    func loadData(mlSyncState: MLSyncState) {
        loadTracks(mlSyncState: mlSyncState)
        loadSnapshotTracks(mlSyncState: mlSyncState)
        isFirstLoad = false
    }

    @objc func handleDidUpdateMLSyncState(_ notification: Notification) {
        guard let mlSyncState = notification.object as? MLSyncState else { return }
        loadSnapshotTracks(mlSyncState: mlSyncState)
    }

    func loadTracks(mlSyncState: MLSyncState) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let albumId = mlSyncState.albumsSyncIds.first(where: { $0.iphoneMediaId == self.snapshotAlbum.id })?.watchMediaId,
                  let album = VLCAppCoordinator.sharedInstance().mediaLibraryService.medialib.album(withIdentifier: albumId) else {
                return
            }
            self.tracks = album.tracks(with: .default, desc: true) ?? []
        }
    }

    func loadSnapshotTracks(mlSyncState: MLSyncState) {
        DispatchQueue.global(qos: .userInitiated).async {
            let snapshotMedias = self.snapshotAlbum.tracks().map { VLCWatchMLMedia($0) }
            DispatchQueue.main.async {
                self.snapshotMedias = snapshotMedias
                self.loadThumbnails(snapshotMedias: snapshotMedias, mediaSyncIds: mlSyncState.mediaSyncIds)
            }
        }
    }

    func play(mediaID: VLCMLIdentifier) {
        guard let media: VLCMLMedia = self.tracks.first(where: { $0.identifier() == mediaID })
        else {
            print("Media with id not found: \(mediaID)")
            return
        }

        playbackService.play(media)
        print("Playing media: \(media.title)")
    }

    private func loadThumbnails(snapshotMedias: [VLCWatchMLMedia], mediaSyncIds: [MLSyncID]) {
        for i in 0..<snapshotMedias.count {
            guard let mediaId = mediaSyncIds.first(where: { $0.iphoneMediaId == snapshotMedias[i].id })?.watchMediaId else { continue }

            guard let media = self.tracks.first(where: { $0.identifier() == mediaId }) else { continue }
            self.snapshotMedias[i].thumbnail = media.thumbnail()
        }
    }
}
