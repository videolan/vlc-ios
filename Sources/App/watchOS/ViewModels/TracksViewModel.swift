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

class TracksViewModel: TrackModel, ObservableObject {

    override var files: [VLCMLMedia] {
        didSet {
            DispatchQueue.main.async {
                self.tracks = self.anyfiles.compactMap { (obj: VLCMLObject) -> VLCWatchMLMedia? in
                    guard let media = obj as? VLCMLMedia else { return nil }
                    return VLCWatchMLMedia(media)
                }
            }
        }
    }

    lazy var playbackService = PlaybackService.sharedInstance()

    @Published var tracks: [VLCWatchMLMedia] = []
    @Published var isFirstLoad = true

    required init(medialibrary: MediaLibraryService) {
        super.init(medialibrary: medialibrary)
        medialibrary.observable.addObserver(self)
    }

    func play(media: VLCWatchMLMedia) {
        guard let mlMedia = files.first(where: { $0.identifier() == media.id }) else { return }
        playbackService.play(mlMedia)
        print("Playing media: \(media.title)")
    }

    func loadTracks() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.sort(by: .default, desc: true)
            self.files = self.anyfiles as? [VLCMLMedia] ?? []
        }
        isFirstLoad = false
    }
}
