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
    let mlSyncState: MLSyncState
    @EnvironmentObject var router: WatchNavigationRouter

    var body: some View {
        AlbumListView(
            snapshotAlbums: albumsViewModel.snapshotAlbums,
            mediaSyncIds: mlSyncState.albumsSyncIds,
            didTapAlbum: { album in
                router.path.append(album)
            }
        )
        .navigationTitle(NSLocalizedString("ALBUMS", comment: ""))
        .onAppear {
            guard albumsViewModel.isFirstLoad else { return }
            albumsViewModel.loadData(albumSyncIds: mlSyncState.albumsSyncIds)
        }
    }
}
