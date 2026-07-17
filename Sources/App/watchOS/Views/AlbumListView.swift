/*****************************************************************************
 * AlbumListView.swift
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

struct AlbumListView: View {
    let snapshotAlbums: [VLCWatchMLAlbum]
    let mediaSyncIds: [MLSyncID]
    let didTapAlbum: (VLCWatchMLAlbum) -> Void

    var body: some View {
        List(snapshotAlbums) { album in
            AlbumCellView(
                album: album,
                thumbnail: album.thumbnail
            )
            .onTapGesture {
                didTapAlbum(album)
            }
        }
    }
}
