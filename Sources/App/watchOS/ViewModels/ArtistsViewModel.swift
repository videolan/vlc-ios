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
    @Published var isFirstLoad = true

    private var _artistsMap: [VLCMLIdentifier: VLCMLArtist] = [:]

    init(mediaLibraryService: MediaLibraryService, playbackService: PlaybackService) {
        self.mediaLibraryService = mediaLibraryService
        self.playbackService = playbackService
        model = ArtistModel(medialibrary: mediaLibraryService)
    }

    func loadArtists() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.model.sort(by: .default, desc: true)
            DispatchQueue.main.async {
                self.artists = self.model.anyfiles.compactMap { (obj: VLCMLObject) -> VLCWatchMLArtist? in
                    guard let artist = obj as? VLCMLArtist else { return nil }
                    self._artistsMap[artist.identifier()] = artist
                    return VLCWatchMLArtist(artist)
                }
            }
        }
        isFirstLoad = false
    }
}
