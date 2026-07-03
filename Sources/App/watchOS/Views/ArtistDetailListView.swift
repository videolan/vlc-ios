/*****************************************************************************
 * ArtistDetailListView.swift
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

struct ArtistDetailListView: View {
    let snapshotAlbums: [VLCWatchMLAlbum]
    let snapshotMedias: [VLCWatchMLMedia]

    var downloadedMediaIDs: Set<VLCMLIdentifier>
    var mediaSyncIds: [MediaSyncID]

    var didTapAlbum: (VLCWatchMLAlbum) -> Void
    var didTapMedia: (VLCWatchMLMedia) -> Void

    var body: some View {
        List {
            Section("Albums") {
                ForEach(snapshotAlbums) { album in
                    AlbumCellView(album: album)
                        .onTapGesture {
                            didTapAlbum(album)
                        }
                }
            }

            Section("Tracks") {
                ForEach(snapshotMedias) { media in
                    TrackCellView(
                        media: media,
                        showTrackNumber: false,
                        isDownloaded: media.isDownloaded(mediaSyncIds, downloadedMediaIDs)
                    )
                    .onTapGesture {
                        didTapMedia(media)
                    }
                }
            }
        }
    }
}
