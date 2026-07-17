/*****************************************************************************
 * ArtistView.swift
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

struct ArtistView: View {
    @ObservedObject var artistsViewModel: ArtistsViewModel
    var mlSyncState: MLSyncState

    var body: some View {
        NavigationStack(path: $artistsViewModel.path) {
            ArtistListView(
                snapshotArtists: artistsViewModel.snapshotArtists,
                mediaSyncIds: mlSyncState.mediaSyncIds,
                didTapArtist: { artist in
                    artistsViewModel.path.append(artist)
                }
            )
            .navigationTitle(NSLocalizedString("ARTISTS", comment: ""))
            .onAppear {
                guard artistsViewModel.isFirstLoad else { return }
                artistsViewModel.loadData(artistSyncIds: mlSyncState.artistSyncIds)
            }
            .navigationDestination(for: VLCWatchMLArtist.self) { artist in
                ArtistDetailView(
                    artist: artist,
                    mlSyncState: mlSyncState,
                    didTapAlbum: { album in
                        artistsViewModel.path.append(album)
                    }
                )
            }
            .navigationDestination(for: VLCWatchMLAlbum.self) { album in
                AlbumDetailView(
                    album: album,
                    mlSyncState: mlSyncState
                )
            }
        }
    }
}
