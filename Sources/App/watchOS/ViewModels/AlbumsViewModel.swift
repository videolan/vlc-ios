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

    override var files: [VLCMLAlbum] {
        didSet {
            DispatchQueue.main.async {
                self.albums = self.anyfiles.compactMap { (obj: VLCMLObject) -> VLCWatchMLAlbum? in
                    guard let album = obj as? VLCMLAlbum else { return nil }
                    return VLCWatchMLAlbum(album)
                }
            }
        }
    }

    @Published var albums: [VLCWatchMLAlbum] = []
    @Published var isFirstLoad = true
    @Published var path = NavigationPath()

    required init(medialibrary: MediaLibraryService) {
        super.init(medialibrary: medialibrary)
        medialibrary.observable.addObserver(self)
    }

    func loadAlbums() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.sort(by: .default, desc: true)
            self.files = self.anyfiles as? [VLCMLAlbum] ?? []
        }
        isFirstLoad = false
    }
}
