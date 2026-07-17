/*****************************************************************************
 * TrackCellView.swift
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

struct TrackCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    let media: VLCWatchMLMedia
    let thumbnail: URL?
    let showTrackNumber: Bool
    let isDownloaded: Bool

    var body: some View {
        MediaCellView(
            titleView: titleView(media),
            subtitleView: subtitleView(media),
            thumbnail: thumbnail,
            placeholderImageName: media.placeholderName(for: colorScheme)
        )
    }

    @ViewBuilder
    func titleView(_ media: VLCWatchMLMedia) -> some View {
        Text(showTrackNumber ? "\(media.trackNumber). \(media.title)" : media.title)
            .lineLimit(1)
    }

    @ViewBuilder
    func subtitleView(_ media: VLCWatchMLMedia) -> some View {
        HStack(spacing: 2) {
            if !isDownloaded {
                Image("Downloads")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            Text(media.artist?.artistName() ?? "")
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}
