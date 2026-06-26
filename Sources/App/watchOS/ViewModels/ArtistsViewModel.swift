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

class ArtistsViewModel: ArtistModel, ObservableObject {

    @Published var snapshotArtists: [VLCWatchMLArtist] = []
    @Published var isFirstLoad = true

    var snapshotMediaLibrary: MediaLibraryService?

    required init(medialibrary: MediaLibraryService) {
        super.init(medialibrary: medialibrary)
    }

    convenience init(medialibrary: MediaLibraryService, snapshotMediaLibrary: MediaLibraryService) {
        self.init(medialibrary: medialibrary)
        self.snapshotMediaLibrary = snapshotMediaLibrary
    }

    func loadArtists() {
        loadSnapshotArtists()
        loadArtistsFromWatch()
        isFirstLoad = false
    }

    private func loadSnapshotArtists() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let artistsFiles = self.snapshotMediaLibrary?.medialib.artists(true) {
                DispatchQueue.main.async {
                    self.snapshotArtists = artistsFiles.map { VLCWatchMLArtist($0) }.sorted { $0.id < $1.id}
                }
            }
        }
    }

    private func loadArtistsFromWatch() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.sort(by: .default, desc: true)
            self.files = self.anyfiles as? [VLCMLArtist] ?? []
        }
    }
}
