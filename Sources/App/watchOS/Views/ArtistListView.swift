/*****************************************************************************
 * ArtistListView.swift
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

struct ArtistListView: View {
    let snapshotArtists: [VLCWatchMLArtist]
    var didTapCell: (VLCWatchMLArtist) -> Void
    
    var body: some View {
        List(snapshotArtists) { artist in
            ArtistCellView(artist: artist)
                .onTapGesture {
                    didTapCell(artist)
                }
        }
    }
}
