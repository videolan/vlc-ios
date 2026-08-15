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
    @EnvironmentObject var router: WatchNavigationRouter

    var body: some View {
        ArtistListView(
            snapshotArtists: artistsViewModel.snapshotArtists,
            mediaSyncIds: mlSyncState.mediaSyncIds,
            didTapArtist: { artist in
                router.path.append(artist)
            }
        )
        .navigationTitle(NSLocalizedString("ARTISTS", comment: ""))
        .onAppear {
            guard artistsViewModel.isFirstLoad else { return }
            artistsViewModel.loadData(artistSyncIds: mlSyncState.artistSyncIds)
        }
    }
}
