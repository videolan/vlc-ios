//
//  ArtistDetailViewModel.swift
//  VLC-watchOS
//
//  Created by Timmy Nguyen on 7/10/26.
//  Copyright © 2026 VideoLAN. All rights reserved.
//

import Foundation

class ArtistDetailViewModel: ObservableObject {
    @Published var snapshotAlbums: [VLCWatchMLAlbum] = []
    @Published var snapshotMedias: [VLCWatchMLMedia] = []

    let artist: VLCWatchMLArtist
    var tracks: [VLCMLMedia] = []

    lazy var playbackService = PlaybackService.sharedInstance()

    init(artist: VLCWatchMLArtist) {
        self.artist = artist
        loadSnapshotAlbums()
        loadSnapshotMedias()
    }

    func loadSnapshotAlbums() {
        DispatchQueue.global(qos: .userInitiated).async {
            let snapshotAlbums = self.artist.albums().map { VLCWatchMLAlbum($0) }
            DispatchQueue.main.async {
                self.snapshotAlbums = snapshotAlbums
            }
        }
    }

    func loadSnapshotMedias() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.tracks = self.artist.tracks()
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
