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

class AlbumsViewModel: ObservableObject {
    let model: MediaLibraryBaseModel
    let mediaLibraryService: MediaLibraryService
    let playbackService: PlaybackService

    @Published var albums: [VLCWatchMLAlbum] = []
    var _albumsMap: [VLCMLIdentifier: VLCMLAlbum] = [:]

    @Published var path = NavigationPath()

    init(mediaLibraryService: MediaLibraryService, playbackService: PlaybackService) {
        self.mediaLibraryService = mediaLibraryService
        self.playbackService = playbackService
        model = AlbumModel(medialibrary: mediaLibraryService)
        
        model.sort(by: .default, desc: true)
        albums = model.anyfiles.compactMap { (obj: VLCMLObject) -> VLCWatchMLAlbum? in
            guard let album = obj as? VLCMLAlbum else { return nil }
            _albumsMap[album.identifier()] = album
            return VLCWatchMLAlbum(album)
        }

        if let albums = model.anyfiles as? [VLCMLAlbum] {
            print("Albums (\(albums.count)): \(albums)")
        }
    }
}
