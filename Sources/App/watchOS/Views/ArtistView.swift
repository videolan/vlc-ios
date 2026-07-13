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
    var mediaSyncIds: [MediaSyncID]

    var body: some View {
        NavigationStack(path: $artistsViewModel.path) {
            ArtistListView(
                snapshotArtists: artistsViewModel.snapshotArtists,
                didTapArtist: { artist in
                    artistsViewModel.path.append(artist)
                }
            )
            .navigationTitle(NSLocalizedString("ARTISTS", comment: ""))
            .onAppear {
                guard artistsViewModel.isFirstLoad else { return }
                artistsViewModel.loadData()
            }
            .navigationDestination(for: VLCWatchMLArtist.self) { artist in
                ArtistDetailView(
                    artist: artist,
                    mediaSyncIds: mediaSyncIds,
                    didTapAlbum: { album in
                        artistsViewModel.path.append(album)
                    }
                )
            }
            .navigationDestination(for: VLCWatchMLAlbum.self) { album in
                AlbumDetailView(
                    album: album,
                    mediaSyncIds: mediaSyncIds
                )
            }
        }
    }
}
