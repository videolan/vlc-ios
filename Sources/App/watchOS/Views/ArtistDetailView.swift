//
//  ArtistDetailView.swift
//  VLC-watchOS
//
//  Created by Timmy Nguyen on 7/10/26.
//  Copyright © 2026 VideoLAN. All rights reserved.
//

import SwiftUI

struct ArtistDetailView: View {
    @StateObject var artistDetailViewModel: ArtistDetailViewModel
    var mlSyncState: MLSyncState
    var didTapAlbum: (VLCWatchMLAlbum) -> Void

    init(artist: VLCWatchMLArtist, mlSyncState: MLSyncState, didTapAlbum: @escaping (VLCWatchMLAlbum) -> Void) {
        _artistDetailViewModel = StateObject(wrappedValue: ArtistDetailViewModel(snapshotArtist: artist))
        self.mlSyncState = mlSyncState
        self.didTapAlbum = didTapAlbum
    }

    var body: some View {
        Group {
            if artistDetailViewModel.snapshotArtist.albumsCount == 0 {
                TrackListView(
                    snapshotMedias: artistDetailViewModel.snapshotMedias,
                    mediaSyncIds: mlSyncState.mediaSyncIds,
                    didTapMedia: { media in
                        guard let mediaId = mlSyncState.mediaSyncIds.first(where: { $0.iphoneMediaId == media.id })?.watchMediaId else { return }
                        artistDetailViewModel.play(mediaID: mediaId)
                    }
                )
            } else {
                List {
                    Section(NSLocalizedString("ALBUMS", comment: "")) {
                        ForEach(artistDetailViewModel.snapshotAlbums) { album in
                            AlbumCellView(
                                album: album,
                                thumbnail: album.thumbnail
                            )
                            .onTapGesture {
                                didTapAlbum(album)
                            }
                        }
                    }

                    Section(NSLocalizedString("SONGS", comment: "")) {
                        ForEach(artistDetailViewModel.snapshotMedias) { media in
                            TrackCellView(
                                media: media,
                                thumbnail: media.thumbnail,
                                showTrackNumber: false,
                                isDownloaded: media.isDownloaded(mlSyncState.mediaSyncIds)
                            )
                            .onTapGesture {
                                guard let mediaId = mlSyncState.mediaSyncIds.first(where: { $0.iphoneMediaId == media.id })?.watchMediaId else { return }
                                artistDetailViewModel.play(mediaID: mediaId)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(artistDetailViewModel.snapshotArtist.name)
        .onAppear {
            guard artistDetailViewModel.isFirstLoad else { return }
            artistDetailViewModel.loadData(mlSyncState: mlSyncState)
        }
    }
}
