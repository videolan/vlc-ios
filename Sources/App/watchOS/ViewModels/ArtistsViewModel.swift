/*****************************************************************************
 * ArtistsViewModel.swift
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

class ArtistsViewModel: ArtistModel, ObservableObject {
    @Published var snapshotArtists: [VLCWatchMLArtist] = []
    @Published var isFirstLoad = true
    @Published var path = NavigationPath()

    required init(medialibrary: MediaLibraryService) {
        super.init(medialibrary: medialibrary)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDidUpdateMLSyncState),
                                               name: .VLCDidUpdateMLSyncStateNotification,
                                               object: nil)
    }

    func loadData(artistSyncIds: [MLSyncID]) {
        loadArtists(artistSyncIds: artistSyncIds)
        isFirstLoad = false
    }

    @objc func handleDidUpdateMLSyncState(_ notification: Notification) {
        guard let mlSyncState = notification.object as? MLSyncState else { return }
        loadData(artistSyncIds: mlSyncState.artistSyncIds)
    }

    private func loadArtists(artistSyncIds: [MLSyncID]) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.sort(by: .default, desc: true)
            self.files = self.anyfiles as? [VLCMLArtist] ?? []
            self.loadSnapshotArtists(artistSyncIds: artistSyncIds)
        }
    }

    private func loadSnapshotArtists(artistSyncIds: [MLSyncID]) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let snapshotArtistFiles = VLCAppCoordinator.sharedInstance().snapshotMediaLibraryService.medialib.artists(true) {
                let snapshotArtists = snapshotArtistFiles.map { VLCWatchMLArtist($0) }.sorted { $0.id < $1.id}
                DispatchQueue.main.async {
                    self.snapshotArtists = snapshotArtists
                    self.loadThumbnails(snapshotArtists: snapshotArtists, artistSyncIds: artistSyncIds)
                }
            }
        }
    }

    private func loadThumbnails(snapshotArtists: [VLCWatchMLArtist], artistSyncIds: [MLSyncID]) {
        for i in 0..<snapshotArtists.count {
            guard let artistId = artistSyncIds.first(where: { $0.iphoneMediaId == snapshotArtists[i].id })?.watchMediaId else { continue }

            guard let artist = self.files.first(where: { $0.identifier() == artistId }) else { continue }
            self.snapshotArtists[i].thumbnail = artist.artworkMRL()
        }
    }

}
