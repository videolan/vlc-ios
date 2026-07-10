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
    var mediaSyncIds: [MediaSyncID]
    var didTapAlbum: (VLCWatchMLAlbum) -> Void

    init(artist: VLCWatchMLArtist, mediaSyncIds: [MediaSyncID], didTapAlbum: @escaping (VLCWatchMLAlbum) -> Void) {
        _artistDetailViewModel = StateObject(wrappedValue: ArtistDetailViewModel(artist: artist))
        self.mediaSyncIds = mediaSyncIds
        self.didTapAlbum = didTapAlbum
    }

    var body: some View {
        Group {
            if artistDetailViewModel.artist.albumsCount == 0 {
                TrackListView(
                    snapshotMedias: artistDetailViewModel.snapshotMedias,
                    mediaSyncIds: mediaSyncIds,
                    didTapMedia: { media in
                        guard let mediaId = mediaSyncIds.getMediaId(snapshotMediaId: media.id) else { return }
                        artistDetailViewModel.play(mediaID: mediaId)
                    }
                )
            } else {
                List {
                    Section("Albums") {
                        ForEach(artistDetailViewModel.snapshotAlbums) { album in
                            AlbumCellView(album: album)
                                .onTapGesture {
                                    didTapAlbum(album)
                                }
                        }
                    }

                    Section("Tracks") {
                        ForEach(artistDetailViewModel.snapshotMedias) { media in
                            TrackCellView(
                                media: media,
                                showTrackNumber: false,
                                isDownloaded: media.isDownloaded(mediaSyncIds)
                            )
                            .onTapGesture {
                                guard let mediaId = mediaSyncIds.getMediaId(snapshotMediaId: media.id) else { return }
                                artistDetailViewModel.play(mediaID: mediaId)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(artistDetailViewModel.artist.name)
    }
}
