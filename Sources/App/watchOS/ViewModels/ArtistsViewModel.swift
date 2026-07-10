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
                                               selector: #selector(handleDidUpdateSnapshotLibraryDBFile),
                                               name: .VLCDidUpdateSnapshotLibraryDBFileNotification,
                                               object: nil)
    }

    func loadData() {
        loadSnapshotArtists()
        isFirstLoad = false
    }

    @objc private func handleDidUpdateSnapshotLibraryDBFile() {
        loadSnapshotArtists()
    }

    func loadSnapshotArtists() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let artistsFiles = VLCAppCoordinator.sharedInstance().snapshotMediaLibraryService.medialib.artists(true) {
                let snapshotArtists = artistsFiles.map { VLCWatchMLArtist($0) }.sorted { $0.id < $1.id}
                DispatchQueue.main.async {
                    self.snapshotArtists = snapshotArtists
                }
            }
        }
    }
}
