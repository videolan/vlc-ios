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
    var mediaSyncIds: [MediaSyncID]

    init(album: VLCWatchMLAlbum, mediaSyncIds: [MediaSyncID]) {
        self._albumDetailViewModel = StateObject(wrappedValue: AlbumDetailViewModel(album: album))
        self.mediaSyncIds = mediaSyncIds
    }

    var body: some View {
        TrackListView(
            snapshotMedias: albumDetailViewModel.snapshotMedias,
            mediaSyncIds: mediaSyncIds,
            showTrackNumber: true,
            didTapMedia: { media in
                guard let mediaId = mediaSyncIds.getMediaId(snapshotMediaId: media.id) else { return }
                albumDetailViewModel.play(mediaID: mediaId)
            }
        )
        .navigationTitle(albumDetailViewModel.album.title)
    }
}
