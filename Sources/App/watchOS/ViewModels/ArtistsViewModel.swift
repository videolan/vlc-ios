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

class ArtistsViewModel: ObservableObject {
    let model: MediaLibraryBaseModel
    let mediaLibraryService: MediaLibraryService
    let playbackService: PlaybackService

    @Published var artists: [VLCWatchMLArtist] = []
    var _artistsMap: [VLCMLIdentifier: VLCMLArtist] = [:]

    init(mediaLibraryService: MediaLibraryService, playbackService: PlaybackService) {
        self.mediaLibraryService = mediaLibraryService
        self.playbackService = playbackService
        model = ArtistModel(medialibrary: mediaLibraryService)

        model.sort(by: .default, desc: true)
        artists = model.anyfiles.compactMap { (obj: VLCMLObject) -> VLCWatchMLArtist? in
            guard let artist = obj as? VLCMLArtist else { return nil }
            _artistsMap[artist.identifier()] = artist
            return VLCWatchMLArtist(artist)
        }

        if let albums = model.anyfiles as? [VLCMLArtist] {
            print("Artists (\(albums.count)): \(albums)")
        }
    }
}
