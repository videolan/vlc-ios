/*****************************************************************************
 * AlbumCellView.swift
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

struct AlbumCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    let album: VLCWatchMLAlbum
    let thumbnail: URL?

    var body: some View {
        MediaCellView(
            titleView: titleView(album),
            subtitleView: subtitleView(album),
            thumbnail: thumbnail,
            placeholderImageName: album.placeholderName(for: colorScheme)
        )
    }

    @ViewBuilder
    private func titleView(_ album: VLCWatchMLAlbum) -> some View {
        Text(album.title)
            .lineLimit(1)
    }

    @ViewBuilder
    private func subtitleView(_ album: VLCWatchMLAlbum) -> some View {
        Text(album.albumArtistName ?? "")
            .lineLimit(1)
            .foregroundStyle(.secondary)
            .font(.caption)
    }
}
