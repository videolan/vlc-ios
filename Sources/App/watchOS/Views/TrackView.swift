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
    var mediaSyncIds: [MLSyncID]

    var body: some View {
        NavigationStack {
            TrackListView(
                snapshotMedias: tracksViewModel.snapshotMedias,
                mediaSyncIds: mediaSyncIds,
                didTapMedia: { media in
                    guard let mediaId = mediaSyncIds.first(where: { $0.iphoneMediaId == media.id })?.watchMediaId else { return }
                    tracksViewModel.play(mediaID: mediaId)
                }
            )
            .navigationTitle(NSLocalizedString("SONGS", comment: ""))
            .onAppear {
                guard tracksViewModel.isFirstLoad else { return }
                tracksViewModel.loadData(mlSyncIds: mediaSyncIds)
            }
        }
    }
}
