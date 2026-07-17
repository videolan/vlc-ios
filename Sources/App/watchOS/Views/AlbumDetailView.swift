//
//  AlbumDetailView.swift
//  VLC-watchOS
//
//  Created by Timmy Nguyen on 7/10/26.
//  Copyright © 2026 VideoLAN. All rights reserved.
//

import SwiftUI

struct AlbumDetailView: View {
    @StateObject var albumDetailViewModel: AlbumDetailViewModel
    var mlSyncState: MLSyncState

    init(album: VLCWatchMLAlbum, mlSyncState: MLSyncState) {
        self._albumDetailViewModel = StateObject(wrappedValue: AlbumDetailViewModel(snapshotAlbum: album))
        self.mlSyncState = mlSyncState
    }

    var body: some View {
        TrackListView(
            snapshotMedias: albumDetailViewModel.snapshotMedias,
            mediaSyncIds: mlSyncState.mediaSyncIds,
            showTrackNumber: true,
            didTapMedia: { media in
                guard let mediaId = mlSyncState.mediaSyncIds.first(where: { $0.iphoneMediaId == media.id })?.watchMediaId else { return }
                albumDetailViewModel.play(mediaID: mediaId)
            }
        )
        .onAppear {
            guard albumDetailViewModel.isFirstLoad else { return }
            albumDetailViewModel.loadData(mlSyncState: mlSyncState)
        }
        .navigationTitle(albumDetailViewModel.snapshotAlbum.title)
    }
}
