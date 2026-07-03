/*****************************************************************************
 * TrackView.swift
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

struct TrackView: View {
    @ObservedObject var tracksViewModel: TracksViewModel

    var body: some View {
        NavigationStack {
            TrackListView(
                snapshotMedias: tracksViewModel.snapshotMedias,
                downloadedMediaIDs: tracksViewModel.downloadedMediaIDs,
                mediaSyncIds: tracksViewModel.mediaSyncIds) { media in
                    tracksViewModel.play(media: media)
                }
                .navigationTitle("Songs")
                .onAppear {
                    guard tracksViewModel.isFirstLoad else { return }
                    tracksViewModel.loadTracks()
                }
        }
    }
}
