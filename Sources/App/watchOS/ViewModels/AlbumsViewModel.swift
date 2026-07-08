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
                                               selector: #selector(handleDidUpdateSnapshotLibraryDBFile),
                                               name: .VLCDidUpdateSnapshotLibraryDBFileNotification,
                                               object: nil)
    }

    func loadAlbums() {
        loadSnapshotAlbums()
        loadAlbumsFromWatch()
        isFirstLoad = false
    }

    @objc private func handleDidUpdateSnapshotLibraryDBFile() {
        loadSnapshotAlbums()
    }

    private func loadSnapshotAlbums() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let albumFiles = VLCAppCoordinator.sharedInstance().snapshotMediaLibraryService.medialib.albums() {
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
