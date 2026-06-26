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

    var snapshotMediaLibrary: MediaLibraryService?

    required init(medialibrary: MediaLibraryService) {
        super.init(medialibrary: medialibrary)
    }

    convenience init(medialibrary: MediaLibraryService, snapshotMediaLibrary: MediaLibraryService) {
        self.init(medialibrary: medialibrary)
        self.snapshotMediaLibrary = snapshotMediaLibrary
    }

    func loadAlbums() {
        loadSnapshotAlbums()
        loadAlbumsFromWatch()
        isFirstLoad = false
    }

    private func loadSnapshotAlbums() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let albumFiles = self.snapshotMediaLibrary?.medialib.albums() {
                DispatchQueue.main.async {
                    self.snapshotAlbums = albumFiles.map { VLCWatchMLAlbum($0) }.sorted { $0.id < $1.id}
                }
            }
        }
    }

    private func loadAlbumsFromWatch() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.sort(by: .default, desc: true)
            self.files = self.anyfiles as? [VLCMLAlbum] ?? []
        }
    }
}
