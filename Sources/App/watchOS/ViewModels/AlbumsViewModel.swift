/*****************************************************************************
 * AlbumsViewModel.swift
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

class AlbumsViewModel: AlbumModel, ObservableObject {
    @Published var snapshotAlbums: [VLCWatchMLAlbum] = []
    @Published var isFirstLoad = true
    @Published var path = NavigationPath()

    required init(medialibrary: MediaLibraryService) {
        super.init(medialibrary: medialibrary)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDidUpdateMLSyncState),
                                               name: .VLCDidUpdateMLSyncStateNotification,
                                               object: nil)
    }

    func loadData(albumSyncIds: [MLSyncID]) {
        loadAlbums(albumSyncIds: albumSyncIds)
        isFirstLoad = false
    }

    @objc func handleDidUpdateMLSyncState(_ notification: Notification) {
        guard let mlSyncState = notification.object as? MLSyncState else { return }
        loadSnapshotAlbums(albumSyncIds: mlSyncState.albumsSyncIds)
    }

    private func loadAlbums(albumSyncIds: [MLSyncID]) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.sort(by: .default, desc: true)
            self.files = self.anyfiles as? [VLCMLAlbum] ?? []
            self.loadSnapshotAlbums(albumSyncIds: albumSyncIds)
        }
    }

    private func loadSnapshotAlbums(albumSyncIds: [MLSyncID]) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let snapshotAlbumFiles = VLCAppCoordinator.sharedInstance().snapshotMediaLibraryService.medialib.albums() {
                let snapshotAlbums = snapshotAlbumFiles.map { VLCWatchMLAlbum($0) }.sorted { $0.id < $1.id}
                DispatchQueue.main.async {
                    self.snapshotAlbums = snapshotAlbums
                    self.loadThumbnails(snapshotAlbums: snapshotAlbums, albumSyncIds: albumSyncIds)
                }
            }
        }
    }

    private func loadThumbnails(snapshotAlbums: [VLCWatchMLAlbum], albumSyncIds: [MLSyncID]) {
        for i in 0..<snapshotAlbums.count {
            guard let albumId = albumSyncIds.first(where: { $0.iphoneMediaId == snapshotAlbums[i].id })?.watchMediaId,
                  let album = self.files.first(where: { $0.identifier() == albumId })
            else { continue }

            self.snapshotAlbums[i].thumbnail = album.artworkMRL()
        }
    }
}
