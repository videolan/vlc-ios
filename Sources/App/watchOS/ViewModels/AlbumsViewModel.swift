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
    typealias MLType = VLCMLAlbum

    override var files: [VLCMLAlbum] {
        didSet {
            DispatchQueue.main.async {
                self.albums = self.model.anyfiles.compactMap { (obj: VLCMLObject) -> VLCWatchMLAlbum? in
                    guard let album = obj as? VLCMLAlbum else { return nil }
                    return VLCWatchMLAlbum(album)
                }
            }
        }
    }

    let model: MediaLibraryBaseModel

    @Published var albums: [VLCWatchMLAlbum] = []
    @Published var isFirstLoad = true
    @Published var path = NavigationPath()

    required init(medialibrary: MediaLibraryService) {
        self.model = AlbumModel(medialibrary: medialibrary)
        super.init(medialibrary: medialibrary)
        medialibrary.observable.addObserver(self)
    }

    func loadAlbums() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.model.sort(by: .default, desc: true)
            self.files = self.model.anyfiles as? [VLCMLAlbum] ?? []
        }
        isFirstLoad = false
    }
}
