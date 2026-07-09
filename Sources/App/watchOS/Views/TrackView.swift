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

struct TrackView<MLSyncManager>: View where MLSyncManager: ObservableMLSyncManager {
    @EnvironmentObject var mlSyncManager: MLSyncManager
    @ObservedObject var tracksViewModel: TracksViewModel

    var body: some View {
        NavigationStack {
            TrackListView(
                snapshotMedias: tracksViewModel.snapshotMedias,
                mediaSyncIds: mlSyncManager.state?.mediaSyncIds ?? []) { media in
                    guard let mediaId = mlSyncManager.getMediaId(snapshotMediaId: media.id) else { return }
                    tracksViewModel.play(mediaID: mediaId)
                }
                .navigationTitle("Songs")
        }
    }
}
