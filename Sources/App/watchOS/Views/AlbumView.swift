/*****************************************************************************
 * AlbumView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Timmy Nguyen <timmypass21 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import SwiftUI

struct AlbumView: View {
    @ObservedObject var albumsViewModel: AlbumsViewModel
    @ObservedObject var tracksViewModel: TracksViewModel

    var body: some View {
        NavigationStack(path: $albumsViewModel.path) {
            AlbumListView(snapshotAlbums: albumsViewModel.snapshotAlbums) { album in
                albumsViewModel.path.append(album)
            }
            .navigationTitle("Albums")
            .onAppear {
                guard albumsViewModel.isFirstLoad else { return }
                albumsViewModel.loadAlbums()
            }
            .navigationDestination(for: VLCWatchMLAlbum.self) { album in
                let medias = album.tracks.map { VLCWatchMLMedia($0) }

                TrackListView(
                    snapshotMedias: medias,
                    downloadedMediaIDs: tracksViewModel.downloadedMediaIDs,
                    mediaSyncIds: tracksViewModel.mediaSyncIds,
                    showTrackNumber: true
                ) { media in
                    tracksViewModel.play(media: media)
                }
                .navigationTitle(album.title)
            }
        }
    }
}
