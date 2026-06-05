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
    typealias MLType = VLCMLArtist

    override var files: [VLCMLArtist] {
        didSet {
            DispatchQueue.main.async {
                self.artists = self.model.anyfiles.compactMap { (obj: VLCMLObject) -> VLCWatchMLArtist? in
                    guard let artist = obj as? VLCMLArtist else { return nil }
                    return VLCWatchMLArtist(artist)
                }
            }
        }
    }

    let model: MediaLibraryBaseModel

    @Published var artists: [VLCWatchMLArtist] = []
    @Published var isFirstLoad = true

    required init(medialibrary: MediaLibraryService) {
        self.model = ArtistModel(medialibrary: medialibrary)
        super.init(medialibrary: medialibrary)
        medialibrary.observable.addObserver(self)
    }

    func loadArtists() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.model.sort(by: .default, desc: true)
            self.files = self.model.anyfiles as? [VLCMLArtist] ?? []
        }
        isFirstLoad = false
    }
}
