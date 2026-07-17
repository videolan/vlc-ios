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
    @Published var isFirstLoad: Bool = true

    let snapshotArtist: VLCWatchMLArtist
    var albums: [VLCMLAlbum] = []
    var tracks: [VLCMLMedia] = []

    lazy var playbackService = PlaybackService.sharedInstance()

    init(snapshotArtist: VLCWatchMLArtist) {
        self.snapshotArtist = snapshotArtist
    }

    func loadData(mlSyncState: MLSyncState) {
        loadArtist(mlSyncState: mlSyncState)
        isFirstLoad = false
    }

    required init(medialibrary: MediaLibraryService) {
        fatalError("init(medialibrary:) has not been implemented")
    }

    private func loadArtist(mlSyncState: MLSyncState) {
        DispatchQueue.global(qos: .userInitiated).async {
            var artist: VLCMLArtist?

            if let artistId = mlSyncState.artistSyncIds.first(where: { $0.iphoneMediaId == self.snapshotArtist.id })?.watchMediaId {
                artist = VLCAppCoordinator.sharedInstance().mediaLibraryService.medialib.artist(withIdentifier: artistId)
            }

            self.loadAlbums(artist: artist, mlSyncState: mlSyncState)
            self.loadTracks(artist: artist, mlSyncState: mlSyncState)
        }
    }

    private func loadAlbums(artist: VLCMLArtist?, mlSyncState: MLSyncState) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.albums = artist?.albums() ?? []
            self.loadSnapshotAlbums(albumSyncIds: mlSyncState.albumsSyncIds)
        }
    }

    private func loadSnapshotAlbums(albumSyncIds: [MLSyncID]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let snapshotAlbumFiles = self.snapshotArtist.albums()
            let snapshotAlbums = snapshotAlbumFiles.map { VLCWatchMLAlbum($0) }.sorted { $0.id < $1.id}
            DispatchQueue.main.async {
                self.snapshotAlbums = snapshotAlbums
                self.loadThumbnails(snapshotAlbums: snapshotAlbums, albumSyncIds: albumSyncIds)
            }
        }
    }

    private func loadTracks(artist: VLCMLArtist?, mlSyncState: MLSyncState) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.tracks = artist?.tracks() ?? []
            self.loadSnapshotTracks(mediaSyncIds: mlSyncState.mediaSyncIds)
        }
    }

    private func loadSnapshotTracks(mediaSyncIds: [MLSyncID]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let snapshotMediaFiles = self.snapshotArtist.tracks()
            let snapshotMedias = snapshotMediaFiles.map { VLCWatchMLMedia($0) }.sorted { $0.id < $1.id}
            DispatchQueue.main.async {
                self.snapshotMedias = snapshotMedias
                self.loadThumbnails(snapshotMedias: snapshotMedias, mediaSyncIds: mediaSyncIds)
            }
        }
    }

    private func loadSnapshotTracks(tracks: [VLCMLMedia], mediaSyncIds: [MLSyncID]) {
        DispatchQueue.main.async {
            let snasphotMedias = tracks.map { VLCWatchMLMedia($0) }
            self.snapshotMedias = snasphotMedias
            self.loadThumbnails(snapshotMedias: snasphotMedias, mediaSyncIds: mediaSyncIds)
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

    private func loadThumbnails(snapshotAlbums: [VLCWatchMLAlbum], albumSyncIds: [MLSyncID]) {
        for i in 0..<snapshotAlbums.count {
            guard let albumId = albumSyncIds.first(where: { $0.iphoneMediaId == snapshotAlbums[i].id })?.watchMediaId,
                  let album = self.albums.first(where: { $0.identifier() == albumId })
            else { continue }

            self.snapshotAlbums[i].thumbnail = album.artworkMRL()
        }
    }

    private func loadThumbnails(snapshotMedias: [VLCWatchMLMedia], mediaSyncIds: [MLSyncID]) {
        for i in 0..<snapshotMedias.count {
            guard let mediaId = mediaSyncIds.first(where: { $0.iphoneMediaId == snapshotMedias[i].id })?.watchMediaId,
                  let media = self.tracks.first(where: { $0.identifier() == mediaId })
            else { continue }

            self.snapshotMedias[i].thumbnail = media.thumbnail()
        }
    }

}
