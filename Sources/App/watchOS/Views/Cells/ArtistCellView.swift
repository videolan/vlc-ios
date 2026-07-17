/*****************************************************************************
 * ArtistCellView.swift
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

struct ArtistCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    let artist: VLCWatchMLArtist
    let thumbnail: URL?

    var body: some View {
        MediaCellView(
            titleView: titleView(artist),
            subtitleView: subtitleView(artist),
            thumbnail: thumbnail,
            placeholderImageName: artist.placeholderName(for: colorScheme)
        )
    }

    @ViewBuilder
    private func titleView(_ artist: VLCWatchMLArtist) -> some View {
        Text(artist.name)
            .lineLimit(1)
    }

    @ViewBuilder
    private func subtitleView(_ artist: VLCWatchMLArtist) -> some View {
        Text(subtitleText(artist))
            .lineLimit(1)
            .foregroundStyle(.secondary)
            .font(.caption)
    }

    private func subtitleText(_ artist: VLCWatchMLArtist) -> String {
        return artist.albumsCount == 0 ? numberOfTracksString(artist) : String(format: "%@ · %@", numberOfAlbumsString(artist), numberOfTracksString(artist))
    }

    private func numberOfTracksString(_ artist: VLCWatchMLArtist) -> String {
        let tracksString = artist.tracksCount == 1 ? NSLocalizedString("TRACK", comment: "") : NSLocalizedString("TRACKS", comment: "")
        return String(format: tracksString, artist.tracksCount)
    }

    private func numberOfAlbumsString(_ artist: VLCWatchMLArtist) -> String {
        let albumsString = artist.albumsCount == 1 ? NSLocalizedString("NB_ALBUM_FORMAT", comment: "") : NSLocalizedString("NB_ALBUMS_FORMAT", comment: "")
        return String(format: albumsString, artist.albumsCount)
    }
}
