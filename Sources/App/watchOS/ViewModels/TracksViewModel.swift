/*****************************************************************************
 * TracksViewModel.swift
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

class TracksViewModel: ObservableObject {
    let model: MediaLibraryBaseModel
    let mediaLibraryService: MediaLibraryService
    let playbackService: PlaybackService

    @Published var tracks: [VLCWatchMLMedia] = []
    @Published var isFirstLoad = true

    private var _tracksMap: [VLCMLIdentifier: VLCMLMedia] = [:]

    init(mediaLibraryService: MediaLibraryService, playbackService: PlaybackService) {
        self.mediaLibraryService = mediaLibraryService
        self.playbackService = playbackService
        model = TrackModel(medialibrary: mediaLibraryService)
    }

    func play(media: VLCWatchMLMedia) {
        guard let mlMedia = _tracksMap[media.id] else { return }
         playbackService.play(mlMedia)
        print("Playing media: \(media.title)")
    }

    func loadTracks() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.model.sort(by: .default, desc: true)
            DispatchQueue.main.async {
                self.tracks = self.model.anyfiles.compactMap { (obj: VLCMLObject) -> VLCWatchMLMedia? in
                    guard let media = obj as? VLCMLMedia else { return nil }
                    self._tracksMap[media.identifier()] = media
                    return VLCWatchMLMedia(media)
                }
            }
        }
        isFirstLoad = false
    }
}
