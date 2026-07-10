//
//  AlbumDetailViewModel.swift
//  VLC-watchOS
//
//  Created by Timmy Nguyen on 7/10/26.
//  Copyright © 2026 VideoLAN. All rights reserved.
//

import Foundation

class AlbumDetailViewModel: ObservableObject {
    @Published var snapshotMedias: [VLCWatchMLMedia] = []

    let album: VLCWatchMLAlbum
    var tracks: [VLCMLMedia] = []

    lazy var playbackService = PlaybackService.sharedInstance()

    init(album: VLCWatchMLAlbum) {
        self.album = album
        loadSnapshotMedias()
    }

    func loadSnapshotMedias() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.tracks = self.album.tracks()
            let snapshotMedias = self.tracks.map { VLCWatchMLMedia($0) }
            DispatchQueue.main.async {
                self.snapshotMedias = snapshotMedias
            }
        }
    }

    func play(mediaID: VLCMLIdentifier) {
        guard let media: VLCMLMedia = self.tracks.first(where: { $0.identifier() == mediaID })
        else {
            print("Media with id not found: \(mediaID)")
            return
        }

        playbackService.play(media)
        print("Playing media: \(media.title)")
    }
}
